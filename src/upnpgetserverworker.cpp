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
