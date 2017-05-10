/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


#ifndef UPNPGETRENDERERWORKER_H
#define UPNPGETRENDERERWORKER_H

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

class UPnPGetRendererWorker : public QObject
{
    Q_OBJECT
public:
    UPnPGetRendererWorker(QString friendlyName);

public slots:
    void process();

signals:
    void finished();
    void error(QString err);
    void getRendererDone(QString rendererJson);

private:
    QString friendlyName;
};

#endif // UPNPGETRENDERERWORKER_H
