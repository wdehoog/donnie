/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
//import org.freedesktop.contextkit 1.0
//import org.nemomobile.connectivity 1.0
//import Nemo.DBus 2.0
import org.nemomobile.dbus 2.0

import "pages"
import "cover"
import "UPnP.js" as UPnP

import "components"

ApplicationWindow
{
    id: app
    property var discoveredRenderers : [];
    property var discoveredServers : [];
    property var currentBrowseStack : new UPnP.dataStructures.Stack();
    property var currentServer
    property var currentRenderer
    property var currentServerSearchCapabilities
    property bool useBuiltInPlayer: false;

    property var errorLog : new UPnP.dataStructures.Fifo();

    property int playerState: -1
    property int mprisStateMask: 0

    property alias last_playing_position: last_playing_position
    property alias last_playing_info: last_playing_info
    property alias last_browsing_info: last_browsing_info


    //property alias wlanDetectState: wlanDetectState
    //property alias wlanDetectType: wlanDetectType
    //property alias connectionHelper: connectionHelper
    //property alias dbusFlight: dbusFlight
    //property alias connman: connman

    //Component.onDestruction: app.last_playing_position.value = position
    //property alias last_playing_position: last_playing_position
    property int lastPlayingPosition: 0

    initialPage: mainPage

    allowedOrientations: defaultAllowedOrientations

    Browse {
        id: browsePage
    }

    //Search {
    //    id: searchPage
    //}

    MainPage {
        id: mainPage
    }

    PlayerPage {
        id: playerPage
    }

    RendererPage {
        id: rendererPage
    }

    cover: CoverPage {
        id: cover
    }

    function error(msg) {
        console.log("error: " + msg);
        errorLog.push(msg);
    }

    function showErrorDialog(text) { //, showCancelAll, cancelAll) {
        var dialog = pageStack.push(Qt.resolvedUrl("components/ErrorDialog.qml"),
                                    {errorMessageText: text}) //, showCancelAll: showCancelAll});
        /*if(showCancelAll) {
          dialog.accepted.connect(function() {
              if(dialog.cancelAll)
                cancelAll()
          })
        }*/
    }

    /**
     * can have a 4th param: rejectCallback
     */
    function showConfirmDialog(text, title, acceptCallback) {
        var dialog = pageStack.push (Qt.resolvedUrl("components/ConfirmDialog.qml"),
                                                   {confirmMessageText: text, titleText: title})
        if(acceptCallback !== null)
            dialog.accepted.connect(acceptCallback)
        if(arguments.length >= 4 && arguments[3] !== null)
            dialog.rejected.connect(arguments[3])
    }

    function hasCurrentServer() {
        return app.currentServer ? true : false;
    }

    function setCurrentServer(server) {
        app.currentServer = server;
        console.log("setCurrentServer to: "+ currentServer["friendlyName"]);
        var res = upnp.setCurrentServer(currentServer["friendlyName"], true);
        if(res) {
            try {
                var scapJson = upnp.getSearchCapabilitiesJson();
                console.log(scapJson);
                currentServerSearchCapabilities = JSON.parse(scapJson);
            } catch( err ) {
                app.error("Exception while getting Search Capabilities: " + err);
                app.error("json: " + scapJson);
            }
        } else {
            currentServerSearchCapabilities = {};
            error("Failed to set Current Server to: "+ currentServer["friendlyName"]);
        }
        return res;
    }

    function hasCurrentRenderer() {
        return app.currentRenderer ? true : false;
    }

    function setCurrentRenderer(renderer) {
        app.currentRenderer = renderer;

        if(renderer === undefined) {
            rendererPage.reset();
            return;
        }

        console.log("setCurrentRenderer to: "+ currentRenderer["friendlyName"]);
        var res = upnp.setCurrentRenderer(currentRenderer["friendlyName"], true);
        if(!res) {
            rendererPage.reset();
            error("Failed to set Current Renderer to: "+ currentRenderer["friendlyName"]);
        }
        return res;
    }

    function getPlayerPage() {
        if(useBuiltInPlayer)
            return playerPage;
        else
            return rendererPage;
    }

    function prev() {
        if(useBuiltInPlayer)
            playerPage.prev();
        else
            rendererPage.prev();
    }

    function pause() {
        if(useBuiltInPlayer)
            playerPage.pause();
        else
            rendererPage.pause();
    }

    function next() {
        if(useBuiltInPlayer)
            playerPage.next();
        else
            rendererPage.next();
    }

    function notifyTransportState(transportState) {
        // 1 playing, 2 paused, the rest inactive
        switch(transportState) {
        case 1:
        case 2:
            playerState = transportState;
            break;
        default:
            playerState = -1;
            break;
        }
        updateMprisState();
    }

    function updateMprisState() {
        // 0x01: play, 0x02: pause, 0x04: next, 0x08: previous
        // 0x0100: playing, 0x0200: paused
        var mask = 0;
        var player = getPlayerPage();
        /*if(player.canPlay)
            mask |= 0x01;
        if(player.canPause)
            mask |= 0x02;*/
        if(player.canNext)
            mask |= 0x04;
        if(player.canPrevious)
            mask |= 0x08;
        if(playerState == 1)
            mask |= 0x0103;
        else if(playerState == 2)
            mask |= 0x0203;
        //console.log("updateMprisState: 0x"+mask.toString(16));
        if(mask != mprisStateMask) {
            upnp.mprisSetStateMask(mask);
            mprisStateMask = mask;
        }
    }

    function updateMprisMetaData(meta) {
        var jsonString= JSON.stringify(meta);
        upnp.mprisSetMetaData(jsonString);
    }

    function saveLastBrowsingJSON() {
        var i
        var browseStackIds = []
        for(i=1;i<currentBrowseStack.length();i++)
            browseStackIds.push(currentBrowseStack.elements()[i].id)
        last_browsing_info.value = JSON.stringify(browseStackIds)
    }

    function saveLastPlayingJSON(currentTrack, trackListModel) {
        /*
          info.currentTrackId
          info.queueTrackIds[]
         */
        var i
        var lastPlayingInfo = {}
        lastPlayingInfo.currentTrackId = currentTrack.id
        lastPlayingInfo.queueTrackIds = []
        for(i=0;i<trackListModel.count;i++)
            lastPlayingInfo.queueTrackIds.push(trackListModel.get(i).id)
        last_playing_info.value = JSON.stringify(lastPlayingInfo)
    }

    //Component.onDestruction: { nothing happens
        //console.log("lastPlayingPosition:") //+lastPlayingPosition)
        //last_playing_position.value = lastPlayingPosition
        //last_playing_position.sync()
    //}


    /* Did not work
    ContextProperty {
        id: wlanDetectState
        key: "Internet.NetworkState"
        // "connected" or "disconnected"
        onValueChanged: console.log(key + "->" + value + "/" + typeof(value))
    }

    ContextProperty {
        id: wlanDetectType
        key: "Internet.NetworkType"
        onValueChanged: console.log(key + "->" + value + "/" + typeof(value))
    }*/

    /*// this seems to work
    property bool connectedToNetwork: false
    ConnectionHelper {
         id: connectionHelper
         onNetworkConnectivityEstablished: {
             connectedToNetwork = true
         }
         onNetworkConnectivityUnavailable: {
             connectedToNetwork = false
         }
    }*/

    /*DBusInterface {
        id : dbusFlight
        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/signal"
        iface: "com.nokia.mce.signal"

        // Signals
        signalsEnabled: true

        function radio_states_ind (state) {
          console.log(JSON.stringify( "MCE radio state= "+ state))
        }

        function display_status_ind (state) {
            console.log(JSON.stringify("MCE display state= " + state))
        }

    }*/

    // this seems to work
    property int connmanConnected: UPnP.NetworkState.Unknown
    onConnmanConnectedChanged: {
        mainPage.networkStateChange(connmanConnected)
    }

    DBusInterface {
             id: connman

             bus:DBus.SystemBus
             service: 'net.connman'
             iface: 'net.connman.Technology'
             path: '/net/connman/technology/wifi'
             signalsEnabled: true
             function propertyChanged (name,value) {
                 //console.log("WiFi changed name=%1, value=%2".arg(name).arg(value))
                 if(name === "Connected")
                     connmanConnected = value ? UPnP.NetworkState.Connected : UPnP.NetworkState.Disconnected
             }
             Component.onCompleted: {
                 // result. Connected|Name|Powered|Tethering|TetheringIdentifier|Type
                 //         true      "WiFi" true  false     "One"               "wifi"
                 connman.typedCall('GetProperties', [], function (result) {
                     console.log('Got properties: ' + result);
                     connmanConnected = result.Connected ? UPnP.NetworkState.Connected : UPnP.NetworkState.Disconnected
                 });
             }
    }

    ConfigurationValue {
            id: last_playing_position
            key: "/donnie/last_playing_position"
            defaultValue: 0
    }

    ConfigurationValue {
            id: last_browsing_info
            key: "/donnie/last_browsing_info"
            defaultValue: ""
    }

    ConfigurationValue {
            id: last_playing_info
            key: "/donnie/last_playing_info"
            defaultValue: ""
    }
}

