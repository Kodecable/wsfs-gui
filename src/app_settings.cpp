#include "app_settings.hpp"

AppSettings settingsFromJson(const QJsonObject &object)
{
    AppSettings settings;
    settings.autoStartOnBoot = object.value("autoStartOnBoot").toBool(false);
    settings.minimizeToTrayOnLaunch = object.value("minimizeToTrayOnLaunch").toBool(false);
    settings.restoreEnabledProfilesOnLaunch = object.value("restoreEnabledProfilesOnLaunch").toBool(true);
    settings.useSystemCredentialStore = object.value("useSystemCredentialStore").toBool(false);
    settings.wsfsExecutablePath = object.value("wsfsExecutablePath").toString().trimmed();
    return settings;
}

QJsonObject settingsToJson(const AppSettings &settings)
{
    QJsonObject object;
    object["autoStartOnBoot"] = settings.autoStartOnBoot;
    object["minimizeToTrayOnLaunch"] = settings.minimizeToTrayOnLaunch;
    object["restoreEnabledProfilesOnLaunch"] = settings.restoreEnabledProfilesOnLaunch;
    object["useSystemCredentialStore"] = settings.useSystemCredentialStore;
    object["wsfsExecutablePath"] = settings.wsfsExecutablePath;
    return object;
}
