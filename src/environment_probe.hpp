#pragma once

#include <QString>

struct EnvironmentStatus {
    bool wsfsReady = true;
    bool wsfsVersionOk = true;
    bool linuxFuse3Ready = true;
    QString winfspStatus = "pending";
    QString wsfsVersionLine;
};

class EnvironmentProbe
{
public:
    static QString resolveWsfsExecutable(const QString &configuredPath);
    static EnvironmentStatus probe(const QString &configuredPath);
};
