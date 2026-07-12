#include "app_controller.hpp"

#include <QCoreApplication>
#include <QQuickWindow>
#include <QUuid>
#include <memory>

AppController::AppController(QObject *parent)
    : QObject(parent)
{
    m_profiles = m_store.loadProfiles();
    m_settings = m_store.loadSettings();
    if (!m_profiles.isEmpty())
        m_selectedProfileId = m_profiles.front().id;

    m_runner.setProfileLookup([this](const QString &profileId) {
        return findProfile(profileId);
    });
    m_runner.setExecutableResolver([this]() {
        return resolveWsfsExecutable();
    });
    connect(&m_runner, &MountRunner::stateChanged, this, [this]() {
        emit profilesChanged();
        emit selectedProfileChanged();
    });
    connect(&m_runner, &MountRunner::logLine, this, [this](const QString &profileId, const QString &line) {
        m_logs.append(line, profileId);
        emit logsChanged();
    });

    connect(&m_system, &SystemIntegration::showRequested, this, &AppController::showMainWindow);
    connect(&m_system, &SystemIntegration::stopAllRequested, this, &AppController::stopAll);
    connect(&m_system, &SystemIntegration::quitRequested, this, &AppController::quitApp);

    refreshEnvironment();
    m_system.setupTray();
}

AppController::~AppController()
{
    m_runner.setQuitting(true);
    stopAll();
}

QVariantList AppController::profiles() const
{
    QVariantList list;
    list.reserve(m_profiles.size());
    for (const Profile &profile : m_profiles) {
        QVariantMap map = profileToSummaryBaseMap(profile);
        const MountRuntimeState runtime = m_runner.runtimeState(profile.id);
        map["state"] = runtime.state;
        map["pid"] = runtime.pid;
        map["lastError"] = runtime.lastError;
        map["nextRetrySec"] = runtime.nextRetrySec;
        list.push_back(map);
    }
    return list;
}

QString AppController::selectedProfileId() const
{
    return m_selectedProfileId;
}

void AppController::setSelectedProfileId(const QString &id)
{
    if (m_selectedProfileId == id)
        return;
    m_selectedProfileId = id;
    emit selectedProfileIdChanged();
    emit selectedProfileChanged();
}

QVariantMap AppController::selectedProfile() const
{
    const Profile *profile = findProfile(m_selectedProfileId);
    if (!profile)
        return {};
    return profileToDetailMap(*profile);
}

bool AppController::autoStartOnBoot() const
{
    return m_settings.autoStartOnBoot;
}

bool AppController::minimizeToTrayOnLaunch() const
{
    return m_settings.minimizeToTrayOnLaunch;
}

bool AppController::restoreEnabledProfilesOnLaunch() const
{
    return m_settings.restoreEnabledProfilesOnLaunch;
}

bool AppController::useSystemCredentialStore() const
{
    return m_settings.useSystemCredentialStore;
}

bool AppController::credentialOperationInProgress() const
{
    return m_credentialOperationInProgress;
}

QString AppController::wsfsExecutablePath() const
{
    return m_settings.wsfsExecutablePath;
}

QString AppController::wsfsVersionLine() const
{
    return m_environment.wsfsVersionLine;
}

QString AppController::wsfsGuiVersion() const
{
    return QStringLiteral("WSFS-GUI " CONFIG_VERSION);
}

bool AppController::linuxFuse3Ready() const
{
    return m_environment.linuxFuse3Ready;
}

QString AppController::winfspStatus() const
{
    return m_environment.winfspStatus;
}

QString AppController::dependencyWarning() const
{
    QStringList warnings;

    if (!m_environment.wsfsReady)
        warnings.push_back(tr("wsfs not found. Please install it or set the executable path manually."));
    else if (!m_environment.wsfsVersionOk)
        warnings.push_back(tr("Unable to execute wsfs. Please check installation."));

#if defined(Q_OS_LINUX)
    if (!m_environment.linuxFuse3Ready)
        warnings.push_back(tr("fusermount3 not found. Please install fuse3 first."));
#endif
#if defined(Q_OS_WIN)
    if (m_environment.winfspStatus != "ready")
        warnings.push_back(tr("WinFsp not found. Please install WinFsp first."));
#endif

    return warnings.join('\n');
}

