#include "system_integration.hpp"

#include <QAction>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QIcon>
#include <QMenu>
#include <QSettings>
#include <QStandardPaths>
#include <QSystemTrayIcon>

SystemIntegration::SystemIntegration(QObject *parent)
    : QObject(parent)
{
}

SystemIntegration::~SystemIntegration()
{
    delete m_trayMenu;
}

namespace {
QString desktopExecArgument(const QString &path)
{
    QString escaped = path;
    escaped.replace('\\', QStringLiteral("\\\\"));
    escaped.replace('"', QStringLiteral("\\\""));
    return QStringLiteral("\"") + escaped + QStringLiteral("\"");
}

QString linuxStartupExecutable()
{
    // In an AppImage, applicationFilePath() points into the temporary mount.
    // APPIMAGE points to the persistent AppImage file that can be launched at login.
    const QString appImagePath = qEnvironmentVariable("APPIMAGE").trimmed();
    if (!appImagePath.isEmpty() && QFileInfo::exists(appImagePath) && QFileInfo(appImagePath).isFile())
        return appImagePath;

    return QCoreApplication::applicationFilePath();
}
} // namespace

void SystemIntegration::setupTray()
{
    if (!QSystemTrayIcon::isSystemTrayAvailable())
        return;

    m_trayIcon = new QSystemTrayIcon(this);
    m_trayIcon->setIcon(QIcon(QStringLiteral(":/assets/app-icon.png")));

    m_trayMenu = new QMenu();
    QAction *showAction = m_trayMenu->addAction(tr("Show"));
    QAction *stopAction = m_trayMenu->addAction(tr("Stop All"));
    QAction *quitAction = m_trayMenu->addAction(tr("Quit"));

    connect(showAction, &QAction::triggered, this, &SystemIntegration::showRequested);
    connect(stopAction, &QAction::triggered, this, &SystemIntegration::stopAllRequested);
    connect(quitAction, &QAction::triggered, this, &SystemIntegration::quitRequested);

    connect(m_trayIcon, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger)
            emit showRequested();
    });

    m_trayIcon->setContextMenu(m_trayMenu);
    m_trayIcon->show();
}

void SystemIntegration::applyAutoStart(bool enabled)
{
#if defined(Q_OS_LINUX)
    const QString autostartDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/autostart";
    QDir().mkpath(autostartDir);
    const QString desktopFilePath = autostartDir + "/wsfs-gui.desktop";

    if (!enabled) {
        QFile::remove(desktopFilePath);
        return;
    }

    QFile file(desktopFilePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;

    const QString desktop = QString(
        "[Desktop Entry]\n"
        "Type=Application\n"
        "Name=WSFS Mount Manager\n"
        "Exec=%1\n"
        "Terminal=false\n"
        "X-GNOME-Autostart-enabled=true\n").arg(desktopExecArgument(linuxStartupExecutable()));
    file.write(desktop.toUtf8());
#elif defined(Q_OS_WIN)
    QSettings runKey("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", QSettings::NativeFormat);
    const QString name = "WsfsGui";
    if (enabled) {
        runKey.setValue(name, QDir::toNativeSeparators(QCoreApplication::applicationFilePath()));
    } else {
        runKey.remove(name);
    }
#else
    Q_UNUSED(enabled)
#endif
}
