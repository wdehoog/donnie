/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifdef QT_QML_DEBUG
#include <QtQuick>
#else
#include <QQuickView>
#include <QQmlContext>
#include <QGuiApplication>
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

    QQmlEngine *engine = view->engine();
    engine->addImageProvider(QLatin1String("donnie-icons"), new IconProvider);

    UPNP upnp;
    view->rootContext()->setContextProperty("upnp", &upnp);

    view->setSource(SailfishApp::pathTo("qml/donnie.qml"));
    view->show();

    return app->exec();

    //return SailfishApp::main(argc, argv);
}
