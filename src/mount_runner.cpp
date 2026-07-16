#include "mount_runner.hpp"

#include "environment_probe.hpp"
#include "wsfs_command.hpp"

#include <QDateTime>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>
#include <QRegularExpression>

namespace
{
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
} // namespace

MountRunner::MountRunner(QObject *parent) : QObject(parent) {}

void MountRunner::setProfileLookup(ProfileLookup lookup) { m_profileLookup = std::move(lookup); }

void MountRunner::setExecutableResolver(ExecutableResolver resolver) { m_executableResolver = std::move(resolver); }

MountRuntimeState MountRunner::runtimeState(const QString &profileId) const
{
    const Runtime runtime = m_runtime.value(profileId);

    MountRuntimeState state;
    state.state = runtime.state;
    state.lastError = runtime.lastError;
    state.nextRetrySec =
        runtime.retryTimer && runtime.retryTimer->isActive() ? runtime.retryTimer->remainingTime() / 1000 : -1;
    state.pid = runtime.state == "Running" && runtime.process && runtime.process->processId() > 0
                    ? runtime.process->processId()
                    : -1;
    return state;
}

void MountRunner::ensureDesiredState(const QString &profileId)
{
    Profile *profile = profileFor(profileId);
    if (!profile || !profile->enabled) return;

    Runtime &runtime = m_runtime[profileId];
    if (runtime.process && runtime.process->state() != QProcess::NotRunning) return;

    clearRetry(profileId);
    startProfile(profileId);
}

