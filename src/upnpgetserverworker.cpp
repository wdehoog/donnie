#include <vector>
#include "upnpgetserverworker.h"

#include <libupnpp/log.hxx>
#include <libupnpp/upnpputils.hxx>
#include <libupnpp/control/cdirectory.hxx>

void UPnPGetServerWorker::process() {
    QVariantMap rvm, cdvm;
    QJsonObject devicesObject;


    QJsonArray serversArray;

    std::vector<UPnPClient::UPnPDeviceDesc> servers;
    if (!UPnPClient::MediaServer::getDeviceDescs(servers, friendlyName.toStdString()) || servers.empty()) {
        std::cerr << "UPnPDiscoveryWorker: No Media Servers found." << std::endl;
    } else {
        for (std::vector<UPnPClient::UPnPDeviceDesc>::iterator it = servers.begin();
             it != servers.end(); it++) {
            QJsonObject server;
            server["deviceType"] = QString::fromStdString(it->deviceType);
            server["friendlyName"] = QString::fromStdString(it->friendlyName);
            server["UDN"] = QString::fromStdString(it->UDN);
            server["URLBase"] = QString::fromStdString(it->URLBase);
            server["manufacturer"] = QString::fromStdString(it->manufacturer);
            server["modelName"] = QString::fromStdString(it->modelName);
            serversArray.append(server);
        }
    }
    devicesObject["server"] = serversArray;

    QJsonDocument doc(devicesObject);
    emit getServerDone(doc.toJson(QJsonDocument::Compact));
    emit finished();
}

UPnPGetServerWorker::UPnPGetServerWorker(QString friendlyName) {
    this->friendlyName = friendlyName;
}
