#include <QThread>

#include <vector>

#include "upnp.h"
#include "upnpdiscoveryworker.h"
#include "upnpbrowseworker.h"

#include <libupnpp/log.hxx>
#include <libupnpp/upnpputils.hxx>
#include <libupnpp/control/cdirectory.hxx>
#include <libupnpp/control/avtransport.hxx>


UPNP::UPNP(QObject *parent) : QObject(parent)
{
    libUPnP = nullptr;
    superdir = nullptr;
    currentRenderer = nullptr;
    currentServer = nullptr;
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
                if (libUPnP)
                    std::cerr << libUPnP->errAsString("init 2nd try", libUPnP->getInitError()) << std::endl;
            }
        }
    }
    if (libUPnP && libUPnP->ok()) {
        libUPnP->setLogLevel(UPnPP::LibUPnP::LogLevelDebug);
        if (Logger::getTheLog("/tmp/donnie.log") == 0) {
            std::cerr << "Can't initialize log" << std::endl;
        } else
            Logger::getTheLog("/tmp/donnie.log")->setLogLevel(Logger::LLDEB1);
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

/*UPnPP::LibUPnP *UPNP::getLibUPnP()
{
    return libUPnP;
}*/

bool UPNP::setCurrentRenderer(QString name, bool isfriendlyname) {
    UPnPClient::MRDH newRenderer = getRenderer(name, isfriendlyname);
    if(newRenderer) {
        if(currentRenderer) {
            currentRenderer.reset();
            //delete avtPlayer;
        }
        currentRenderer = newRenderer;
        //avtPlayer = new AVTPlayer(currentRenderer->avt());
        return true;
    }
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

void UPNP::onError(QString msg) {
    emit error(msg);
}

void UPNP::play() {
    if(!currentRenderer)
        return;
    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::play: Device has no AVTransport service");
        return;
    }

    avt->play();
}

void UPNP::pause() {
    if(!currentRenderer)
        return;

    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::pause: Device has no AVTransport service");
        return;
    }

    avt->pause();
}

void UPNP::stop() {
    if(!currentRenderer)
        return;
    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::stop: Device has no AVTransport service");
        return;
    }

    avt->stop();
}

void UPNP::setTrack(QString uri, QString didl) {
    if(!currentRenderer)
        return;
    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::setTrack: Device has no AVTransport service");
        return;
    }
    std::cerr << didl.toStdString() <<  std::endl;
    avt->setAVTransportURI(uri.toStdString(), didl.toStdString());
}

void UPNP::setNextTrack(QString uri, QString didl) {
    if(!currentRenderer)
        return;
    UPnPClient::AVTH avt = currentRenderer->avt();
    if (!avt) {
        emit error("UPNP::setNextTrack: Device has no AVTransport service");
        return;
    }
    std::cerr << didl.toStdString() <<  std::endl;
    avt->setNextAVTransportURI(uri.toStdString(), didl.toStdString());
}

void UPNP::setVolume(int volume) {
    if(!currentRenderer)
        return;

    UPnPClient::RDCH rdc = currentRenderer->rdc();
    if (!rdc) {
        emit error("UPNP::setVolume: Device has no RenderingControl service");
        return;
    }

    int err;
    if((err = rdc->setVolume(volume))) {
        QString msg = QStringLiteral("UPNP::setVolume: failed with error %1").arg(err);
        emit error("Error setting volume: ");
    }
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


