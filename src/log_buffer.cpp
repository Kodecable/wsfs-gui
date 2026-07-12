#include "log_buffer.hpp"

#include <QDateTime>

namespace {
constexpr int kMaxLogLines = 1024;
constexpr int kMaxLineBytes = 2048;

void trimToLimit(QStringList &lines)
{
    while (lines.size() > kMaxLogLines)
        lines.pop_front();
}
}

void LogBuffer::append(const QString &line, const QString &profileId)
{
    QString timestamped = QStringLiteral("[%1] %2")
                              .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss"), line);
    if (timestamped.toUtf8().size() > kMaxLineBytes) {
        const QByteArray truncated = timestamped.toUtf8().left(kMaxLineBytes - 3);
        timestamped = QString::fromUtf8(truncated) + QStringLiteral("...");
    }
    m_lines.push_back(timestamped);
    trimToLimit(m_lines);

    if (!profileId.isEmpty()) {
        QStringList &profileLog = m_profileLines[profileId];
        profileLog.push_back(timestamped);
        trimToLimit(profileLog);
    }
}

void LogBuffer::removeProfile(const QString &profileId)
{
    m_profileLines.remove(profileId);
}

QString LogBuffer::allLogs() const
{
    return m_lines.join("\n");
}

QString LogBuffer::profileLogs(const QString &profileId) const
{
    return m_profileLines.value(profileId).join("\n");
}
