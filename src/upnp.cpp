/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


#include <QThread>
#include <QThreadPool>

#include <vector>
#include <set>

#include "upnp.h"
#include "upnpdiscoveryworker.h"
#include "upnpbrowseworker.h"
#include "upnpsearchworker.h"
#include "upnpgetrendererworker.h"
#include "upnpgetserverworker.h"
#include "upnpgettransportinforunnable.h"
#include "upnpgetmediainforunnable.h"
#include "upnpgetpositioninforunnable.h"
#include "upnpsettrackrunnable.h"
#include "upnpsetnexttrackrunnable.h"

#include <MprisPlayer>

#include <libupnpp/log.hxx>
#include <libupnpp/upnpputils.hxx>
#include <libupnpp/control/cdirectory.hxx>
#include <libupnpp/control/avtransport.hxx>


UPNP::UPNP(QObject *parent) :
    QObject(parent),
    mprisPlayer(new MprisPlayer(this))
{
    libUPnP = nullptr;
    superdir = nullptr;
    currentRenderer = nullptr;
    currentServer = nullptr;
    cavt = nullptr;

    mprisPlayer->setServiceName("donnie");
    mprisPlayer->setCanControl(true);
    connect(mprisPlayer, &MprisPlayer::playRequested, this, &UPNP::mprisPlay);
    connect(mprisPlayer, &MprisPlayer::pauseRequested, this, &UPNP::mprisPause);
    connect(mprisPlayer, &MprisPlayer::nextRequested, this, &UPNP::mprisNext);
    connect(mprisPlayer, &MprisPlayer::previousRequested, this, &UPNP::mprisPrevious);
}

void UPNP::init(int search_window) {

    if(!libUPnP || !libUPnP->ok()) {
        libUPnP = UPnPP::LibUPnP::getLibUPnP(false, 0, "wlan0"); //, "127.0.0.1");
        if (!libUPnP || !libUPnP->ok()) {
            if (libUPnP)
                std::cerr << libUPnP->errAsString("init", libUPnP->getInitError()) << std::endl;
            // try second time without specifying iface
            libUPnP = UPnPP::LibUPnP::getLibUPnP();
            if (!libUPnP || !libUPnP->ok()) {
                if (!libUPnP)
                    std::cerr << "init failed to create libUPnP 2nd try" << std::endl;
                else
                    std::cerr << libUPnP->errAsString("Error on init 2nd try: ", libUPnP->getInitError()) << std::endl;
            }
        }
        if (libUPnP && libUPnP->ok()) {
            libUPnP->setLogFileName("/home/nemo/.donnie.log", UPnPP::LibUPnP::LogLevelDebug);
    //        Logger::getTheLog("/home/nemo/.donnie.log")->setLogLevel(Logger::LLDEB1);
    //        if (Logger::getTheLog("stderr") == 0)
    //            std::cerr << "Can't initialize log" << std::endl;
        }
    }

    if(!superdir) {
        // default timeout seems too low: make configurable
        superdir = UPnPClient::UPnPDeviceDirectory::getTheDir(search_window);
        if(!superdir) {
            std::cerr << "UPNP::init Can't create UPnP discovery object" << std::endl;
        }
    }

}

/*void UPNP::search(int search_window) {
    if(!superdir)
        init(search_window);

    std::vector<UPnPClient::UPnPDeviceDesc> devices;
    if (!UPnPClient::MediaRenderer::getDeviceDescs(devices) || devices.empty()) {
        std::cerr << "UPNP::search No Media Renderers found." << std::endl;
    } else {
        for (std::vector<UPnPClient::UPnPDeviceDesc>::iterator it = devices.begin();
             it != devices.end(); it++) {
            UPnPClient::MRDH rdr = getRenderer(it->UDN, false);
            if(rdr) {
                std::cerr << "Renderer " << it->friendlyName << "(" << it->UDN
                     << ")." << std::endl;
            } else {
                std::cerr << "Renderer " << it->UDN
                     << " not found." << std::endl;
            }
        }
    }

}*/

/*QVariantList UPNP::getAdapters() {
    std::vector<std::string> adapters;
    QVariantList vl;

    if(UPnPP::getAdapterNames(adapters) == 0) {
        for (std::vector<std::string>::iterator it = adapters.begin();
             it != adapters.end(); it++) {
            //std::cerr << "Adapter " << (*it) << std::endl;
            vl.append(QString(it->c_str()));
        }
    }

    // UPnPP::getAdapterNames filters out all adapters with 127.0.0.x
    vl.append("lo");

    return vl;
}*/

