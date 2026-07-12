#include "environment_probe.hpp"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QSettings>
#include <QStandardPaths>

namespace {
#if defined(Q_OS_WIN)
QString winfspDllNameForArch()
{
#if defined(Q_PROCESSOR_ARM_64)
    return QStringLiteral("winfsp-a64.dll");
#elif defined(Q_PROCESSOR_X86_64)
    return QStringLiteral("winfsp-x64.dll");
#elif defined(Q_PROCESSOR_X86_32)
    return QStringLiteral("winfsp-x86.dll");
#else
    return QString();
#endif
}

bool hasFile(const QString &path)
{
    if (path.isEmpty())
        return false;
    const QFileInfo info(path);
    return info.exists() && info.isFile();
}

bool existsInDirectories(const QString &fileName, const QStringList &dirs)
{
    for (const QString &dir : dirs) {
        if (dir.isEmpty())
            continue;
        const QString candidate = QDir(dir).filePath(fileName);
        if (hasFile(candidate))
            return true;
    }
    return false;
}

bool detectWinFsp()
{
    const QString dllName = winfspDllNameForArch();
    if (dllName.isEmpty())
        return false;

    QStringList probeDirs;
    probeDirs << QCoreApplication::applicationDirPath();
    probeDirs << qEnvironmentVariable("SystemRoot") + QStringLiteral("\\System32");
    probeDirs << qEnvironmentVariable("SystemRoot");
    probeDirs << qEnvironmentVariable("WINDIR") + QStringLiteral("\\System32");
    probeDirs << qEnvironmentVariable("WINDIR");
    probeDirs << qEnvironmentVariable("PATH").split(';', Qt::SkipEmptyParts);
    if (existsInDirectories(dllName, probeDirs))
        return true;

    const QStringList regPaths = {
        QStringLiteral("HKEY_LOCAL_MACHINE\\Software\\WinFsp"),
        QStringLiteral("HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\WinFsp")
    };

    for (const QString &regPath : regPaths) {
        QSettings reg(regPath, QSettings::NativeFormat);
        const QString installDir = reg.value(QStringLiteral("InstallDir")).toString().trimmed();
        if (installDir.isEmpty())
            continue;

        const QString dllPath = QDir(installDir).filePath(QStringLiteral("bin/%1").arg(dllName));
        if (hasFile(dllPath))
            return true;
    }
    return false;
}
#endif
}

QString EnvironmentProbe::resolveWsfsExecutable(const QString &configuredPath)
{
    if (!configuredPath.isEmpty())
        return configuredPath;

#if defined(Q_OS_WIN)
    const QString localName = QStringLiteral("wsfs.exe");
#else
    const QString localName = QStringLiteral("wsfs");
#endif

    const QString localPath = QDir(QCoreApplication::applicationDirPath()).filePath(localName);
    const QFileInfo localInfo(localPath);
    if (localInfo.exists() && localInfo.isFile() && localInfo.isExecutable())
        return localPath;

    QString fromPath = QStandardPaths::findExecutable(QStringLiteral("wsfs"));
#if defined(Q_OS_WIN)
    if (fromPath.isEmpty())
        fromPath = QStandardPaths::findExecutable(QStringLiteral("wsfs.exe"));
#endif
    return fromPath;
}

EnvironmentStatus EnvironmentProbe::probe(const QString &configuredPath)
{
    EnvironmentStatus status;
    status.wsfsVersionOk = true;
    status.wsfsVersionLine.clear();

    const QString executable = resolveWsfsExecutable(configuredPath);
    status.wsfsReady = !executable.isEmpty();

    if (status.wsfsReady) {
        QProcess probeProcess;
        probeProcess.start(executable, QStringList() << "version");
        if (!probeProcess.waitForStarted(1500)) {
            status.wsfsVersionOk = false;
        } else if (!probeProcess.waitForFinished(2500)) {
            probeProcess.kill();
            probeProcess.waitForFinished(500);
            status.wsfsVersionOk = false;
        } else if (probeProcess.exitStatus() != QProcess::NormalExit || probeProcess.exitCode() != 0) {
            status.wsfsVersionOk = false;
        }

        const QString out = QString::fromUtf8(probeProcess.readAllStandardOutput()).trimmed();
        const QString err = QString::fromUtf8(probeProcess.readAllStandardError()).trimmed();
        const QString merged = out.isEmpty() ? err : out;
        if (!merged.isEmpty())
            status.wsfsVersionLine = merged.split('\n').first().trimmed();
    }

#if defined(Q_OS_LINUX)
    status.linuxFuse3Ready = !QStandardPaths::findExecutable("fusermount3").isEmpty();
#else
    status.linuxFuse3Ready = true;
#endif

#if defined(Q_OS_WIN)
    status.winfspStatus = detectWinFsp() ? "ready" : "missing";
#else
    status.winfspStatus = "n/a";
#endif

    return status;
}
