#ifndef UPNPDISCOVERYWORKER_H
#define UPNPDISCOVERYWORKER_H

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

class UPnPDiscoveryWorker : public QObject
{
    Q_OBJECT
public:

public slots:
    void process();

signals:
    void finished();
    void error(QString err);
    void discoveryDone(QString devicesJson);

private:

};

#endif // UPNPDISCOVERYWORKER_H