/*QVariantMap UPNP::getRenderers(QString adapter) {
    QVariantMap vm;

    UPnPP::LibUPnP * libUPnP = UPnPP::LibUPnP::getLibUPnP(false, 0, adapter.toStdString());
    if (!libUPnP || !libUPnP->ok()) {
        if (libUPnP)
            std::cerr << libUPnP->errAsString("getRenderers", libUPnP->getInitError()) << std::endl;
    } else {
        std::vector<UPnPClient::UPnPDeviceDesc> devices;
        if (!UPnPClient::MediaRenderer::getDeviceDescs(devices) || devices.empty()) {
            std::cerr << "UPNP::getRenderers no Media Renderers found." << std::endl;
        } else {
            for (std::vector<UPnPClient::UPnPDeviceDesc>::iterator it = devices.begin();
                 it != devices.end(); it++) {
                vm.insert("deviceType", QString(it->deviceType.c_str()));
                vm.insert("friendlyName", QString(it->friendlyName.c_str()));
                vm.insert("UDN", QString(it->UDN.c_str()));
                vm.insert("URLBase", QString(it->URLBase.c_str()));
                vm.insert("manufacturer", QString(it->manufacturer.c_str()));
                vm.insert("modelName", QString(it->modelName.c_str()));
            }
        }
    }

    return vm;
}

QVariantMap UPNP::getContentDirectories(QString adapter) {
    QVariantMap vm;

    UPnPP::LibUPnP * libUPnP = UPnPP::LibUPnP::getLibUPnP(false, 0, adapter.toStdString());
    if (!libUPnP || !libUPnP->ok()) {
        if (libUPnP)
            std::cerr << libUPnP->errAsString("getContentDirectories", libUPnP->getInitError()) << std::endl;
    } else {
        std::vector<UPnPClient::CDSH> services;
        if (!UPnPClient::ContentDirectory::getServices(services) || services.empty()) {
            std::cerr << "UPNP::getContentDirectories no Content Directories found." << std::endl;
        } else {
            for (std::vector<UPnPClient::CDSH>::iterator it = services.begin();
                 it != services.end(); it++) {
                vm.insert("DeviceId", QString((*it)->getDeviceId().c_str()));
                vm.insert("FriendlyName", QString((*it)->getFriendlyName().c_str()));
                vm.insert("ServiceType", QString((*it)->getServiceType().c_str()));
                vm.insert("ActionURL", QString((*it)->getActionURL().c_str()));
                vm.insert("Manufacturer", QString((*it)->getManufacturer().c_str()));
                vm.insert("ModelName", QString((*it)->getModelName().c_str()));
            }
        }
    }

    return vm;

}*/

void UPNP::discover(int search_window) {
    if(!superdir)
        init(search_window);

    QThread* thread = new QThread;
    UPnPDiscoveryWorker * worker = new UPnPDiscoveryWorker();
    worker->moveToThread(thread);

    connect(worker, SIGNAL (error(QString)), this, SLOT (onError(QString)));
    connect(worker, SIGNAL (discoveryDone(QString)), this, SLOT (onDiscoveryDone(QString)));

    connect(thread, SIGNAL (started()), worker, SLOT (process()));
    connect(worker, SIGNAL (finished()), thread, SLOT (quit()));
    connect(worker, SIGNAL (finished()), worker, SLOT (deleteLater()));
    connect(thread, SIGNAL (finished()), thread, SLOT (deleteLater()));
    thread->start();

}

void UPNP::browse(QString cid) {
    if(currentServer == nullptr)
        return;

    QThread* thread = new QThread;
    UPnPBrowseWorker * worker = new UPnPBrowseWorker(currentServer, cid);
    worker->moveToThread(thread);

    connect(worker, SIGNAL (error(QString)), this, SLOT (onError(QString)));
    connect(worker, SIGNAL (browseDone(QString)), this, SLOT (onBrowseDone(QString)));

    connect(thread, SIGNAL (started()), worker, SLOT (process()));
    connect(worker, SIGNAL (finished()), thread, SLOT (quit()));
    connect(worker, SIGNAL (finished()), worker, SLOT (deleteLater()));
    connect(thread, SIGNAL (finished()), thread, SLOT (deleteLater()));
    thread->start();
}

