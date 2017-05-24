#ifndef UPNPGETPOSITIONINFORUNNABLE_H
#define UPNPGETPOSITIONINFORUNNABLE_H

#include <QObject>
#include <QRunnable>

#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>

#include <libupnpp/upnpplib.hxx>
#include <libupnpp/control/mediarenderer.hxx>
#include <libupnpp/control/mediaserver.hxx>
#include <libupnpp/control/renderingcontrol.hxx>

class UPnPGetPositionRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    UPnPGetPositionRunnable(UPnPClient::AVTH avt) {
        this->avt = avt;
    }

signals:
    void error(QString err);
    void positionInfo(QString positionInfoJson);

public slots:
    void run() {
        int err;
        UPnPClient::AVTransport::PositionInfo info;
        if((err = avt->getPositionInfo(info)) != 0) {
            QString msg = QStringLiteral("getPositionInfo failed with error  %1").arg(err);
            emit error(msg);
            return ;
        }

        QJsonObject pInfo;

        pInfo["trackuri"] = QString::fromStdString(info.trackuri);
        pInfo["trackduration"] = QString::number(info.trackduration);
        pInfo["reltime"] = QString::number(info.reltime);
        pInfo["abstime"] = QString::number(info.abstime);
        pInfo["relcount"] = QString::number(info.relcount);
        pInfo["abscount"] = QString::number(info.abscount);

        QJsonDocument doc(pInfo);
        emit positionInfo(doc.toJson(QJsonDocument::Compact));
    }

protected:
  UPnPClient::AVTH avt;
};

#endif // UPNPGETPOSITIONINFORUNNABLE_H
