#pragma once

#include <QJsonObject>
#include <QString>

struct AppSettings {
    bool autoStartOnBoot = false;
    bool minimizeToTrayOnLaunch = false;
    bool restoreEnabledProfilesOnLaunch = true;
    bool useSystemCredentialStore = false;
    QString wsfsExecutablePath;
};

AppSettings settingsFromJson(const QJsonObject &object);
QJsonObject settingsToJson(const AppSettings &settings);
