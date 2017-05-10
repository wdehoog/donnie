/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
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
