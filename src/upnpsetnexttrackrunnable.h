#ifndef UPNPSETNEXTTRACKRUNNABLE_H
#define UPNPSETNEXTTRACKRUNNABLE_H

#include <QObject>
#include <QRunnable>

#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

#include <libupnpp/upnpplib.hxx>
#include <libupnpp/control/mediarenderer.hxx>
#include <libupnpp/control/mediaserver.hxx>
#include <libupnpp/control/renderingcontrol.hxx>

class UPnPSetNextTrackRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    UPnPSetNextTrackRunnable(UPnPClient::AVTH avt, QString uri, QString didl) {
        this->avt = avt;
        this->uri = uri;
        this->didl = didl;
    }

signals:
    void nextTrackSet(int status, QString uri);

public slots:
    void run() {
        int err = avt->setNextAVTransportURI(uri.toStdString(), didl.toStdString());
        emit nextTrackSet(err, uri);
    }

protected:
    UPnPClient::AVTH avt;
    QString uri;
    QString didl;
};

#endif // UPNPSETTRACKRUNNABLE_H
