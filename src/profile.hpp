#pragma once

#include <QJsonObject>
#include <QString>
#include <QVariantMap>

struct Profile {
    QString id;
    QString name;
    bool enabled = false;
    QString scheme = "wsfs";
    QString host = "localhost";
    int port = 20001;
    QString path = "/";
    bool appendWsfsQuery = true;
    QString username;
    QString password;
    QString mountPoint;
    QString logLevel = "info";
    int structTimeout = -1;

    bool directMount = false;
    int uid = -1;
    int gid = -1;
    int otherUid = -1;
    int otherGid = -1;

    int pingInterval = -1;
    QString certHash;
    QString flockMode;

    QString volumeLabel;
    bool masqueradeAsNtfs = false;
};

QVariantMap profileToDetailMap(const Profile &profile);
QVariantMap profileToSummaryBaseMap(const Profile &profile);
QJsonObject profileToJson(const Profile &profile);
QJsonObject profileToJson(const Profile &profile, bool includePassword);
Profile profileFromJson(const QJsonObject &object, int fallbackIndex);
bool updateProfileFromPayload(Profile &profile, const QVariantMap &payload);
QString defaultMountPoint(int index);