void UPNP::browse(QString cid, int startIndex, int maxCount) {
    if(currentServer == nullptr)
        return;

    QThread* thread = new QThread;
    UPnPBrowseWorker * worker = new UPnPBrowseWorker(currentServer, cid, startIndex, maxCount);
    worker->moveToThread(thread);

    connect(worker, SIGNAL (error(QString)), this, SLOT (onError(QString)));
    connect(worker, SIGNAL (browseDone(QString)), this, SLOT (onBrowseDone(QString)));

    connect(thread, SIGNAL (started()), worker, SLOT (process()));
    connect(worker, SIGNAL (finished()), thread, SLOT (quit()));
    connect(worker, SIGNAL (finished()), worker, SLOT (deleteLater()));
    connect(thread, SIGNAL (finished()), thread, SLOT (deleteLater()));
    thread->start();
}

void UPNP::search(QString searchString, int startIndex, int count) {
    if(currentServer == nullptr)
        return;

    QThread* thread = new QThread;
    UPnPSearchWorker * worker = new UPnPSearchWorker(currentServer, searchString, startIndex, count);
    worker->moveToThread(thread);

    connect(worker, SIGNAL (error(QString)), this, SLOT (onError(QString)));
    connect(worker, SIGNAL (searchDone(QString)), this, SLOT (onSearchDone(QString)));

    connect(thread, SIGNAL (started()), worker, SLOT (process()));
    connect(worker, SIGNAL (finished()), thread, SLOT (quit()));
    connect(worker, SIGNAL (finished()), worker, SLOT (deleteLater()));
    connect(thread, SIGNAL (finished()), thread, SLOT (deleteLater()));
    thread->start();
}

QString UPNP::getPathJson(QString id) {
    UPnPClient::UPnPDirContent dirbuf;
    QString parentID;
    QString title;
    QJsonArray pathObject;
    QString searchString;

    if(currentServer == nullptr)
        return "";

    while(id.compare("-1") != 0) { // stop at root

        dirbuf.clear();
        searchString = QString("@id = \"%1\"").arg(id);
        int code = currentServer->search("0", searchString.toUtf8().constData(), dirbuf);
        if (code) {
            std::cerr << UPnPP::LibUPnP::errAsString("getPathJson", code) << std::endl;
            break;
        }
        if(dirbuf.m_containers.size() > 0) {
            parentID = QString::fromStdString(dirbuf.m_containers[0].m_pid);
            title = QString::fromStdString(dirbuf.m_containers[0].m_title);
        } else if(dirbuf.m_items.size() > 0) {
            parentID = QString::fromStdString(dirbuf.m_items[0].m_pid);
            title = QString::fromStdString(dirbuf.m_items[0].m_title);
        } else {
            //std::cerr << "getPathJson found nothing for " << id << std::endl;
            break;
        }

        QJsonObject part;
        part["id"] = id;
        part["pid"] = parentID;
        part["title"] = title;
        pathObject.append(part);

        id = parentID;
    }

    QJsonDocument doc(pathObject);
    return doc.toJson(QJsonDocument::Compact);
}