QString AppController::logs() const
{
    return m_logs.allLogs();
}

QString AppController::logsForProfile(const QString &profileId) const
{
    if (profileId.isEmpty())
        return logs();
    return m_logs.profileLogs(profileId);
}

QString AppController::createProfile()
{
    Profile profile;
    profile.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    profile.name = tr("Mount %1").arg(m_profiles.size() + 1);
    profile.mountPoint = defaultMountPoint(m_profiles.size() + 1);

    m_profiles.push_back(profile);
    saveProfiles();

    setSelectedProfileId(profile.id);
    emit profilesChanged();
    emit selectedProfileChanged();
    return profile.id;
}

void AppController::saveSelectedProfile(const QVariantMap &payload)
{
    Profile *profile = findProfile(m_selectedProfileId);
    if (!profile) {
        emit profileSaveFinished(false, tr("No profile selected."));
        return;
    }

    Profile nextProfile = *profile;
    const bool hasNewPassword = payload.contains("password") && !payload.value("password").toString().isEmpty();
    const QString newPassword = hasNewPassword ? payload.value("password").toString() : QString();

    if (!updateProfileFromPayload(nextProfile, payload)) {
        emit profileSaveFinished(false, tr("Name, mount point, host, and port are required."));
        return;
    }

    auto commitProfile = [this, profileId = profile->id, nextProfile]() {
        Profile *current = findProfile(profileId);
        if (!current) {
            emit profileSaveFinished(false, tr("Profile no longer exists."));
            return;
        }
        *current = nextProfile;
        saveProfiles();
        emit profilesChanged();
        emit selectedProfileChanged();
        emit profileSaveFinished(true, QString());
    };

    if (!m_settings.useSystemCredentialStore || !hasNewPassword) {
        commitProfile();
        return;
    }

    setCredentialOperationInProgress(true);
    m_credentials.writePassword(profile->id, newPassword, [this, commitProfile](const CredentialStore::Result &result) {
        setCredentialOperationInProgress(false);
        if (!result.ok) {
            emit profileSaveFinished(false, tr("Unable to save password: %1").arg(result.error));
            return;
        }
        commitProfile();
    });
}

void AppController::removeSelectedProfile()
{
    if (m_selectedProfileId.isEmpty())
        return;

    m_runner.stopProfile(m_selectedProfileId, true);

    const QString removedId = m_selectedProfileId;
    for (int i = 0; i < m_profiles.size(); ++i) {
        if (m_profiles[i].id != removedId)
            continue;
        m_profiles.removeAt(i);
        break;
    }
    if (m_settings.useSystemCredentialStore) {
        m_credentials.deletePassword(removedId, [](const CredentialStore::Result &) {
        });
    }
    m_runner.removeProfile(removedId);
    m_logs.removeProfile(removedId);

    if (!m_profiles.isEmpty())
        setSelectedProfileId(m_profiles.front().id);
    else
        setSelectedProfileId(QString());

    saveProfiles();
    emit profilesChanged();
    emit selectedProfileChanged();
    emit logsChanged();
}

void AppController::setProfileEnabled(const QString &id, bool enabled)
{
    Profile *profile = findProfile(id);
    if (!profile || profile->enabled == enabled)
        return;

    profile->enabled = enabled;
    saveProfiles();

    if (enabled) {
        prepareProfilePassword(id, [this, id](bool ok, const QString &error) {
            if (!ok) {
                m_logs.append(tr("failed to read saved password: %1").arg(error), id);
                emit logsChanged();
                return;
            }
            m_runner.ensureDesiredState(id);
        });
    } else {
        m_runner.stopProfile(id);
    }

    emit profilesChanged();
    if (id == m_selectedProfileId)
        emit selectedProfileChanged();
}

void AppController::setUseSystemCredentialStore(bool enabled)
{
    if (m_settings.useSystemCredentialStore == enabled) {
        emit credentialMigrationFinished(true, QString());
        return;
    }
    if (m_credentialOperationInProgress) {
        emit credentialMigrationFinished(false, tr("Another credential operation is already running."));
        return;
    }

    if (enabled)
        migratePlainTextToKeychain();
    else
        migrateKeychainToPlainText();
}

