#ifndef UPNPGETMEDIAINFORUNNABLE_H
#define UPNPGETMEDIAINFORUNNABLE_H

#include <QObject>
#include <QRunnable>

#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

#include <libupnpp/upnpplib.hxx>
#include <libupnpp/control/mediarenderer.hxx>
#include <libupnpp/control/mediaserver.hxx>
#include <libupnpp/control/renderingcontrol.hxx>

#include "upnpbrowseworker.h"

class UPnPGetMediaInfoRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    UPnPGetMediaInfoRunnable(UPnPClient::AVTH avt) {
        this->avt = avt;
    }

signals:
    void mediaInfo(int error, QString mediaInfoJson);

public slots:
    void run() {
        int err;

        UPnPClient::AVTransport::MediaInfo info;
        if((err = avt->getMediaInfo(info)) != 0) {
            QString msg = QStringLiteral("UPnP::getMediaInfo failed with error  %1").arg(err);
            emit mediaInfo(err, msg);
            return;
        }

        QJsonObject mInfo;
        QJsonObject dirObj0, dirObj1;

        mInfo["nrtracks"] = QString::number(info.nrtracks);
        mInfo["mduration"] = QString::number(info.mduration);
        mInfo["cururi"] = QString::fromStdString(info.cururi);
        UPnPBrowseWorker::load(info.curmeta, dirObj0);
        mInfo["curmeta"] = dirObj0;
        mInfo["nexturi"] = QString::fromStdString(info.nexturi);
        UPnPBrowseWorker::load(info.nextmeta, dirObj1);
        mInfo["nextmeta"] = dirObj1;

        QJsonDocument doc(mInfo);
        emit mediaInfo(0, doc.toJson(QJsonDocument::Compact));

    }

protected:
  UPnPClient::AVTH avt;
};

#endif // UPNPGETMEDIAINFORUNNABLE_H
