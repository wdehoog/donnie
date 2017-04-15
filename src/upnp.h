#ifndef P_UPNP_H
#define P_UPNP_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

#include <string>

#include <libupnpp/upnpplib.hxx>
#include <libupnpp/log.hxx>
#include <libupnpp/control/cdirectory.hxx>
#include <libupnpp/control/discovery.hxx>
#include <libupnpp/control/mediarenderer.hxx>
#include <libupnpp/control/renderingcontrol.hxx>


class UPNP : public QObject
{
    Q_OBJECT
public:
    explicit UPNP(QObject *parent = 0);

    Q_INVOKABLE void init(int search_window = 10);
    //Q_INVOKABLE void search(int search_window = 10);
    //Q_INVOKABLE QVariantList getAdapters();
    //Q_INVOKABLE QVariantMap getRenderers(QString adapter);
    //Q_INVOKABLE QVariantMap getContentDirectories(QString adapter);

    Q_INVOKABLE void discover(int search_window = 10);
    Q_INVOKABLE void browse(QString cid);

    Q_INVOKABLE void getRendererJson(QString friendlyName, int search_window = 10);
    Q_INVOKABLE void getServerJson(QString friendlyName, int search_window = 10);

    //UPnPP::LibUPnP * getLibUPnP();

    Q_INVOKABLE bool setCurrentRenderer(QString name, bool isfriendlyname);
    Q_INVOKABLE bool setCurrentServer(QString name, bool isfriendlyname);

    UPnPClient::MRDH getRenderer(QString name, bool isfriendlyname);
    UPnPClient::CDSH getServer(QString name, bool isfriendlyname);

    // for renderer
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setVolume(int volume);
    Q_INVOKABLE int getVolume();
    Q_INVOKABLE bool getMute();
    Q_INVOKABLE int setMute(bool mute);
    Q_INVOKABLE void setTrack(QString uri, QString didl);
    Q_INVOKABLE void setNextTrack(QString uri, QString didl);
    Q_INVOKABLE QString getTransportInfoJson();
    Q_INVOKABLE QString getPositionInfoJson();
    Q_INVOKABLE int seek(int seconds);

signals:
    void getRendererDone(QString rendererJson);
    void getServerDone(QString serverJson);
    void discoveryDone(QString devicesJson);
    void browseDone(QString contentsJson);
    void error(QString msg);

public slots:
    void onGetRendererDone(QString rendererJson);
    void onGetServerDone(QString serverJson);
    void onDiscoveryDone(QString devicesJson);
    void onBrowseDone(QString contentsJson);
    void onError(QString msg);

protected:
    UPnPP::LibUPnP * libUPnP;
    UPnPClient::UPnPDeviceDirectory *superdir;
    UPnPClient::MRDH currentRenderer;
    UPnPClient::CDSH currentServer;
};

#endif // P_UPNP_H
