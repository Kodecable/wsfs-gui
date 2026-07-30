#include "profile_store.hpp"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>
#include <QStandardPaths>

namespace {
bool writeJsonFile(const QString &path, const QJsonDocument &document)
{
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly))
        return false;

    const QByteArray data = document.toJson(QJsonDocument::Indented);
    if (file.write(data) != data.size())
        return false;

    return file.commit();
}
} // namespace

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

bool ProfileStore::saveProfiles(const QList<Profile> &profiles, bool includePasswords) const
{
    if (!QDir().mkpath(configDir()))
        return false;

    QJsonArray array;
    for (const Profile &profile : profiles)
        array.push_back(profileToJson(profile, includePasswords));

    return writeJsonFile(profilesFilePath(), QJsonDocument(array));
}

bool ProfileStore::saveSettings(const AppSettings &settings) const
{
    if (!QDir().mkpath(configDir()))
        return false;

    return writeJsonFile(settingsFilePath(), QJsonDocument(settingsToJson(settings)));
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
