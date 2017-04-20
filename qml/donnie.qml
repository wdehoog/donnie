/*
  Copyright (C) 2013 Jolla Ltd.
  Contact: Thomas Perl <thomas.perl@jollamobile.com>
  All rights reserved.

  You may use this file under the terms of BSD license as follows:

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Jolla Ltd nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
}

