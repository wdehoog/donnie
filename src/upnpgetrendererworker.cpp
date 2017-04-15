#include <vector>
#include "upnpgetrendererworker.h"

#include <libupnpp/log.hxx>
#include <libupnpp/upnpputils.hxx>
#include <libupnpp/control/cdirectory.hxx>

void UPnPGetRendererWorker::process() {
    QVariantMap rvm, cdvm;
    QJsonObject devicesObject;

    QJsonArray renderersArray;

    std::vector<UPnPClient::UPnPDeviceDesc> devices;
    if (!UPnPClient::MediaRenderer::getDeviceDescs(devices, friendlyName.toStdString()) || devices.empty()) {
        std::cerr << "UPnPDiscoveryWorker: No Media Renderers found." << std::endl;
    } else {
        for (std::vector<UPnPClient::UPnPDeviceDesc>::iterator it = devices.begin();
             it != devices.end(); it++) {
            QJsonObject renderer;
            renderer["deviceType"] = QString::fromStdString(it->deviceType);
            renderer["friendlyName"] = QString::fromStdString(it->friendlyName);
            renderer["UDN"] = QString::fromStdString(it->UDN);
            renderer["URLBase"] = QString::fromStdString(it->URLBase);
            renderer["manufacturer"] = QString::fromStdString(it->manufacturer);
            renderer["modelName"] = QString::fromStdString(it->modelName);
            renderersArray.append(renderer);
        }
    }
    devicesObject["renderer"] = renderersArray;

    QJsonDocument doc(devicesObject);
    emit getRendererDone(doc.toJson(QJsonDocument::Compact));
    emit finished();
}

UPnPGetRendererWorker::UPnPGetRendererWorker(QString friendlyName) {
    this->friendlyName = friendlyName;
}
