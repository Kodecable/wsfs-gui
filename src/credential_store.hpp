#pragma once

#include <QObject>
#include <QString>
#include <functional>

class CredentialStore : public QObject
{
    Q_OBJECT

public:
    struct Result {
        bool ok = false;
        QString password;
        QString error;
        bool entryNotFound = false;
    };

    using Callback = std::function<void(const Result &)>;

    explicit CredentialStore(QObject *parent = nullptr);

    void readPassword(const QString &profileId, Callback callback);
    void writePassword(const QString &profileId, const QString &password, Callback callback);
    void deletePassword(const QString &profileId, Callback callback);

private:
    QString keyForProfile(const QString &profileId) const;
};
