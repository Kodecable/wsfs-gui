#include "mount_runner.hpp"

#include "environment_probe.hpp"
#include "wsfs_command.hpp"

#include <QDateTime>
#include <QProcessEnvironment>
#include <QRegularExpression>

namespace {
constexpr int kRetryMaxDelaySec = 600;
constexpr int kRetryResetRunThresholdSec = 30;
constexpr int kStopGraceMs = 90000;
constexpr int kKillWaitMs = 3000;

QString stripAnsi(const QString &text)
{
    static const QRegularExpression ansiPattern(QStringLiteral("\\x1B\\[[0-?]*[ -/]*[@-~]"));
    QString cleaned = text;
    cleaned.remove(ansiPattern);
    return cleaned;
}
}

MountRunner::MountRunner(QObject *parent)
    : QObject(parent)
{
}

void MountRunner::setProfileLookup(ProfileLookup lookup)
{
    m_profileLookup = std::move(lookup);
}

void MountRunner::setExecutableResolver(ExecutableResolver resolver)
{
    m_executableResolver = std::move(resolver);
}

MountRuntimeState MountRunner::runtimeState(const QString &profileId) const
{
    const Runtime runtime = m_runtime.value(profileId);

    MountRuntimeState state;
    state.state = runtime.state;
    state.lastError = runtime.lastError;
    state.nextRetrySec = runtime.retryTimer && runtime.retryTimer->isActive()
                         ? runtime.retryTimer->remainingTime() / 1000
                         : -1;
    state.pid = runtime.state == "Running" && runtime.process && runtime.process->processId() > 0
                ? runtime.process->processId()
                : -1;
    return state;
}

void MountRunner::ensureDesiredState(const QString &profileId)
{
    Profile *profile = profileFor(profileId);
    if (!profile || !profile->enabled)
        return;

    Runtime &runtime = m_runtime[profileId];
    if (runtime.process && runtime.process->state() != QProcess::NotRunning)
        return;

    clearRetry(profileId);
    startProfile(profileId);
}

void MountRunner::startProfile(const QString &profileId)
{
    Profile *profile = profileFor(profileId);
    if (!profile)
        return;

    Runtime &runtime = m_runtime[profileId];
    if (runtime.process && runtime.process->state() != QProcess::NotRunning)
        return;

    ensureProcess(profileId, runtime);

    runtime.state = "Starting";
    runtime.lastError.clear();
    runtime.stopRequested = false;
    emit stateChanged();

    const QStringList args = buildWsfsMountArgs(*profile);
    QString executable = resolvedExecutable();
    if (executable.isEmpty()) {
#if defined(Q_OS_WIN)
        executable = QStringLiteral("wsfs.exe");
#else
        executable = QStringLiteral("wsfs");
#endif
    }

    QStringList quoted;
    quoted.reserve(args.size() + 1);
    quoted.push_back(quoteProcessArgument(executable));
    for (const QString &arg : args)
        quoted.push_back(quoteProcessArgument(arg));
    emit logLine(profileId, QStringLiteral("exec: %1").arg(quoted.join(' ')));

    if (!profile->password.isEmpty()) {
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        env.insert(QStringLiteral("WSFS_GUI_PWD"), profile->password);
        runtime.process->setProcessEnvironment(env);
    }

    runtime.process->start(executable, args);
    if (!runtime.process->waitForStarted(3000)) {
        runtime.state = "Retrying";
        runtime.lastError = runtime.process->errorString();
        emit logLine(profileId, QStringLiteral("failed to start wsfs: %1").arg(runtime.lastError));
        scheduleRetry(profileId);
    } else {
        runtime.state = "Running";
        runtime.runningSinceMs = QDateTime::currentMSecsSinceEpoch();
        emit logLine(profileId, QStringLiteral("mount started"));
    }

    emit stateChanged();
}

void MountRunner::stopProfile(const QString &profileId, bool quitting)
{
    clearRetry(profileId);

    Runtime &runtime = m_runtime[profileId];
    if (!runtime.process || runtime.process->state() == QProcess::NotRunning) {
        runtime.state = "Stopped";
        emit stateChanged();
        return;
    }

    runtime.state = "Stopping";
    runtime.stopRequested = true;
    emit stateChanged();

#if defined(Q_OS_WIN)
    runtime.process->kill();
    runtime.process->waitForFinished(kKillWaitMs);
#else
    runtime.process->terminate();
    if (!runtime.process->waitForFinished(kStopGraceMs)) {
        runtime.process->kill();
        runtime.process->waitForFinished(kKillWaitMs);
    }
#endif

    runtime.state = "Stopped";
    if (!quitting)
        emit logLine(profileId, QStringLiteral("mount stopped"));
    emit stateChanged();
}