QString UPNP::getParentID(QString id) {
    UPnPClient::UPnPDirContent dirbuf;
    QString parentID;

    if(currentServer == nullptr)
        return "";

    // get item so we also get it's parent id
    QString searchString = QString("@id = \"%1\"").arg(id);
    int code = currentServer->search("0", searchString.toUtf8().constData(), dirbuf);
    if (code) {
        std::cerr << UPnPP::LibUPnP::errAsString("getParentID", code) << std::endl;
        return "";
    }

    std::cout << "getParentID 1: got " << dirbuf.m_containers.size() <<
        " containers and " << dirbuf.m_items.size() << " items " << std::endl;

    if(dirbuf.m_containers.size() > 0) {
        std::cout << "getParentID: C for " << id.toStdString() << " is "
                  << dirbuf.m_containers[0].m_pid << std::endl;
        parentID = QString::fromStdString(dirbuf.m_containers[0].m_pid);
    } else if(dirbuf.m_items.size() > 0) {
        std::cout << "getParentID: I for " << id.toStdString() << " is "
                  << dirbuf.m_containers[0].m_pid << std::endl;
        parentID = QString::fromStdString(dirbuf.m_items[0].m_pid);
    } else
        parentID =  ""; // no idea

    // now get the parent item so we can get the title
    // get item so we also get it's parent id
    searchString = QString("@id = \"%1\"").arg(parentID);
    code = currentServer->search("0", searchString.toUtf8().constData(), dirbuf);
    if (code) {
        std::cerr << UPnPP::LibUPnP::errAsString("getParentID", code) << std::endl;
        return parentID;
    }

    std::cout << "getParentID 2: got " << dirbuf.m_containers.size() <<
        " containers and " << dirbuf.m_items.size() << " items " << std::endl;

    // it must be a container
    QString title = "";
    for (unsigned int i = 0; i < dirbuf.m_containers.size(); i++) {
        if(id.compare(QString::fromStdString(dirbuf.m_containers[i].m_pid)) == 0) {
            title = QString::fromStdString(dirbuf.m_containers[i].m_title);
            break;
        }
    }
    // VISIT return Json
    return QString("%1,%2").arg(parentID, title);
}

QString UPNP::getSearchCapabilitiesJson() {
    if(!currentServer)
        return "[]";

    std::set<std::string> searchCapabilities;
    int code = currentServer->getSearchCapabilities(searchCapabilities);
    if (code) {
        std::cerr << UPnPP::LibUPnP::errAsString("UPNP::getSearchCapabilitiesJson", code) << std::endl;
        return "[]";
    }

    if(searchCapabilities.empty())
        return "[]";

    QJsonArray items;
    for(std::set<std::string>::const_iterator it = searchCapabilities.begin();
        it != searchCapabilities.end();
        it++) {
        items.append(QString::fromStdString(*it));
    }

    QJsonDocument doc(items);
    return doc.toJson(QJsonDocument::Compact);
}

void UPNP::getRendererJson(QString friendlyName, int search_window) {
    if(!superdir)
        init(search_window);

    QThread* thread = new QThread;
    UPnPGetRendererWorker * worker = new UPnPGetRendererWorker(friendlyName);
    worker->moveToThread(thread);

    connect(worker, SIGNAL (error(QString)), this, SLOT (onError(QString)));
    connect(worker, SIGNAL (getRendererDone(QString)), this, SLOT (onGetRendererDone(QString)));

    connect(thread, SIGNAL (started()), worker, SLOT (process()));
    connect(worker, SIGNAL (finished()), thread, SLOT (quit()));
    connect(worker, SIGNAL (finished()), worker, SLOT (deleteLater()));
    connect(thread, SIGNAL (finished()), thread, SLOT (deleteLater()));
    thread->start();
}

void UPNP::getServerJson(QString friendlyName, int search_window) {
    if(!superdir)
        init(search_window);

    QThread* thread = new QThread;
    UPnPGetServerWorker * worker = new UPnPGetServerWorker(friendlyName);
    worker->moveToThread(thread);

    connect(worker, SIGNAL (error(QString)), this, SLOT (onError(QString)));
    connect(worker, SIGNAL (getServerDone(QString)), this, SLOT (onGetServerDone(QString)));

    connect(thread, SIGNAL (started()), worker, SLOT (process()));
    connect(worker, SIGNAL (finished()), thread, SLOT (quit()));
    connect(worker, SIGNAL (finished()), worker, SLOT (deleteLater()));
    connect(thread, SIGNAL (finished()), thread, SLOT (deleteLater()));
    thread->start();
}
/*UPnPP::LibUPnP *UPNP::getLibUPnP()
{
    return libUPnP;
}*/

bool UPNP::setCurrentRenderer(QString name, bool isfriendlyname) {
    UPnPClient::MRDH newRenderer = getRenderer(name, isfriendlyname);

    if(newRenderer) {
        std::cerr << "cpp setCurrentRenderer to: " + name.toStdString() <<  std::endl;
        if(currentRenderer) {
            std::cerr << "  reset old renderer" <<  std::endl;
            currentRenderer.reset();
            //cavt.reset();
        }
        currentRenderer = newRenderer;
        //if(currentRenderer)
            // MediaRenderer has a weak_ptr to avt. since donnie does not use
            // a permanent reference to it the AVTransport migth be deleted causing
            // a segfault due to received upnp events. should not happen but it does.
            // so save a ref to keep the object alive.
            //cavt = currentRenderer->avt();
        return true;
    }
    std::cerr << "setCurrentRenderer: FAILED for" + name.toStdString() <<  std::endl;
    return false;
}

