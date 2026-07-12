#include <QApplication>
#include <QLocale>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTranslator>
#include <QIcon>

#include "app_controller.hpp"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setQuitOnLastWindowClosed(false);
    app.setWindowIcon(QIcon(QStringLiteral(":/assets/app-icon.png")));

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

    engine.setInitialProperties({{QStringLiteral("appModel"), QVariant::fromValue(&controller)}});
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    if (QQuickWindow *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first()))
        controller.attachMainWindow(window);

    controller.restoreOnLaunch();
    return app.exec();
}
