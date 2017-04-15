#ifndef UPNPGETSERVERWORKER_H
#define UPNPGETSERVERWORKER_H

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

class UPnPGetServerWorker : public QObject
{
    Q_OBJECT
public:
    UPnPGetServerWorker(QString friendlyName);

public slots:
    void process();

signals:
    void finished();
    void error(QString err);
    void getServerDone(QString rendererJson);

private:
    QString friendlyName;
};

#endif // UPNPGETSERVERWORKER_H