UPnPClient::MRDH UPNP::getRenderer(QString name, bool isfriendlyname) {
    UPnPClient::UPnPDeviceDesc ddesc;
    const std::string cname = name.toUtf8().constData();

    if (isfriendlyname) {
        if (superdir->getDevByFName(cname, ddesc)) {
            return UPnPClient::MRDH(new UPnPClient::MediaRenderer(ddesc));
        }
        std::cerr << "UPNP::getRenderer getDevByFname failed" << std::endl;
    } else {
        if (superdir->getDevByUDN(cname, ddesc)) {
            return UPnPClient::MRDH(new UPnPClient::MediaRenderer(ddesc));
        }
        std::cerr << "UPNP::getRenderer getDevByUDN failed" << std::endl;
    }
    return UPnPClient::MRDH();
}

bool UPNP::setCurrentServer(QString name, bool isfriendlyname) {
    UPnPClient::CDSH newServer = getServer(name, isfriendlyname);
    if(newServer) {
        if(currentServer)
            currentServer.reset();
        currentServer = newServer;
        return true;
    }
    return false;
}

UPnPClient::CDSH UPNP::getServer(QString name, bool isfriendlyname) {
    bool found = false;
    UPnPClient::UPnPDeviceDesc ddesc;
    const std::string cname = name.toUtf8().constData();

    if(!superdir)
        init();

    if (isfriendlyname) {
        if (!superdir->getDevByFName(cname, ddesc)) {
            std::cerr << "UPNP::getRenderer getDevByFname failed" << std::endl;
        } else
            found = true;
    } else {
        if (!superdir->getDevByUDN(cname, ddesc)) {
            std::cerr << "UPNP::getRenderer getDevByUDN failed" << std::endl;
        } else
            found = true;
    }

    if(found) {
        for (std::vector<UPnPClient::UPnPServiceDesc>::const_iterator it =
                ddesc.services.begin(); it != ddesc.services.end(); it++) {
            if (UPnPClient::ContentDirectory::isCDService(it->serviceType)) {
                return UPnPClient::CDSH(new UPnPClient::ContentDirectory(ddesc, *it));
            }
        }
    }

    return UPnPClient::CDSH();
}

void UPNP::onDiscoveryDone(QString devicesJson) {
    emit discoveryDone(devicesJson);
}

void UPNP::onBrowseDone(QString contentsJson) {
    emit browseDone(contentsJson);
}

void UPNP::onSearchDone(QString searchResultsJson) {
    emit searchDone(searchResultsJson);
}

void UPNP::onError(QString msg) {
    emit error(msg);
}

void UPNP::onGetRendererDone(QString rendererJson) {
    emit getRendererDone(rendererJson);
}

void UPNP::onGetServerDone(QString serverJson) {
    emit getServerDone(serverJson);
}

int UPNP::play() {
    if(!currentRenderer)
        return -1;

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::play: Device has no AVTransport service");
        return -1;
    }

    int err;
    if((err = avt->play())) {
        QString msg = QStringLiteral("UPNP::play: failed with error %1").arg(err);
        emit error(msg);
    }

    return err;
}

int UPNP::pause() {
    if(!currentRenderer)
        return -1;

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::pause: Device has no AVTransport service");
        return -1;
    }

    int err;
    if((err = avt->pause())) {
        QString msg = QStringLiteral("UPNP::pause: failed with error %1").arg(err);
        emit error(msg);
    }

    return err;
}

int UPNP::stop() {
    if(!currentRenderer)
        return -1;
    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::stop: Device has no AVTransport service");
        return -1;
    }

    int err;
    if((err = avt->stop())) {
        QString msg = QStringLiteral("UPNP::stop: failed with error %1").arg(err);
        emit error(msg);
    }

    return err;
}

int  UPNP::setTrack(QString uri, QString didl) {
    if(!currentRenderer)
        return -1;

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::setTrack: Device has no AVTransport service");
        return -1;
    }
    //std::cerr << didl.toStdString() <<  std::endl;

    int err;
    if((err = avt->setAVTransportURI(uri.toStdString(), didl.toStdString()))) {
        QString msg = QStringLiteral("UPNP::setTrack: failed with error %1").arg(err);
        emit error(msg);
    }

    return err;
}

