#ifndef UPNPGETMETADATARUNNABLE_H
#define UPNPGETMETADATARUNNABLE_H

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

class UPnPGetMetaDataRunnable : public QObject, public QRunnable
{
    Q_OBJECT
public:
    UPnPGetMetaDataRunnable(UPnPClient::CDSH server, QString id) {
        this->server = server;
        this->id = id;
    }

signals:
    void metaData(int error, QString metaDataJson);

public slots:
    void run() {
        int err;

        UPnPClient::UPnPDirContent dirBuf;
        if((err = server->getMetadata(id.toStdString(), dirBuf)) != 0) {
            QString msg = QStringLiteral("UPnP::getMetadata failed with error  %1").arg(err);
            emit metaData(err, msg);
            return;
        }

        QJsonObject mInfo;
        mInfo["id"] = id;

        QJsonArray containers;
        for (unsigned int i = 0; i < dirBuf.m_containers.size(); i++) {
            QJsonObject container;
            UPnPBrowseWorker::load(dirBuf.m_containers[i], container);
            containers.append(container);
        }
        mInfo["containers"] = containers;

        QJsonArray items;
        for (unsigned int i = 0; i < dirBuf.m_items.size(); i++) {
            QJsonObject item;
            UPnPBrowseWorker::load(dirBuf.m_items[i], item);
            items.append(item);
        }
        mInfo["items"] = items;

        QJsonDocument doc(mInfo);
        emit metaData(0, doc.toJson(QJsonDocument::Compact));

    }

protected:
  UPnPClient::CDSH server;
  QString id;
};

#endif // UPNPGETMETADATARUNNABLE_H
