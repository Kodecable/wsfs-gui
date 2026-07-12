#include "profile.hpp"

#include <QUuid>

namespace {
int parseOptionalInt(const QVariant &value, int unsetValue = -1)
{
    if (!value.isValid() || value.isNull())
        return unsetValue;

    bool ok = false;
    const int parsed = value.toInt(&ok);
    if (ok)
        return parsed;

    const QString text = value.toString().trimmed();
    if (text.isEmpty())
        return unsetValue;

    const int fromText = text.toInt(&ok);
    return ok ? fromText : unsetValue;
}
}

QVariantMap profileToDetailMap(const Profile &profile)
{
    QVariantMap map;
    map["id"] = profile.id;
    map["name"] = profile.name;
    map["enabled"] = profile.enabled;
    map["scheme"] = profile.scheme;
    map["host"] = profile.host;
    map["port"] = profile.port;
    map["path"] = profile.path;
    map["appendWsfsQuery"] = profile.appendWsfsQuery;
    map["username"] = profile.username;
    map["password"] = profile.password;
    map["mountPoint"] = profile.mountPoint;
    map["logLevel"] = profile.logLevel;
    map["structTimeout"] = profile.structTimeout;
    map["directMount"] = profile.directMount;
    map["uid"] = profile.uid;
    map["gid"] = profile.gid;
    map["otherUid"] = profile.otherUid;
    map["otherGid"] = profile.otherGid;
    map["pingInterval"] = profile.pingInterval;
    map["certHash"] = profile.certHash;
    map["flockMode"] = profile.flockMode;
    map["volumeLabel"] = profile.volumeLabel;
    map["masqueradeAsNtfs"] = profile.masqueradeAsNtfs;
    return map;
}

QVariantMap profileToSummaryBaseMap(const Profile &profile)
{
    QVariantMap map;
    map["id"] = profile.id;
    map["name"] = profile.name;
    map["enabled"] = profile.enabled;
    return map;
}

QJsonObject profileToJson(const Profile &profile)
{
    return profileToJson(profile, true);
}

QJsonObject profileToJson(const Profile &profile, bool includePassword)
{
    QJsonObject object;
    object["id"] = profile.id;
    object["name"] = profile.name;
    object["enabled"] = profile.enabled;
    object["scheme"] = profile.scheme;
    object["host"] = profile.host;
    object["port"] = profile.port;
    object["path"] = profile.path;
    object["appendWsfsQuery"] = profile.appendWsfsQuery;
    object["username"] = profile.username;
    if (includePassword)
        object["password"] = profile.password;
    object["mountPoint"] = profile.mountPoint;
    object["logLevel"] = profile.logLevel;
    object["structTimeout"] = profile.structTimeout;
    object["directMount"] = profile.directMount;
    object["uid"] = profile.uid;
    object["gid"] = profile.gid;
    object["otherUid"] = profile.otherUid;
    object["otherGid"] = profile.otherGid;
    object["pingInterval"] = profile.pingInterval;
    object["certHash"] = profile.certHash;
    object["flockMode"] = profile.flockMode;
    object["volumeLabel"] = profile.volumeLabel;
    object["masqueradeAsNtfs"] = profile.masqueradeAsNtfs;
    return object;
}

