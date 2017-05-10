/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


#include <vector>
#include <map>
#include "upnpbrowseworker.h"
#include "upnpsearchworker.h"

#include <libupnpp/log.hxx>
#include <libupnpp/upnpputils.hxx>
#include <libupnpp/control/cdirectory.hxx>


UPnPSearchWorker::UPnPSearchWorker(UPnPClient::CDSH server, QString searchString, int startIndex, int maxCount) {
    this->server = server;
    this->searchString = searchString;
    this->startIndex = startIndex;
    this->maxCount = maxCount;
}


void UPnPSearchWorker::process() {
    QJsonObject cdObject;
    int total;
    int actualCount;

    UPnPClient::UPnPDirContent dirbuf;
    std::string cid("0");
    //int code = server->search(cid, searchString.toUtf8().constData(), dirbuf);
    int code = server->searchSlice(cid, searchString.toUtf8().constData(), startIndex, maxCount, dirbuf, &actualCount, &total);
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
