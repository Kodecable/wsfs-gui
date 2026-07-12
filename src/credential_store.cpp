#include "credential_store.hpp"

#include <qtkeychain/keychain.h>

namespace {
constexpr auto kCredentialService = "wsfs-gui";
}

CredentialStore::CredentialStore(QObject *parent)
    : QObject(parent)
{
}

void CredentialStore::readPassword(const QString &profileId, Callback callback)
{
    auto *job = new QKeychain::ReadPasswordJob(QString::fromLatin1(kCredentialService), this);
    job->setKey(keyForProfile(profileId));
    job->setInsecureFallback(false);

    connect(job, &QKeychain::ReadPasswordJob::finished, this,
            [callback = std::move(callback)](QKeychain::Job *finishedJob) {
                auto *readJob = static_cast<QKeychain::ReadPasswordJob *>(finishedJob);
                Result result;
                result.ok = readJob->error() == QKeychain::NoError;
                result.entryNotFound = readJob->error() == QKeychain::EntryNotFound;
                if (result.ok)
                    result.password = readJob->textData();
                else if (result.entryNotFound)
                    result.ok = true;
                else
                    result.error = readJob->errorString();
                callback(result);
            });
    job->start();
}

void CredentialStore::writePassword(const QString &profileId, const QString &password, Callback callback)
{
    auto *job = new QKeychain::WritePasswordJob(QString::fromLatin1(kCredentialService), this);
    job->setKey(keyForProfile(profileId));
    job->setTextData(password);
    job->setInsecureFallback(false);

    connect(job, &QKeychain::WritePasswordJob::finished, this,
            [callback = std::move(callback)](QKeychain::Job *finishedJob) {
                Result result;
                result.ok = finishedJob->error() == QKeychain::NoError;
                if (!result.ok)
                    result.error = finishedJob->errorString();
                callback(result);
            });
    job->start();
}

void CredentialStore::deletePassword(const QString &profileId, Callback callback)
{
    auto *job = new QKeychain::DeletePasswordJob(QString::fromLatin1(kCredentialService), this);
    job->setKey(keyForProfile(profileId));
    job->setInsecureFallback(false);

    connect(job, &QKeychain::DeletePasswordJob::finished, this,
            [callback = std::move(callback)](QKeychain::Job *finishedJob) {
                Result result;
                result.ok = finishedJob->error() == QKeychain::NoError || finishedJob->error() == QKeychain::EntryNotFound;
                result.entryNotFound = finishedJob->error() == QKeychain::EntryNotFound;
                if (!result.ok)
                    result.error = finishedJob->errorString();
                callback(result);
            });
    job->start();
}

QString CredentialStore::keyForProfile(const QString &profileId) const
{
    return QStringLiteral("profile/%1/password").arg(profileId);
}
