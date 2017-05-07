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

#ifndef UPNPBROWSEWORKER_H
#define UPNPBROWSEWORKER_H

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

class UPnPBrowseWorker : public QObject
{
    Q_OBJECT
public:
    UPnPBrowseWorker(UPnPClient::CDSH server, QString cid);
    UPnPBrowseWorker(UPnPClient::CDSH server, QString cid, int startIndex, int maxCount);
    static void load(UPnPClient::UPnPDirObject obj, QJsonObject& parent);

public slots:
    void process();

signals:
    void finished();
    void error(QString err);
    void browseDone(QString contentsJson);

protected:
  UPnPClient::CDSH server;
  QString cid;
  int startIndex;
  int maxCount;
};

#endif // UPNPBROWSEWORKER_H
