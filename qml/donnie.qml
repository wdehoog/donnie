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

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import "pages"
import "cover"
import "UPnP.js" as UPnP

ApplicationWindow
{
    id: app
    property var discoveredRenderers : [];
    property var discoveredServers : [];
    property var currentBrowseStack : new UPnP.dataStructures.Stack();
    property var currentServer
    property var currentRenderer

    property bool useBuiltInPlayer: false;

    property var errorLog : new UPnP.dataStructures.Fifo();

    property int playerState: -1
    property int mprisStateMask: 0

    initialPage: Component { MainPage { } }

    allowedOrientations: defaultAllowedOrientations

    Browse {
        id: browsePage
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
        errorLog.push(msg);
    }

    function hasCurrentServer() {
        return app.currentServer ? true : false;
    }

    function setCurrentServer(server) {
        app.currentServer = server;
        console.log("setCurrentServer to: "+ currentServer["friendlyName"]);
        return upnp.setCurrentServer(currentServer["friendlyName"], true);
    }

    function hasCurrentRenderer() {
        return app.currentRenderer ? true : false;
    }

    function setCurrentRenderer(renderer) {
        app.currentRenderer = renderer;
        console.log("setCurrentRenderer to: "+ currentRenderer["friendlyName"]);
        return upnp.setCurrentRenderer(currentRenderer["friendlyName"], true);
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
        console.log("updateMprisState: 0x"+mask.toString(16));
        if(mask != mprisStateMask) {
            upnp.mprisSetStateMask(mask);
            mprisStateMask = mask;
        }
    }

    function updateMprisMetaData(track) {
        var jsonString= JSON.stringify(track);
        upnp.mprisSetMetaData(jsonString);
    }
}

