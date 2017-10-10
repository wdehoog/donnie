/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


#ifdef QT_QML_DEBUG
#include <QtQuick>
#else
#include <QQuickView>
#include <QQmlContext>
#include <QGuiApplication>
#include <QTranslator>
#endif


#include <sailfishapp.h>

#include "IconProvider.h"
#include "upnp.h"

int main(int argc, char *argv[])
{
    // SailfishApp::main() will display "qml/template.qml", if you need more
    // control over initialization, you can use:
    //
    //   - SailfishApp::application(int, char *[]) to get the QGuiApplication *
    //   - SailfishApp::createView() to get a new QQuickView * instance
    //   - SailfishApp::pathTo(QString) to get a QUrl to a resource file
    //
    // To display the view, call "show()" (will show fullscreen on device).

    QGuiApplication * app = SailfishApp::application(argc,argv);
    QQuickView * view = SailfishApp::createView();

    // custom icon loader
    QQmlEngine *engine = view->engine();
    engine->addImageProvider(QLatin1String("donnie-icons"), new IconProvider);

    // translations
    QTranslator translator;
    translator.load("donnie-" + QLocale::system().name(),
                        "/usr/share/donnie/translations");
    app->installTranslator(&translator);
    qDebug() << "Locale: " << QLocale::system().name();

    UPNP upnp;
    view->rootContext()->setContextProperty("upnp", &upnp);

    view->setSource(SailfishApp::pathTo("qml/donnie.qml"));
    view->show();

    return app->exec();

    //return SailfishApp::main(argc, argv);
}
