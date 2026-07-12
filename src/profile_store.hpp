#pragma once

#include "app_settings.hpp"
#include "profile.hpp"

#include <QList>
#include <QString>

class ProfileStore
{
public:
    QList<Profile> loadProfiles() const;
    AppSettings loadSettings() const;
    void saveProfiles(const QList<Profile> &profiles, bool includePasswords = true) const;
    void saveSettings(const AppSettings &settings) const;

private:
    QString configDir() const;
    QString profilesFilePath() const;
    QString settingsFilePath() const;
};
