#include "system_integration.hpp"

#include <QAction>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
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
        "X-GNOME-Autostart-enabled=true\n").arg(QCoreApplication::applicationFilePath());
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