int UPNP::setNextTrack(QString uri, QString didl) {
    if(!currentRenderer)
        return -1;
    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::setNextTrack: Device has no AVTransport service");
        return -1;
    }
    //std::cerr << didl.toStdString() <<  std::endl;

    int err;
    if((err = avt->setNextAVTransportURI(uri.toStdString(), didl.toStdString()))) {
        QString msg = QStringLiteral("UPNP::setNextTrack: failed with error %1").arg(err);
        emit error(msg);
    }

    return err;
}

int UPNP::setVolume(int volume) {
    if(!currentRenderer)
        return -1;

    UPnPClient::RDCH rdc = currentRenderer->rdc();
    if (!rdc) {
        emit error("UPNP::setVolume: Device has no RenderingControl service");
        return -1;
    }

    int err;
    if((err = rdc->setVolume(volume))) {
        QString msg = QStringLiteral("UPNP::setVolume: failed with error %1").arg(err);
        emit error(msg);
    }

    return err;
}

int UPNP::getVolume() {
    if(!currentRenderer)
        return -1;

    UPnPClient::RDCH rdc = currentRenderer->rdc();
    if (!rdc) {
        emit error("UPNP::getVolume: Device has no RenderingControl service");
        return -1;
    }

    return rdc->getVolume();
}

bool UPNP::getMute() {
    if(!currentRenderer)
        return -1;

    UPnPClient::RDCH rdc = currentRenderer->rdc();
    if (!rdc) {
        emit error("UPNP::getMute: Device has no RenderingControl service");
        return -1;
    }

    return rdc->getMute();
}

int UPNP::setMute(bool mute) {
    if(!currentRenderer)
        return -1;

    UPnPClient::RDCH rdc = currentRenderer->rdc();
    if (!rdc) {
        emit error("UPNP::setMute: Device has no RenderingControl service");
        return -1;
    }

    int err;
    if((err = rdc->setMute(mute))) {
        QString msg = QStringLiteral("UPNP::setMute: failed with error %1").arg(err);
        emit error(msg);
    }
    return err;
}

int UPNP::seek(int seconds) {
    if(!currentRenderer)
        return -1;

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::seeek: Device has no AVTransport service");
        return -2;
    }

    return avt->seek(UPnPClient::AVTransport::SEEK_REL_TIME, seconds);
}

void UPNP::mprisPlay() {
    emit mprisControl("Play");
}

void UPNP::mprisPause() {
    emit mprisControl("Pause");
}

void UPNP::mprisNext() {
    emit mprisControl("Next");
}

void UPNP::mprisPrevious() {
    emit mprisControl("Previous");
}

void UPNP::mprisSetStateMask(unsigned int mask) {
    mprisPlayer->setCanPlay(mask & 0x01);
    mprisPlayer->setCanPause(mask & 0x02);
    mprisPlayer->setCanGoNext(mask & 0x04);
    mprisPlayer->setCanGoPrevious(mask & 0x08);
    if(mask & 0x0100)
        mprisPlayer->setPlaybackStatus(Mpris::Playing);
    else if(mask & 0x0200)
        mprisPlayer->setPlaybackStatus(Mpris::Paused);
    else
        mprisPlayer->setPlaybackStatus(Mpris::Stopped);
}

void UPNP::mprisSetMetaData(QString metaDataJson) {
    QJsonDocument doc = QJsonDocument::fromJson(metaDataJson.toUtf8());
    if(doc.isNull())
        return;
    if(!doc.isObject())
        return;
    QJsonObject obj = doc.object();
    QVariantMap map;

    QString s = obj["Artist"].toString();
    if(s.length()>0)
        map["xesam:artist"] = s ;

    s = obj["Title"].toString();
    if(s.length()>0)
        map["xesam:title"] = s;

    obj["Album"].toString();
    if(s.length()>0)
        map["xesam:album"] = s;

    s = obj["Length"].toString();
    if(s.length()>0)
        map["mpris:length"] = s;

    s = obj["ArtUrl"].toString();
    if(s.length()>0)
        map["mpris:artUrl"] = s;

    s = obj["TrackNumber"].toString();
    if(s.length()>0)
        map["xesam:trackNumber"] = s;

    mprisPlayer->setMetadata(map);
}

