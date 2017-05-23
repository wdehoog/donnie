#ifndef UPNPGETTRANSPORTINFORUNNABLE_H
#define UPNPGETTRANSPORTINFORUNNABLE_H

#include <QObject>
#include <QRunnable>

#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

#include <libupnpp/upnpplib.hxx>
#include <libupnpp/control/mediarenderer.hxx>
#include <libupnpp/control/mediaserver.hxx>
#include <libupnpp/control/renderingcontrol.hxx>

class UPnPGetTransportRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    UPnPGetTransportRunnable(UPnPClient::AVTH avt) {
        this->avt = avt;
    }

signals:
    void error(QString err);
    void transportInfo(QString transportInfoJson);

public slots:
    void run() {
        int err;
        UPnPClient::AVTransport::TransportInfo tinfo;
        if ((err = avt->getTransportInfo(tinfo)) != 0) {
            QString msg = QStringLiteral("UPNP::getTransportInfo: failed with error %1").arg(err);
            emit error(msg);
            return;
        }

        QJsonObject tInfo;

        switch(tinfo.tpstate) {
        case UPnPClient::AVTransport::Unknown:
            tInfo["tpstate"] = "Unknown";
            break;
        case UPnPClient::AVTransport::Stopped:
            tInfo["tpstate"] = "Stopped";
            break;
        case UPnPClient::AVTransport::Playing:
            tInfo["tpstate"] = "Playing";
            break;
        case UPnPClient::AVTransport::Transitioning:
            tInfo["tpstate"] = "Transitioning";
            break;
        case UPnPClient::AVTransport::PausedPlayback:
            tInfo["tpstate"] = "PausedPlayback";
            break;
        case UPnPClient::AVTransport::PausedRecording:
            tInfo["tpstate"] = "PausedRecording";
            break;
        case UPnPClient::AVTransport::Recording:
            tInfo["tpstate"] = "Recording";
            break;
        case UPnPClient::AVTransport::NoMediaPresent:
            tInfo["tpstate"] = "NoMediaPresent";
            break;
        }

        switch(tinfo.tpstatus) {
        case UPnPClient::AVTransport::TPS_Unknown:
            tInfo["tpstatus"] = "Unknown";
            break;
        case UPnPClient::AVTransport::TPS_Ok:
            tInfo["tpstatus"] = "OK";
            break;
        case UPnPClient::AVTransport::TPS_Error:
            tInfo["tpstatus"] = "Error";
            break;
        }

        tInfo["curspeed"] = QString::number(tinfo.curspeed);

        QJsonDocument doc(tInfo);
        emit transportInfo(doc.toJson(QJsonDocument::Compact));

    }

protected:
  UPnPClient::AVTH avt;
};

#endif // UPNPGETTRANSPORTINFORUNNABLE_H
