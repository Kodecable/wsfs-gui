#pragma once

#include "profile.hpp"

#include <QHash>
#include <QObject>
#include <QProcess>
#include <QTimer>
#include <functional>

struct MountRuntimeState {
    QString state = "Stopped";
    QString lastError;
    int nextRetrySec = -1;
    qint64 pid = -1;
};

class MountRunner : public QObject
{
    Q_OBJECT

public:
    using ProfileLookup = std::function<Profile *(const QString &)>;
    using ExecutableResolver = std::function<QString()>;

    explicit MountRunner(QObject *parent = nullptr);

    void setProfileLookup(ProfileLookup lookup);
    void setExecutableResolver(ExecutableResolver resolver);
    MountRuntimeState runtimeState(const QString &profileId) const;

    void ensureDesiredState(const QString &profileId);
    void startProfile(const QString &profileId);
    void stopProfile(const QString &profileId, bool quitting = false);
    void stopAll(const QList<Profile> &profiles, bool quitting = true);
    void removeProfile(const QString &profileId);
    void setQuitting(bool quitting);

signals:
    void stateChanged();
    void logLine(const QString &profileId, const QString &line);

private:
    struct Runtime {
        QProcess *process = nullptr;
        QTimer *retryTimer = nullptr;
        QString state = "Stopped";
        QString lastError;
        int retryDelaySec = 1;
        qint64 runningSinceMs = 0;
        bool stopRequested = false;
    };

    Profile *profileFor(const QString &profileId) const;
    QString resolvedExecutable() const;
    void scheduleRetry(const QString &profileId);
    void clearRetry(const QString &profileId);
    void ensureProcess(const QString &profileId, Runtime &runtime);

    QHash<QString, Runtime> m_runtime;
    ProfileLookup m_profileLookup;
    ExecutableResolver m_executableResolver;
    bool m_isQuitting = false;
};