void MountRunner::startProfile(const QString &profileId)
{
    Profile *profile = profileFor(profileId);
    if (!profile) return;

    Runtime &runtime = m_runtime[profileId];
    if (runtime.process && runtime.process->state() != QProcess::NotRunning) return;

    ensureProcess(profileId, runtime);

    runtime.state = "Starting";
    runtime.lastError.clear();
    runtime.stopRequested = false;
    runtime.fuseConnectionId = -1;
    runtime.standardOutputBuffer.clear();
    emit stateChanged();

    const QStringList args = buildWsfsMountArgs(*profile);
    QString executable = resolvedExecutable();
    if (executable.isEmpty())
    {
#if defined(Q_OS_WIN)
        executable = QStringLiteral("wsfs.exe");
#else
        executable = QStringLiteral("wsfs");
#endif
    }

    QStringList quoted;
    quoted.reserve(args.size() + 1);
    quoted.push_back(quoteProcessArgument(executable));
    for (const QString &arg : args) quoted.push_back(quoteProcessArgument(arg));
    emit logLine(profileId, QStringLiteral("exec: %1").arg(quoted.join(' ')));

    if (!profile->password.isEmpty())
    {
        QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
        env.insert(QStringLiteral("WSFS_GUI_PWD"), profile->password);
        runtime.process->setProcessEnvironment(env);
    }

    runtime.process->start(executable, args);
    if (!runtime.process->waitForStarted(3000))
    {
        runtime.state = "Retrying";
        runtime.lastError = runtime.process->errorString();
        emit logLine(profileId, QStringLiteral("failed to start wsfs: %1").arg(runtime.lastError));
        scheduleRetry(profileId);
    }
    else
    {
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
    if (!runtime.process || runtime.process->state() == QProcess::NotRunning)
    {
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
    if (!runtime.process->waitForFinished(kStopGraceMs))
    {
        Profile *profile = profileFor(profileId);
        if (profile) forceUnmount(profileId, runtime, *profile);
        runtime.process->kill();
        runtime.process->waitForFinished(kKillWaitMs);
    }
#endif

    runtime.state = "Stopped";
    if (!quitting) emit logLine(profileId, QStringLiteral("mount stopped"));
    emit stateChanged();
}

void MountRunner::stopAll(const QList<Profile> &profiles, bool quitting)
{
    for (const Profile &profile : profiles) stopProfile(profile.id, quitting);
}

void MountRunner::removeProfile(const QString &profileId)
{
    clearRetry(profileId);
    Runtime runtime = m_runtime.take(profileId);
    if (runtime.process)
    {
        if (runtime.process->state() != QProcess::NotRunning) runtime.process->kill();
        runtime.process->deleteLater();
    }
    if (runtime.retryTimer) runtime.retryTimer->deleteLater();
}

void MountRunner::setQuitting(bool quitting) { m_isQuitting = quitting; }

Profile *MountRunner::profileFor(const QString &profileId) const
{ return m_profileLookup ? m_profileLookup(profileId) : nullptr; }

QString MountRunner::resolvedExecutable() const { return m_executableResolver ? m_executableResolver() : QString(); }

void MountRunner::scheduleRetry(const QString &profileId)
{
    Runtime &runtime = m_runtime[profileId];

    if (!runtime.retryTimer)
    {
        runtime.retryTimer = new QTimer(this);
        runtime.retryTimer->setSingleShot(true);
        connect(runtime.retryTimer, &QTimer::timeout, this, [this, profileId]() { startProfile(profileId); });
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
    if (runtime.retryTimer) runtime.retryTimer->stop();
    runtime.retryDelaySec = 1;
}

void MountRunner::ensureProcess(const QString &profileId, Runtime &runtime)
{
    if (runtime.process) return;

    runtime.process = new QProcess(this);
    runtime.process->setProcessChannelMode(QProcess::SeparateChannels);

    connect(runtime.process, &QProcess::readyReadStandardOutput, this, [this, profileId]() {
        Runtime &rt = m_runtime[profileId];
        handleStandardOutput(profileId, rt);
    });

    connect(runtime.process, &QProcess::readyReadStandardError, this, [this, profileId]() {
        Runtime &rt = m_runtime[profileId];
        const QString out = QString::fromUtf8(rt.process->readAllStandardError());
        if (!out.isEmpty()) emit logLine(profileId, QStringLiteral("stderr: %1").arg(stripAnsi(out).trimmed()));
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
                const bool ranLongEnough =
                    (QDateTime::currentMSecsSinceEpoch() - rt.runningSinceMs) >= (kRetryResetRunThresholdSec * 1000LL);
                if (ranLongEnough) rt.retryDelaySec = 1;

                const bool gracefulRequestedExit = requestedStop && status == QProcess::NormalExit && exitCode == 0;
                if (gracefulRequestedExit)
                {
                    rt.lastError.clear();
                    rt.state = "Stopped";
                    emit stateChanged();
                    return;
                }

                if (status == QProcess::CrashExit) { rt.lastError = QStringLiteral("crash exit"); }
                else if (exitCode == 0) { rt.lastError.clear(); }
                else
                {
                    rt.lastError = QStringLiteral("exit code %1").arg(exitCode);
                }

                if (!requestedStop && profile && profile->enabled && !m_isQuitting)
                {
                    rt.state = "Retrying";
                    scheduleRetry(profileId);
                }
                else
                {
                    rt.state = "Stopped";
                }
                emit stateChanged();
            });
}

void MountRunner::handleStandardOutput(const QString &profileId, Runtime &runtime)
{
    runtime.standardOutputBuffer.append(runtime.process->readAllStandardOutput());
    while (true)
    {
        const qsizetype newline = runtime.standardOutputBuffer.indexOf('\n');
        if (newline < 0) return;

        const QByteArray line = runtime.standardOutputBuffer.left(newline);
        runtime.standardOutputBuffer.remove(0, newline + 1);
        const QString output = QString::fromUtf8(line).trimmed();
        if (output.isEmpty()) continue;

        const QJsonDocument document = QJsonDocument::fromJson(line);
        const QJsonObject object = document.isObject() ? document.object() : QJsonObject{};

        QString message = object.value("message").toString();
        message = message.isEmpty() ? "<Missing Message>" : message;

        QString level = object.value("level").toString();
        level = level.isEmpty() ? "<Missing Level>" : level;
        level = level.toUpper();

        Profile *profile = profileFor(profileId);
        if (profile && message == QStringLiteral("FUSE connection Id obtained") &&
            object.value("Mountpoint").toString() == profile->mountPoint)
        {
            const qint64 connectionId = object.value("id").toVariant().toLongLong();
            if (connectionId > 0)
            {
                runtime.fuseConnectionId = connectionId;
                emit logLine(profileId, QStringLiteral("FUSE connection Id obtained: %1").arg(connectionId));
            }
        }

        QString formatedOutput = QString("%1 %2").arg(level).arg(message);
        for (const QString &key : object.keys()) {
            if (key == "level" || key == "message") 
                continue;
            formatedOutput.append(QString(" %1=%2").arg(key).arg(object[key].toVariant().toString()));
        }

        emit logLine(profileId, QStringLiteral("stdout: %1").arg(formatedOutput));
    }
}

void MountRunner::forceUnmount(const QString &profileId, Runtime &runtime, const Profile &profile)
{
#if defined(Q_OS_LINUX)
    if (profile.directMount || runtime.fuseConnectionId <= 0) return;

    emit logLine(profileId, QStringLiteral("mount did not exit gracefully; forcing FUSE abort and lazy unmount"));
    const QString abortPath = QStringLiteral("/sys/fs/fuse/connections/%1/abort").arg(runtime.fuseConnectionId);
    QFile abortFile(abortPath);
    if (abortFile.open(QIODevice::WriteOnly))
    {
        if (abortFile.write("1") < 0)
            emit logLine(profileId, QStringLiteral("failed to abort FUSE connection: %1").arg(abortFile.errorString()));
        else
            emit logLine(profileId, QStringLiteral("aborted FUSE connection %1").arg(runtime.fuseConnectionId));
    }
    else
    {
        emit logLine(profileId, QStringLiteral("failed to open FUSE abort endpoint: %1").arg(abortFile.errorString()));
    }

    QProcess fusermount;
    fusermount.start(QStringLiteral("fusermount3"), {QStringLiteral("-uz"), profile.mountPoint});
    if (!fusermount.waitForStarted(kKillWaitMs))
    {
        emit logLine(profileId, QStringLiteral("failed to start fusermount3: %1").arg(fusermount.errorString()));
        return;
    }
    if (!fusermount.waitForFinished(kKillWaitMs))
    {
        fusermount.kill();
        fusermount.waitForFinished(kKillWaitMs);
        emit logLine(profileId, QStringLiteral("fusermount3 timed out"));
        return;
    }
    if (fusermount.exitStatus() != QProcess::NormalExit || fusermount.exitCode() != 0)
        emit logLine(profileId, QStringLiteral("fusermount3 failed: %1")
                                    .arg(QString::fromUtf8(fusermount.readAllStandardError()).trimmed()));
    else
        emit logLine(profileId, QStringLiteral("force-unmounted %1").arg(profile.mountPoint));
#else
    Q_UNUSED(profileId)
    Q_UNUSED(runtime)
    Q_UNUSED(profile)
#endif
}