void AppController::restartSelected()
{
    if (m_selectedProfileId.isEmpty())
        return;

    Profile *profile = findProfile(m_selectedProfileId);
    if (!profile)
        return;

    const bool shouldEnable = profile->enabled;
    m_runner.stopProfile(m_selectedProfileId);
    if (shouldEnable) {
        const QString profileId = m_selectedProfileId;
        prepareProfilePassword(profileId, [this, profileId](bool ok, const QString &error) {
            if (!ok) {
                m_logs.append(tr("failed to read saved password: %1").arg(error), profileId);
                emit logsChanged();
                return;
            }
            m_runner.ensureDesiredState(profileId);
        });
    }
}

void AppController::stopAll()
{
    m_runner.stopAll(m_profiles, true);
}

void AppController::showMainWindow()
{
    if (!m_mainWindow)
        return;
    m_mainWindow->show();
    m_mainWindow->raise();
    m_mainWindow->requestActivate();
}

void AppController::quitApp()
{
    m_runner.setQuitting(true);
    stopAll();
    QCoreApplication::quit();
}

void AppController::setAutoStartOnBoot(bool enabled)
{
    if (m_settings.autoStartOnBoot == enabled)
        return;

    m_settings.autoStartOnBoot = enabled;
    SystemIntegration::applyAutoStart(enabled);
    saveSettings();
    emit settingsChanged();
}

void AppController::setMinimizeToTrayOnLaunch(bool enabled)
{
    if (m_settings.minimizeToTrayOnLaunch == enabled)
        return;
    m_settings.minimizeToTrayOnLaunch = enabled;
    saveSettings();
    emit settingsChanged();
}

void AppController::setRestoreEnabledProfilesOnLaunch(bool enabled)
{
    if (m_settings.restoreEnabledProfilesOnLaunch == enabled)
        return;
    m_settings.restoreEnabledProfilesOnLaunch = enabled;
    saveSettings();
    emit settingsChanged();
}

void AppController::setWsfsExecutablePath(const QString &path)
{
    const QString normalized = path.trimmed();
    if (m_settings.wsfsExecutablePath == normalized)
        return;
    m_settings.wsfsExecutablePath = normalized;
    saveSettings();
    refreshEnvironment();
    emit settingsChanged();
}

void AppController::attachMainWindow(QQuickWindow *window)
{
    m_mainWindow = window;
}

void AppController::restoreOnLaunch()
{
    if (m_settings.restoreEnabledProfilesOnLaunch) {
        for (const Profile &profile : std::as_const(m_profiles)) {
            if (!profile.enabled)
                continue;
            const QString profileId = profile.id;
            prepareProfilePassword(profileId, [this, profileId](bool ok, const QString &error) {
                if (!ok) {
                    m_logs.append(tr("failed to read saved password: %1").arg(error), profileId);
                    emit logsChanged();
                    return;
                }
                m_runner.ensureDesiredState(profileId);
            });
        }
    }

    if (m_mainWindow && m_settings.minimizeToTrayOnLaunch)
        m_mainWindow->hide();
}

Profile *AppController::findProfile(const QString &id)
{
    for (Profile &profile : m_profiles) {
        if (profile.id == id)
            return &profile;
    }
    return nullptr;
}

const Profile *AppController::findProfile(const QString &id) const
{
    for (const Profile &profile : m_profiles) {
        if (profile.id == id)
            return &profile;
    }
    return nullptr;
}

void AppController::refreshEnvironment()
{
    m_environment = EnvironmentProbe::probe(m_settings.wsfsExecutablePath);
    emit environmentChanged();
}

void AppController::saveProfiles() const
{
    m_store.saveProfiles(m_profiles, !m_settings.useSystemCredentialStore);
}

void AppController::saveSettings() const
{
    m_store.saveSettings(m_settings);
}

QString AppController::resolveWsfsExecutable() const
{
    return EnvironmentProbe::resolveWsfsExecutable(m_settings.wsfsExecutablePath);
}

