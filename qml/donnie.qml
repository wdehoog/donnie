/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
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

    function showErrorDialog(text) {
        var dialog = pageStack.push(Qt.resolvedUrl("ErrorDialog.qml"),
                                    {errorMessageText: text});
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
}

