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
#include <map>
#include "upnpbrowseworker.h"

#include <libupnpp/log.hxx>
#include <libupnpp/upnpputils.hxx>
#include <libupnpp/control/cdirectory.hxx>


UPnPBrowseWorker::UPnPBrowseWorker(UPnPClient::CDSH server, QString cid) {
    this->server = server;
    this->cid = cid;
    this->startIndex = -1;
}

UPnPBrowseWorker::UPnPBrowseWorker(UPnPClient::CDSH server, QString cid, int startIndex, int maxCount) {
    this->server = server;
    this->cid = cid;
    this->startIndex = startIndex;
    this->maxCount = maxCount;
}

void UPnPBrowseWorker::load(UPnPClient::UPnPDirObject obj, QJsonObject& parent) {

    parent["id"] = QString::fromStdString(obj.m_id);
    parent["pid"] = QString::fromStdString(obj.m_pid);
    parent["title"] = QString::fromStdString(obj.m_title);
    parent["didl"] = QString::fromStdString(obj.getdidl());

    QJsonObject properties;
    for (std::map<std::string,std::string>::const_iterator it =
                obj.m_props.begin();
            it != obj.m_props.end(); it++) {
        properties[QString::fromStdString(it->first)] = QString::fromStdString(it->second);
    }
    parent["properties"] = properties;

    QJsonArray resources;
    for (std::vector<UPnPClient::UPnPResource>::const_iterator it =
                obj.m_resources.begin();
         it != obj.m_resources.end(); it++) {
        QJsonObject resource;
        resource["Uri"] = QString::fromStdString(it->m_uri);
        QJsonObject attributes;
        for (std::map<std::string, std::string>::const_iterator it1 =
                    it->m_props.begin();
                it1 != it->m_props.end(); it1++) {
            attributes[QString::fromStdString(it1->first)] = QString::fromStdString(it1->second);
        }
        resource["attributes"] = attributes;
        resources.append(resource);
    }
    parent["resources"] = resources;
}

void UPnPBrowseWorker::process() {
    QJsonObject cdObject;
    int code;
    int total;
    int actualCount;

    UPnPClient::UPnPDirContent dirbuf;
    if(startIndex < 0)
        code = server->readDir(cid.toUtf8().constData(), dirbuf);
    else
        code = server->readDirSlice(cid.toUtf8().constData(), startIndex, maxCount, dirbuf, &actualCount, &total);
    if (code) {
        std::cerr << UPnPP::LibUPnP::errAsString("UPnPBrowseWorker", code) << std::endl;
        return;
    }

    std::cout << "Browse: got " << dirbuf.m_containers.size() <<
        " containers and " << dirbuf.m_items.size() << " items " << std::endl;

    QJsonArray containers;
    for (unsigned int i = 0; i < dirbuf.m_containers.size(); i++) {
        QJsonObject container;
        load(dirbuf.m_containers[i], container);
        containers.append(container);
    }
    cdObject["containers"] = containers;

    QJsonArray items;
    for (unsigned int i = 0; i < dirbuf.m_items.size(); i++) {
        QJsonObject item;
        load(dirbuf.m_items[i], item);
        items.append(item);
    }
    cdObject["items"] = items;

    if(startIndex<0)
        total = dirbuf.m_containers.size() + dirbuf.m_items.size();
    cdObject["totalCount"] = QString::number(total);

    QJsonDocument doc(cdObject);
    emit browseDone(doc.toJson(QJsonDocument::Compact));
    emit finished();
}