void AppController::prepareProfilePassword(const QString &profileId, std::function<void(bool, const QString &)> callback)
{
    if (!m_settings.useSystemCredentialStore) {
        callback(true, QString());
        return;
    }

    m_credentials.readPassword(profileId, [this, profileId, callback = std::move(callback)](const CredentialStore::Result &result) {
        if (!result.ok) {
            callback(false, result.error);
            return;
        }
        if (Profile *profile = findProfile(profileId))
            profile->password = result.password;
        callback(true, QString());
    });
}

void AppController::migratePlainTextToKeychain()
{
    setCredentialOperationInProgress(true);

    auto writeNext = std::make_shared<std::function<void(int)>>();
    *writeNext = [this, writeNext](int index) {
        if (index >= m_profiles.size()) {
            for (Profile &profile : m_profiles)
                profile.password.clear();
            m_settings.useSystemCredentialStore = true;
            saveSettings();
            saveProfiles();
            setCredentialOperationInProgress(false);
            emit settingsChanged();
            emit selectedProfileChanged();
            emit credentialMigrationFinished(true, QString());
            return;
        }

        const Profile &profile = m_profiles.at(index);
        if (profile.password.isEmpty()) {
            (*writeNext)(index + 1);
            return;
        }

        m_credentials.writePassword(profile.id, profile.password,
                                    [this, writeNext, index, profileName = profile.name](const CredentialStore::Result &result) {
            if (!result.ok) {
                setCredentialOperationInProgress(false);
                emit credentialMigrationFinished(false, tr("Unable to migrate password for %1: %2").arg(profileName, result.error));
                return;
            }
            (*writeNext)(index + 1);
        });
    };

    (*writeNext)(0);
}

void AppController::migrateKeychainToPlainText()
{
    setCredentialOperationInProgress(true);

    auto migratedProfiles = std::make_shared<QList<Profile>>(m_profiles);
    auto readNext = std::make_shared<std::function<void(int)>>();
    *readNext = [this, migratedProfiles, readNext](int index) {
        if (index >= migratedProfiles->size()) {
            deleteKeychainPasswords(0, [this, migratedProfiles](bool ok, const QString &error) {
                if (!ok) {
                    setCredentialOperationInProgress(false);
                    emit credentialMigrationFinished(false, error);
                    return;
                }

                m_profiles = *migratedProfiles;
                m_settings.useSystemCredentialStore = false;
                saveSettings();
                saveProfiles();
                setCredentialOperationInProgress(false);
                emit settingsChanged();
                emit selectedProfileChanged();
                emit credentialMigrationFinished(true, QString());
            });
            return;
        }

        const QString profileId = migratedProfiles->at(index).id;
        const QString profileName = migratedProfiles->at(index).name;
        m_credentials.readPassword(profileId, [this, migratedProfiles, readNext, index, profileName](const CredentialStore::Result &result) {
            if (!result.ok) {
                setCredentialOperationInProgress(false);
                emit credentialMigrationFinished(false, tr("Unable to read password for %1: %2").arg(profileName, result.error));
                return;
            }
            (*migratedProfiles)[index].password = result.password;
            (*readNext)(index + 1);
        });
    };

    (*readNext)(0);
}

void AppController::deleteKeychainPasswords(int index, std::function<void(bool, const QString &)> callback)
{
    if (index >= m_profiles.size()) {
        callback(true, QString());
        return;
    }

    const Profile &profile = m_profiles.at(index);
    m_credentials.deletePassword(profile.id, [this, index, callback = std::move(callback), profileName = profile.name](const CredentialStore::Result &result) mutable {
        if (!result.ok) {
            callback(false, tr("Unable to remove password for %1: %2").arg(profileName, result.error));
            return;
        }
        deleteKeychainPasswords(index + 1, std::move(callback));
    });
}

void AppController::setCredentialOperationInProgress(bool inProgress)
{
    if (m_credentialOperationInProgress == inProgress)
        return;
    m_credentialOperationInProgress = inProgress;
    emit credentialOperationInProgressChanged();
}