void MountRunner::stopAll(const QList<Profile> &profiles, bool quitting)
{
    for (const Profile &profile : profiles)
        stopProfile(profile.id, quitting);
}

void MountRunner::removeProfile(const QString &profileId)
{
    clearRetry(profileId);
    Runtime runtime = m_runtime.take(profileId);
    if (runtime.process) {
        if (runtime.process->state() != QProcess::NotRunning)
            runtime.process->kill();
        runtime.process->deleteLater();
    }
    if (runtime.retryTimer)
        runtime.retryTimer->deleteLater();
}

void MountRunner::setQuitting(bool quitting)
{
    m_isQuitting = quitting;
}

Profile *MountRunner::profileFor(const QString &profileId) const
{
    return m_profileLookup ? m_profileLookup(profileId) : nullptr;
}

QString MountRunner::resolvedExecutable() const
{
    return m_executableResolver ? m_executableResolver() : QString();
}

void MountRunner::scheduleRetry(const QString &profileId)
{
    Runtime &runtime = m_runtime[profileId];

    if (!runtime.retryTimer) {
        runtime.retryTimer = new QTimer(this);
        runtime.retryTimer->setSingleShot(true);
        connect(runtime.retryTimer, &QTimer::timeout, this, [this, profileId]() {
            startProfile(profileId);
        });
    }

    const int delaySec = runtime.retryDelaySec;
    runtime.retryDelaySec = qMin(runtime.retryDelaySec * 2, kRetryMaxDelaySec);
    runtime.retryTimer->start(delaySec * 1000);

    emit logLine(profileId, QStringLiteral("retry in %1 seconds").arg(delaySec));
    emit stateChanged();
}

void MountRunner::clearRetry(const QString &profileId)
{
    Runtime &runtime = m_runtime[profileId];
    if (runtime.retryTimer)
        runtime.retryTimer->stop();
    runtime.retryDelaySec = 1;
}

void MountRunner::ensureProcess(const QString &profileId, Runtime &runtime)
{
    if (runtime.process)
        return;

    runtime.process = new QProcess(this);
    runtime.process->setProcessChannelMode(QProcess::SeparateChannels);

    connect(runtime.process, &QProcess::readyReadStandardOutput, this, [this, profileId]() {
        Runtime &rt = m_runtime[profileId];
        const QString out = QString::fromUtf8(rt.process->readAllStandardOutput());
        if (!out.isEmpty())
            emit logLine(profileId, QStringLiteral("stdout: %1").arg(stripAnsi(out).trimmed()));
    });

    connect(runtime.process, &QProcess::readyReadStandardError, this, [this, profileId]() {
        Runtime &rt = m_runtime[profileId];
        const QString out = QString::fromUtf8(rt.process->readAllStandardError());
        if (!out.isEmpty())
            emit logLine(profileId, QStringLiteral("stderr: %1").arg(stripAnsi(out).trimmed()));
    });

    connect(runtime.process, &QProcess::errorOccurred, this, [this, profileId](QProcess::ProcessError error) {
        Runtime &rt = m_runtime[profileId];
        rt.state = "Failed";
        rt.lastError = QStringLiteral("process error: %1").arg(static_cast<int>(error));
        emit logLine(profileId, QStringLiteral("process error: %1").arg(static_cast<int>(error)));
        emit stateChanged();
    });

    connect(runtime.process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
        [this, profileId](int exitCode, QProcess::ExitStatus status) {
            Profile *profile = profileFor(profileId);
            Runtime &rt = m_runtime[profileId];
            const bool requestedStop = rt.stopRequested;
            rt.stopRequested = false;
            const bool ranLongEnough = (QDateTime::currentMSecsSinceEpoch() - rt.runningSinceMs) >= (kRetryResetRunThresholdSec * 1000LL);
            if (ranLongEnough)
                rt.retryDelaySec = 1;

            const bool gracefulRequestedExit = requestedStop && status == QProcess::NormalExit && exitCode == 0;
            if (gracefulRequestedExit) {
                rt.lastError.clear();
                rt.state = "Stopped";
                emit stateChanged();
                return;
            }

            if (status == QProcess::CrashExit) {
                rt.lastError = QStringLiteral("crash exit");
            } else if (exitCode == 0) {
                rt.lastError.clear();
            } else {
                rt.lastError = QStringLiteral("exit code %1").arg(exitCode);
            }

            if (!requestedStop && profile && profile->enabled && !m_isQuitting) {
                rt.state = "Retrying";
                scheduleRetry(profileId);
            } else {
                rt.state = "Stopped";
            }
            emit stateChanged();
        });
}