Profile profileFromJson(const QJsonObject &object, int fallbackIndex)
{
    Profile profile;
    profile.id = object.value("id").toString(QUuid::createUuid().toString(QUuid::WithoutBraces));
    profile.name = object.value("name").toString("Mount");
    profile.enabled = object.value("enabled").toBool(false);
    profile.scheme = object.value("scheme").toString("wsfs");
    profile.host = object.value("host").toString("localhost");
    profile.port = object.value("port").toInt(20001);
    profile.path = object.value("path").toString("/");
    profile.appendWsfsQuery = object.value("appendWsfsQuery").toBool(true);
    profile.username = object.value("username").toString();
    profile.password = object.value("password").toString();
    profile.mountPoint = object.value("mountPoint").toString();
    profile.logLevel = object.value("logLevel").toString("info");
    profile.structTimeout = object.value("structTimeout").toInt(-1);
    profile.directMount = object.value("directMount").toBool(false);
    profile.uid = object.value("uid").toInt(-1);
    profile.gid = object.value("gid").toInt(-1);
    if (object.contains("otherUid")) {
        profile.otherUid = object.value("otherUid").toInt(-1);
    } else if (object.contains("nobodyUid")) {
        profile.otherUid = object.value("nobodyUid").toInt(-1);
    } else {
        profile.otherUid = -1;
    }
    if (object.contains("otherGid")) {
        profile.otherGid = object.value("otherGid").toInt(-1);
    } else if (object.contains("nobodyGid")) {
        profile.otherGid = object.value("nobodyGid").toInt(-1);
    } else {
        profile.otherGid = -1;
    }
    profile.pingInterval = object.value("pingInterval").toInt(-1);
    profile.certHash = object.value("certHash").toString();
    profile.flockMode = object.value("flockMode").toString();
    profile.volumeLabel = object.value("volumeLabel").toString();
    profile.masqueradeAsNtfs = object.value("masqueradeAsNtfs").toBool(false);

    if (profile.mountPoint.isEmpty())
        profile.mountPoint = defaultMountPoint(fallbackIndex);

    return profile;
}

bool updateProfileFromPayload(Profile &profile, const QVariantMap &payload)
{
    auto readString = [&payload](const char *key, const QString &fallback) {
        return payload.contains(key) ? payload.value(key).toString().trimmed() : fallback;
    };

    profile.name = readString("name", profile.name);
    profile.scheme = readString("scheme", profile.scheme);
    profile.host = readString("host", profile.host);
    profile.path = readString("path", profile.path);
    profile.username = payload.value("username").toString();
    if (payload.contains("password"))
        profile.password = payload.value("password").toString();
    profile.mountPoint = readString("mountPoint", profile.mountPoint);
    profile.logLevel = readString("logLevel", profile.logLevel);
    if (payload.contains("volumeLabel"))
        profile.volumeLabel = payload.value("volumeLabel").toString().trimmed();

    if (payload.contains("port"))
        profile.port = payload.value("port").toInt();
    if (payload.contains("appendWsfsQuery"))
        profile.appendWsfsQuery = payload.value("appendWsfsQuery").toBool();
    if (payload.contains("structTimeout"))
        profile.structTimeout = parseOptionalInt(payload.value("structTimeout"));
    if (payload.contains("directMount"))
        profile.directMount = payload.value("directMount").toBool();
    if (payload.contains("uid"))
        profile.uid = parseOptionalInt(payload.value("uid"));
    if (payload.contains("gid"))
        profile.gid = parseOptionalInt(payload.value("gid"));
    if (payload.contains("otherUid"))
        profile.otherUid = parseOptionalInt(payload.value("otherUid"));
    if (payload.contains("otherGid"))
        profile.otherGid = parseOptionalInt(payload.value("otherGid"));
    if (payload.contains("pingInterval"))
        profile.pingInterval = parseOptionalInt(payload.value("pingInterval"));
    if (payload.contains("certHash"))
        profile.certHash = payload.value("certHash").toString().trimmed();
    if (payload.contains("flockMode"))
        profile.flockMode = payload.value("flockMode").toString().trimmed();
    if (payload.contains("masqueradeAsNtfs"))
        profile.masqueradeAsNtfs = payload.value("masqueradeAsNtfs").toBool();

    return !profile.name.isEmpty() && !profile.scheme.isEmpty() && !profile.host.isEmpty() && !profile.mountPoint.isEmpty();
}

QString defaultMountPoint(int index)
{
#if defined(Q_OS_WIN)
    Q_UNUSED(index)
    return QStringLiteral("P:");
#else
    return QStringLiteral("/mnt/wsfs-%1").arg(index);
#endif
}
