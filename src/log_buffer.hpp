#pragma once

#include <QHash>
#include <QString>
#include <QStringList>

class LogBuffer
{
public:
    void append(const QString &line, const QString &profileId = QString());
    void removeProfile(const QString &profileId);
    QString allLogs() const;
    QString profileLogs(const QString &profileId) const;

private:
    QStringList m_lines;
    QHash<QString, QStringList> m_profileLines;
};
