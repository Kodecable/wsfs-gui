#pragma once

#include "app_settings.hpp"
#include "config.h"
#include "credential_store.hpp"
#include "environment_probe.hpp"
#include "log_buffer.hpp"
#include "mount_runner.hpp"
#include "profile.hpp"
#include "profile_store.hpp"
#include "system_integration.hpp"

#include <QObject>
#include <QVariantList>
#include <functional>

class QQuickWindow;

class AppController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList profiles READ profiles NOTIFY profilesChanged)
    Q_PROPERTY(QString selectedProfileId READ selectedProfileId WRITE setSelectedProfileId NOTIFY selectedProfileIdChanged)
    Q_PROPERTY(QVariantMap selectedProfile READ selectedProfile NOTIFY selectedProfileChanged)
    Q_PROPERTY(bool autoStartOnBoot READ autoStartOnBoot WRITE setAutoStartOnBoot NOTIFY settingsChanged)
    Q_PROPERTY(bool minimizeToTrayOnLaunch READ minimizeToTrayOnLaunch WRITE setMinimizeToTrayOnLaunch NOTIFY settingsChanged)
    Q_PROPERTY(bool restoreEnabledProfilesOnLaunch READ restoreEnabledProfilesOnLaunch WRITE setRestoreEnabledProfilesOnLaunch NOTIFY settingsChanged)
    Q_PROPERTY(bool useSystemCredentialStore READ useSystemCredentialStore NOTIFY settingsChanged)
    Q_PROPERTY(bool credentialOperationInProgress READ credentialOperationInProgress NOTIFY credentialOperationInProgressChanged)
    Q_PROPERTY(QString wsfsExecutablePath READ wsfsExecutablePath WRITE setWsfsExecutablePath NOTIFY settingsChanged)
    Q_PROPERTY(QString wsfsVersionLine READ wsfsVersionLine NOTIFY environmentChanged)
    Q_PROPERTY(QString wsfsGuiVersion READ wsfsGuiVersion CONSTANT)
    Q_PROPERTY(bool linuxFuse3Ready READ linuxFuse3Ready NOTIFY environmentChanged)
    Q_PROPERTY(QString winfspStatus READ winfspStatus NOTIFY environmentChanged)
    Q_PROPERTY(QString dependencyWarning READ dependencyWarning NOTIFY environmentChanged)
    Q_PROPERTY(QString logs READ logs NOTIFY logsChanged)

public:
    explicit AppController(QObject *parent = nullptr);
    ~AppController() override;

    QVariantList profiles() const;

    QString selectedProfileId() const;
    void setSelectedProfileId(const QString &id);
    QVariantMap selectedProfile() const;

    bool autoStartOnBoot() const;
    bool minimizeToTrayOnLaunch() const;
    bool restoreEnabledProfilesOnLaunch() const;
    bool useSystemCredentialStore() const;
    bool credentialOperationInProgress() const;
    QString wsfsExecutablePath() const;
    QString wsfsVersionLine() const;
    QString wsfsGuiVersion() const;
    bool linuxFuse3Ready() const;
    QString winfspStatus() const;
    QString dependencyWarning() const;

    QString logs() const;
    Q_INVOKABLE QString logsForProfile(const QString &profileId) const;

    Q_INVOKABLE QString createProfile();
    Q_INVOKABLE void saveSelectedProfile(const QVariantMap &payload);
    Q_INVOKABLE void removeSelectedProfile();
    Q_INVOKABLE void setProfileEnabled(const QString &id, bool enabled);
    Q_INVOKABLE void setUseSystemCredentialStore(bool enabled);
    Q_INVOKABLE void restartSelected();
    Q_INVOKABLE void stopAll();
    Q_INVOKABLE void showMainWindow();
    Q_INVOKABLE void quitApp();

    void setAutoStartOnBoot(bool enabled);
    void setMinimizeToTrayOnLaunch(bool enabled);
    void setRestoreEnabledProfilesOnLaunch(bool enabled);
    void setWsfsExecutablePath(const QString &path);

    void attachMainWindow(QQuickWindow *window);
    void restoreOnLaunch();

signals:
    void profilesChanged();
    void selectedProfileIdChanged();
    void selectedProfileChanged();
    void settingsChanged();
    void environmentChanged();
    void logsChanged();
    void credentialOperationInProgressChanged();
    void profileSaveFinished(bool ok, const QString &error);
    void credentialMigrationFinished(bool ok, const QString &error);

private:
    Profile *findProfile(const QString &id);
    const Profile *findProfile(const QString &id) const;
    void refreshEnvironment();
    void saveProfiles() const;
    void saveSettings() const;
    QString resolveWsfsExecutable() const;
    void prepareProfilePassword(const QString &profileId, std::function<void(bool, const QString &)> callback);
    void migratePlainTextToKeychain();
    void migrateKeychainToPlainText();
    void deleteKeychainPasswords(int index, std::function<void(bool, const QString &)> callback);
    void setCredentialOperationInProgress(bool inProgress);

    QList<Profile> m_profiles;
    QString m_selectedProfileId;
    AppSettings m_settings;
    EnvironmentStatus m_environment;
    ProfileStore m_store;
    CredentialStore m_credentials;
    LogBuffer m_logs;
    MountRunner m_runner;
    SystemIntegration m_system;
    QQuickWindow *m_mainWindow = nullptr;
    bool m_credentialOperationInProgress = false;
};
