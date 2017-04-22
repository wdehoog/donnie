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
