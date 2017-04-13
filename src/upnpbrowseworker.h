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

public slots:
    void process();

signals:
    void finished();
    void error(QString err);
    void browseDone(QString contentsJson);

protected:
  UPnPClient::CDSH server;
  QString cid;
};

#endif // UPNPDISCOVERYWORKER_H
