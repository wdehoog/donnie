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
#include "upnpsearchworker.h"

#include <libupnpp/log.hxx>
#include <libupnpp/upnpputils.hxx>
#include <libupnpp/control/cdirectory.hxx>


UPnPSearchWorker::UPnPSearchWorker(UPnPClient::CDSH server, QString searchString, int startIndex, int count) {
    this->server = server;
    this->searchString = searchString;
    this->startIndex = startIndex;
    this->count = count;
}


void UPnPSearchWorker::process() {
    QJsonObject cdObject;
    int total;
    int actualCount;

    UPnPClient::UPnPDirContent dirbuf;
    std::string cid("0");
    //int code = server->search(cid, searchString.toUtf8().constData(), dirbuf);
    int code = server->searchSlice(cid, searchString.toUtf8().constData(), startIndex, count, dirbuf, &actualCount, &total);
    if (code) {
        std::cerr << UPnPP::LibUPnP::errAsString("UPnPSearchWorker", code) << std::endl;
        return;
    }

    std::cout << "Search: got " << dirbuf.m_containers.size() <<
        " containers and " << dirbuf.m_items.size() << " items " << std::endl;

    QJsonArray containers;
    for (unsigned int i = 0; i < dirbuf.m_containers.size(); i++) {
        QJsonObject container;
        UPnPBrowseWorker::load(dirbuf.m_containers[i], container);
        containers.append(container);
    }
    cdObject["containers"] = containers;

    QJsonArray items;
    for (unsigned int i = 0; i < dirbuf.m_items.size(); i++) {
        QJsonObject item;
        UPnPBrowseWorker::load(dirbuf.m_items[i], item);
        items.append(item);
    }
    cdObject["items"] = items;

    cdObject["totalCount"] = QString::number(total);

    QJsonDocument doc(cdObject);
    emit searchDone(doc.toJson(QJsonDocument::Compact));
    emit finished();
}
