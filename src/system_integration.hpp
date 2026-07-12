#pragma once

#include <QObject>

class QMenu;
class QSystemTrayIcon;

class SystemIntegration : public QObject
{
    Q_OBJECT

public:
    explicit SystemIntegration(QObject *parent = nullptr);
    ~SystemIntegration() override;

    void setupTray();
    static void applyAutoStart(bool enabled);

signals:
    void showRequested();
    void stopAllRequested();
    void quitRequested();

private:
    QSystemTrayIcon *m_trayIcon = nullptr;
    QMenu *m_trayMenu = nullptr;
};