QString UPNP::getTransportInfoJson() {
    if(!currentRenderer) {
        emit error("UPNP::getTransportInfoJson: No Current Renderer");
        return "";
    }

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::getTransportInfoJson: Device has no AVTransport service");
        return "";
    }

    int err;
    UPnPClient::AVTransport::TransportInfo tinfo;
    if ((err = avt->getTransportInfo(tinfo)) != 0) {
        QString msg = QStringLiteral("UPNP::getTransportInfo: failed with error %1").arg(err);
        emit error(msg);
        return "";
    }

    QJsonObject transportInfo;

    switch(tinfo.tpstate) {
    case UPnPClient::AVTransport::Unknown:
        transportInfo["tpstate"] = "Unknown";
        break;
    case UPnPClient::AVTransport::Stopped:
        transportInfo["tpstate"] = "Stopped";
        break;
    case UPnPClient::AVTransport::Playing:
        transportInfo["tpstate"] = "Playing";
        break;
    case UPnPClient::AVTransport::Transitioning:
        transportInfo["tpstate"] = "Transitioning";
        break;
    case UPnPClient::AVTransport::PausedPlayback:
        transportInfo["tpstate"] = "PausedPlayback";
        break;
    case UPnPClient::AVTransport::PausedRecording:
        transportInfo["tpstate"] = "PausedRecording";
        break;
    case UPnPClient::AVTransport::Recording:
        transportInfo["tpstate"] = "Recording";
        break;
    case UPnPClient::AVTransport::NoMediaPresent:
        transportInfo["tpstate"] = "NoMediaPresent";
        break;
    }

    switch(tinfo.tpstatus) {
    case UPnPClient::AVTransport::TPS_Unknown:
        transportInfo["tpstatus"] = "Unknown";
        break;
    case UPnPClient::AVTransport::TPS_Ok:
        transportInfo["tpstatus"] = "OK";
        break;
    case UPnPClient::AVTransport::TPS_Error:
        transportInfo["tpstatus"] = "Error";
        break;
    }

    transportInfo["curspeed"] = QString::number(tinfo.curspeed);

    QJsonDocument doc(transportInfo);
    return doc.toJson(QJsonDocument::Compact);
}

QString UPNP::getPositionInfoJson() {
    if(!currentRenderer) {
        emit error("UPNP::getPositionInfoJson: No Current Renderer");
        return "";
    }

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::getPositionInfoJson: Device has no AVTransport service");
        return "";
    }

    UPnPClient::AVTransport::PositionInfo info;
    int err;
    if((err = avt->getPositionInfo(info)) != 0) {
        QString msg = QStringLiteral("getPositionInfo failed with error  %1").arg(err);
        emit error(msg);
        //if (m_errcnt++ > 4) {
        //    emit connectionLost();
        //}
        return "";
    }
    //m_errcnt = 0;

    QJsonObject positionInfo;

    positionInfo["trackuri"] = QString::fromStdString(info.trackuri);
    positionInfo["trackduration"] = QString::number(info.trackduration);
    positionInfo["reltime"] = QString::number(info.reltime);
    positionInfo["abstime"] = QString::number(info.abstime);
    positionInfo["relcount"] = QString::number(info.relcount);
    positionInfo["abscount"] = QString::number(info.abscount);

    QJsonDocument doc(positionInfo);
    return doc.toJson(QJsonDocument::Compact);
}

QString UPNP::getMediaInfoJson() {
    if(!currentRenderer) {
        emit error("UPNP::getMediaInfoJson: No Current Renderer");
        return "";
    }

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::getMediaInfoJson: Device has no AVTransport service");
        return "";
    }

    UPnPClient::AVTransport::MediaInfo info;
    int err;
    if((err = avt->getMediaInfo(info)) != 0) {
        QString msg = QStringLiteral("getMediaInfo failed with error  %1").arg(err);
        emit error(msg);
        //if (m_errcnt++ > 4) {
        //    emit connectionLost();
        //}
        return "";
    }
    //m_errcnt = 0;

    QJsonObject mediaInfo;
    QJsonObject dirObj0, dirObj1;

    mediaInfo["nrtracks"] = QString::number(info.nrtracks);
    mediaInfo["mduration"] = QString::number(info.mduration);
    mediaInfo["cururi"] = QString::fromStdString(info.cururi);
    UPnPBrowseWorker::load(info.curmeta, dirObj0);
    mediaInfo["curmeta"] = dirObj0;
    mediaInfo["nexturi"] = QString::fromStdString(info.nexturi);
    UPnPBrowseWorker::load(info.nextmeta, dirObj1);
    mediaInfo["nextmeta"] = dirObj1;

    QJsonDocument doc(mediaInfo);
    return doc.toJson(QJsonDocument::Compact);
}

