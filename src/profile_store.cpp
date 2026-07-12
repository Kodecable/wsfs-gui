#include "profile_store.hpp"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QStandardPaths>

QList<Profile> ProfileStore::loadProfiles() const
{
    QDir().mkpath(configDir());

    QList<Profile> profiles;
    QFile file(profilesFilePath());
    if (!file.exists() || !file.open(QIODevice::ReadOnly))
        return profiles;

    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isArray())
        return profiles;

    const QJsonArray array = document.array();
    profiles.reserve(array.size());
    for (const QJsonValue &value : array) {
        if (!value.isObject())
            continue;
        profiles.push_back(profileFromJson(value.toObject(), profiles.size() + 1));
    }
    return profiles;
}

AppSettings ProfileStore::loadSettings() const
{
    QDir().mkpath(configDir());

    QFile file(settingsFilePath());
    if (!file.exists() || !file.open(QIODevice::ReadOnly))
        return {};

    const QJsonDocument document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject())
        return {};

    return settingsFromJson(document.object());
}

void ProfileStore::saveProfiles(const QList<Profile> &profiles, bool includePasswords) const
{
    QDir().mkpath(configDir());

    QJsonArray array;
    for (const Profile &profile : profiles)
        array.push_back(profileToJson(profile, includePasswords));

    QFile file(profilesFilePath());
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        file.write(QJsonDocument(array).toJson(QJsonDocument::Indented));
}

void ProfileStore::saveSettings(const AppSettings &settings) const
{
    QDir().mkpath(configDir());

    QFile file(settingsFilePath());
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate))
        file.write(QJsonDocument(settingsToJson(settings)).toJson(QJsonDocument::Indented));
}

QString ProfileStore::configDir() const
{
    return QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
}

QString ProfileStore::profilesFilePath() const
{
    return configDir() + "/profiles.json";
}

QString ProfileStore::settingsFilePath() const
{
    return configDir() + "/settings.json";
}
