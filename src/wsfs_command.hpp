#pragma once

#include "profile.hpp"

#include <QString>
#include <QStringList>

QString buildWsfsEndpoint(const Profile &profile);
QStringList buildWsfsMountArgs(const Profile &profile);
QString quoteProcessArgument(const QString &argument);
