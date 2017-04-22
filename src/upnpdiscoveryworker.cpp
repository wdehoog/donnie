/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <vector>
#include "upnpdiscoveryworker.h"

#include <libupnpp/log.hxx>
#include <libupnpp/upnpputils.hxx>
#include <libupnpp/control/cdirectory.hxx>

//UPnPDiscoveryWorker::UPnPDiscoveryWorker(UPnPClient::UPnPDeviceDirectory *superdir) {
//    this->superdir = superdir;
//}

void UPnPDiscoveryWorker::process() {
    QVariantMap rvm, cdvm;
    QJsonObject devicesObject;

    QJsonArray renderersArray;
    QJsonArray serversArray;

    std::vector<UPnPClient::UPnPDeviceDesc> devices;
    if (!UPnPClient::MediaRenderer::getDeviceDescs(devices) || devices.empty()) {
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
    devicesObject["renderers"] = renderersArray;

    std::vector<UPnPClient::UPnPDeviceDesc> servers;
    if (!UPnPClient::MediaServer::getDeviceDescs(servers) || servers.empty()) {
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
    devicesObject["servers"] = serversArray;

    QJsonDocument doc(devicesObject);
    emit discoveryDone(doc.toJson(QJsonDocument::Compact));
    emit finished();
}
