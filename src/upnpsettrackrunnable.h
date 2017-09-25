#ifndef UPNPSETTRACKRUNNABLE_H
#define UPNPSETTRACKRUNNABLE_H

#include <QObject>
#include <QRunnable>

#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

#include <libupnpp/upnpplib.hxx>
#include <libupnpp/control/mediarenderer.hxx>
#include <libupnpp/control/mediaserver.hxx>
#include <libupnpp/control/renderingcontrol.hxx>

class UPnPSetTrackRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    UPnPSetTrackRunnable(UPnPClient::AVTH avt, QString uri, QString didl) {
        this->avt = avt;
        this->uri = uri;
        this->didl = didl;
    }

signals:
    void trackSet(int status, QString uri);

public slots:
    void run() {
        int err = avt->setAVTransportURI(uri.toStdString(), didl.toStdString());
        emit trackSet(err, uri);
    }

protected:
    UPnPClient::AVTH avt;
    QString uri;
    QString didl;
};

#endif // UPNPSETTRACKRUNNABLE_H