void UPNP::getTransportInfoJsonAsync() {
    if(!currentRenderer) {
        emit error("UPNP::getTransportInfoJsonAsync: No Current Renderer");
        return;
    }

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::getTransportInfoJsonAsync: Device has no AVTransport service");
        return;
    }

    UPnPGetTransportRunnable * tr = new UPnPGetTransportRunnable(avt);
    tr->setAutoDelete(true);

    connect(tr, SIGNAL (transportInfo(unsigned int, QString)), this, SLOT (onTransportInfo(unsigned int, QString)));

    QThreadPool::globalInstance()->start(tr);
}

void UPNP::onTransportInfo(unsigned int error, QString transportInfoJson) {
    emit transportInfo(error, transportInfoJson);
}

void UPNP::getMediaInfoJsonAsync() {
    if(!currentRenderer) {
        emit error("UPNP::getMediaInfoJsonAsync: No Current Renderer");
        return;
    }

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::getMediaInfoJsonAsync: Device has no AVTransport service");
        return;
    }

    UPnPGetMediaInfoRunnable * tr = new UPnPGetMediaInfoRunnable(avt);
    tr->setAutoDelete(true);

    connect(tr, SIGNAL (mediaInfo(unsigned int, QString)), this, SLOT (onMediaInfo(unsigned int, QString)));

    QThreadPool::globalInstance()->start(tr);
}

void UPNP::onMediaInfo(unsigned int error, QString mediaInfoJson) {
    emit mediaInfo(error, mediaInfoJson);
}

void UPNP::getPositionInfoJsonAsync() {
    if(!currentRenderer) {
        emit error("UPNP::getPositionInfoJsonAsync: No Current Renderer");
        return;
    }

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::getPositionInfoJsonAsync: Device has no AVTransport service");
        return;
    }

    UPnPGetPositionRunnable * tr = new UPnPGetPositionRunnable(avt);
    tr->setAutoDelete(true);

    connect(tr, SIGNAL (positionInfo(unsigned int, QString)), this, SLOT (onPositionInfo(unsigned int, QString)));

    QThreadPool::globalInstance()->start(tr);
}

void UPNP::onPositionInfo(unsigned int error, QString positionInfoJson) {
    emit positionInfo(error, positionInfoJson);
}

void UPNP::setTrackAsync(QString uri, QString didl) {
    if(!currentRenderer) {
        emit error("UPNP::setTrackAsync: No Current Renderer");
        return;
    }

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::setTrackAsync: Device has no AVTransport service");
        return;
    }

    UPnPSetTrackRunnable * tr = new UPnPSetTrackRunnable(avt, uri, didl);
    tr->setAutoDelete(true);

    connect(tr, SIGNAL (trackSet(unsigned int, QString)), this, SLOT (onTrackSet(unsigned int, QString)));

    QThreadPool::globalInstance()->start(tr);
}

void UPNP::onTrackSet(unsigned int error, QString uri) {
    emit trackSet(error, uri);
}

void UPNP::setNextTrackAsync(QString uri, QString didl) {
    if(!currentRenderer) {
        emit error("UPNP::setNextTrackAsync: No Current Renderer");
        return;
    }

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::setNextTrackAsync: Device has no AVTransport service");
        return;
    }

    UPnPSetNextTrackRunnable * tr = new UPnPSetNextTrackRunnable(avt, uri, didl);
    tr->setAutoDelete(true);

    connect(tr, SIGNAL (nextTrackSet(unsigned int, QString)), this, SLOT (onNextTrackSet(unsigned int, QString)));

    QThreadPool::globalInstance()->start(tr);
}

void UPNP::onNextTrackSet(unsigned int error, QString uri) {
    emit nextTrackSet(error, uri);
}

