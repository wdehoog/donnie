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

#ifndef UPNPSEARCHWORKER_H
#define UPNPSEARCHWORKER_H

#include <QObject>
#include <QVariantMap>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

#include <libupnpp/upnpplib.hxx>
#include <libupnpp/log.hxx>
#include <libupnpp/control/discovery.hxx>
#include <libupnpp/control/mediarenderer.hxx>
#include <libupnpp/control/mediaserver.hxx>
#include <libupnpp/control/renderingcontrol.hxx>

class UPnPSearchWorker : public QObject
{
    Q_OBJECT
public:
    UPnPSearchWorker(UPnPClient::CDSH server, QString searchString, int startIndex, int maxCount);

public slots:
    void process();

signals:
    void finished();
    void error(QString err);
    void searchDone(QString searchResultsJson);

protected:
  UPnPClient::CDSH server;
  QString searchString;
  int startIndex;
  int maxCount;
};

#endif // UPNPSEARCHWORKER_H
