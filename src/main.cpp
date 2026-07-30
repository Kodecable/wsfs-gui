#include <QApplication>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QResource>
#include <QTranslator>
#include <QIcon>

#include "app_controller.hpp"
#include "kdsingleapplication.h"

namespace {
const QByteArray kActivateMessage("activate");
}

int main(int argc, char *argv[])
{
    Q_INIT_RESOURCE(application_resources);
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    QApplication app(argc, argv);
    app.setObjectName("wsfs");
    app.setApplicationName("wsfs-gui");
    app.setQuitOnLastWindowClosed(false);
    app.setWindowIcon(QIcon(QStringLiteral(":/assets/app-icon.png")));

    KDSingleApplication singleInstance(app.applicationName());
    if (!singleInstance.isPrimaryInstance()) {
        if (!singleInstance.sendMessageWithTimeout(kActivateMessage, 1000))
            qWarning() << "Unable to notify the primary wsfs-gui instance";
        return 0;
    }

    QTranslator translator;
    const QLocale locale = QLocale::system();
    if (locale.language() == QLocale::Chinese) {
        const bool loaded = translator.load(QStringLiteral(":/i18n/wsfs_gui_zh_CN.qm"));
        if (loaded)
            app.installTranslator(&translator);
        else
            qCritical() << "Unable to load translator file";
    }

    QQmlApplicationEngine engine;
    AppController controller;

    QObject::connect(
        &singleInstance,
        &KDSingleApplication::messageReceived,
        &controller,
        [&controller](const QByteArray &message) {
            if (message == kActivateMessage)
                controller.showMainWindow();
        });

    engine.setInitialProperties({{QStringLiteral("appModel"), QVariant::fromValue(&controller)}});
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    if (QQuickWindow *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first()))
        controller.attachMainWindow(window);

    controller.restoreOnLaunch();
    return app.exec();
}
