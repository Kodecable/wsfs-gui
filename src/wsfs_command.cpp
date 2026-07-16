#include "wsfs_command.hpp"

QString buildWsfsEndpoint(const Profile &profile)
{
    QString endpoint = QStringLiteral("%1://").arg(profile.scheme);

    if (!profile.username.isEmpty()) {
        endpoint += profile.username;
        endpoint += '@';
    }

    endpoint += profile.host;
    if (profile.port > 0)
        endpoint += QStringLiteral(":%1").arg(profile.port);

    QString path = profile.path;
    if (path.isEmpty())
        path = "/";
    if (!path.startsWith('/'))
        path.prepend('/');
    endpoint += path;

    if (profile.appendWsfsQuery)
        endpoint += endpoint.contains('?') ? "&wsfs" : "?wsfs";

    return endpoint;
}

QStringList buildWsfsMountArgs(const Profile &profile)
{
    QStringList args;
    args << "mount" << buildWsfsEndpoint(profile) << profile.mountPoint;
    args << "--level" << profile.logLevel;
    args << "--no-log-time";
    args << "--no-log-color";
    if (profile.structTimeout >= 0)
        args << "--struct-timeout" << QString::number(profile.structTimeout);
    if (!profile.password.isEmpty())
        args << "--password" << "env:WSFS_GUI_PWD";
    if (profile.pingInterval >= 0)
        args << "--ping-interval" << QString::number(profile.pingInterval);
    if (!profile.certHash.isEmpty())
        args << "--cert-hash" << profile.certHash;

#if defined(Q_OS_LINUX)
    args << "--json-log";
    if (!profile.flockMode.isEmpty())
        args << "--flock" << profile.flockMode;
#endif

#if defined(Q_OS_LINUX)
    if (profile.directMount)
        args << "--direct-mount";
    if (profile.uid >= 0)
        args << "--uid" << QString::number(profile.uid);
    if (profile.gid >= 0)
        args << "--gid" << QString::number(profile.gid);
    if (profile.otherUid >= 0)
        args << "--other-uid" << QString::number(profile.otherUid);
    if (profile.otherGid >= 0)
        args << "--other-gid" << QString::number(profile.otherGid);
#endif

#if defined(Q_OS_WIN)
    if (!profile.volumeLabel.trimmed().isEmpty())
        args << "--volume-label" << profile.volumeLabel;
    if (profile.masqueradeAsNtfs)
        args << "--masquerade-as-ntfs";
#endif

    return args;
}

QString quoteProcessArgument(const QString &argument)
{
    if (argument.isEmpty())
        return "''";
    if (!argument.contains(' ') && !argument.contains('"') && !argument.contains('\'') && !argument.contains('\t'))
        return argument;

    QString escaped = argument;
    escaped.replace("'", "'\\''");
    return QStringLiteral("'%1'").arg(escaped);
}
