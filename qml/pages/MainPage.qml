/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

import "../UPnP.js" as UPnP

Page {
    property bool showBusy : false

    // 0 inactive, 1 load queue data, 2 load browse stack data
    property int resumeState: 0

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Resume")
                onClicked: loadResumeMetaData()
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                id: pHeader
                title: qsTr("Donnie")
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height

                Column {
                    id: appTitleColumn
                    spacing: Theme.paddingLarge

                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        topMargin: Theme.paddingMedium
                    }

                    // Renderer and Server

                    Item {
                        anchors {
                            left: parent.left
                            right: parent.right
                        }
                        height: renderersColumn.height + serversColumn.height

                        Column {
                            id: renderersColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                            }
                            Row {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                }
                                Text {
                                    id: rLabel
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.secondaryColor
                                    wrapMode: Text.Wrap
                                    width: parent.width - anchors.leftMargin - rendererIcon.width

                                    text: qsTr("Renderer");
                                }
                                IconButton {
                                    id: rendererIcon
                                    anchors.rightMargin: Theme.paddingLarge
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon.source: isRendererOK()
                                                 ? "image://theme/icon-s-installed"
                                                 : "" //"image://donnie-icons/icon-s-failure3"
                                }
                            }

                            Text {
                                id: rName

                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.primaryColor
                                wrapMode: Text.Wrap
                                width: parent.width

                                text: renderer_friendlyname.value
                                      ? renderer_friendlyname.value
                                      : qsTr("[Click to select one]")
                            }
                        }

                        Column { // Content Servers
                            id: serversColumn
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: renderersColumn.bottom
                            }
                            Row {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                }
                                Text {
                                    id: sLabel
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.secondaryColor
                                    wrapMode: Text.Wrap
                                    width: parent.width - anchors.leftMargin - serverIcon.width

                                    text: qsTr("Content Server")
                                }
                                IconButton {
                                    id: serverIcon
                                    anchors.rightMargin: Theme.paddingLarge
                                    anchors.verticalCenter: parent.verticalCenter
                                    icon.source: isServerOK()
                                                 ? "image://theme/icon-s-installed"
                                                 : "" //"image://donnie-icons/icon-s-failure3"
                                }
                            }

                            Text {
                                id: sName

                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.primaryColor
                                wrapMode: Text.Wrap
                                width: parent.width

                                text: server_friendlyname.value
                                         ? server_friendlyname.value
                                         : qsTr("[Click to select one]")
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: pageStack.push(Qt.resolvedUrl("DiscoveryPage.qml"))
                        }
                    }

                    // Browser/Search/Player buttons

                    Rectangle {
                        width: parent.width
                        height: browseRow.height
                        opacity: 0
                    }

                    Row {
                        id: browseRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        IconButton {
                            icon.source: "image://theme/icon-m-folder"
                            enabled: !showBusy && isServerOK()
                            onClicked: gotoBrowsePage();
                        }
                        Button {
                            text: qsTr("Browser")
                            enabled: !showBusy && isServerOK()
                            onClicked: gotoBrowsePage();
                        }
                    }

                    Row {
                        id: searchRow
                        anchors.horizontalCenter: parent.horizontalCenter
                        IconButton {
                            icon.source: "image://theme/icon-m-search"
                            enabled: !showBusy && isServerOK()
                            onClicked: gotoSearchPage();
                        }
                        Button {
                            text: qsTr("Search")
                            enabled: !showBusy && isServerOK()
                            onClicked: gotoSearchPage();
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        IconButton {
                            icon.source: "image://theme/icon-m-music"
                            enabled: isRendererOK()
                            onClicked: gotoPlayerPage();
                        }
                        Button {
                            text: qsTr("Player")
                            enabled: isRendererOK()
                            onClicked: gotoPlayerPage();
                        }
                    }

                    /*Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        IconButton {
                            icon.source: "image://theme/icon-m-transfer"
                            enabled: !showBusy
                            onClicked: pageStack.push(Qt.resolvedUrl("DiscoveryPage.qml"));
                        }
                        Button {
                            text: "Selector"
                            enabled: !showBusy
                            onClicked: pageStack.push(Qt.resolvedUrl("DiscoveryPage.qml"));
                        }
                    }*/

                    /*Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        IconButton {
                            icon.source: "image://theme/icon-m-developer-mode"
                            onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
                        }
                        Button {
                            text: "Settings"
                            onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
                        }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        IconButton {
                            visible: show_open_logpage.value === "true"
                            icon.source: "image://theme/icon-m-note"
                            onClicked: showErrorLogPage();
                        }
                        Button {
                            visible: show_open_logpage.value === "true"
                            text: "Show Log"
                            onClicked: showErrorLogPage();
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        IconButton {
                            icon.source: "image://theme/icon-m-about"
                            onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
                        }
                        Button {
                            text: "About"
                            onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
                        }
                    }*/
                }

            }

        }

        VerticalScrollDecorator { }
    }


    function gotoPlayerPage() {
        pageStack.push(getPlayerPage());
    }

    function gotoBrowsePage() {
        if(browsePage.cid === "")
            pageStack.push(browsePage, {cid: "0"});
        else
            pageStack.push(browsePage);
    }

    // to wait for pagestack to be available
    property string openBrowseId: ""
    Timer {
        id: openBrowseTimer
        interval: 100
        running: false
        repeat: true
        onTriggered: {
            if(!pageStack.busy) {
                running = false;
                pageStack.push(browsePage, {cid: openBrowseId});
            }
        }
    }

    function openBrowsePage(id) {
        browsePage.reset();
        if(pageStack.busy) {
            openBrowseId = id;
            openBrowseTimer.start();
        } else
            pageStack.push(browsePage, {cid: id});
    }

    function gotoSearchPage() {
        //pageStack.push(searchPage);
        pageStack.push(Qt.resolvedUrl("Search.qml"),
                       {searchCapabilities: app.currentServerSearchCapabilities});
    }

    function showErrorLogPage() {
        var i;
        var logText = "";
        for(i=0;i<app.errorLog.length();i++)
            logText += app.errorLog.elements[i];
        pageStack.push(Qt.resolvedUrl("LogPage.qml"), {logText: logText});
    }

    function isRendererOK() {
        if(renderer_udn.value === "donnie-player-udn")
            return true;
        return app.hasCurrentRenderer();
    }

    function isServerOK() {
        return app.hasCurrentServer() ? true : false
    }

    function loadLastBrowsingJSON() {
        try {
            var lastBrowsingInfo = JSON.parse(app.last_browsing_info.value)
            return lastBrowsingInfo
        } catch( err ) {
            app.error("Exception in loadLastBrowsingJSON: " + err);
            app.error("json: " + app.last_browsing_info.value);
        }
        return null
    }

    function loadLastPlayingJSON() {
        try {
            var lastPlayingInfo = JSON.parse(app.last_playing_info.value);
            return lastPlayingInfo
        } catch( err ) {
            app.error("Exception in loadLastPlayingJSON: " + err);
            app.error("json: " + app.last_playing_info.value);
        }
        return null
    }

    function loadBrowseStackMetaData() {
        var i
        showBusy = true
        try {
            var linfo = loadLastBrowsingJSON()
            if(linfo !== null && linfo.length > 0) {
                var pos = 0
                var ids = []
                for(i=0;i<linfo.length;i++)
                    ids[pos++] = linfo[i]
                if(ids.length > 0) {
                    resumeState = 2
                    upnp.getMetaData(ids)
                }
            }
        } catch(err) {
            app.error("Exception in loadBrowseStackMetaData: "+err);
            app.showErrorDialog(qsTr("Failed to load previously saved Browse Stack Ids."))
            showBusy = false
        }
    }

    property var userDefinedItems : []
    function loadResumeMetaData() {
        var i
        showBusy = true
        try {
            var linfo = loadLastPlayingJSON()
            if(linfo !== null && linfo.currentTrackId && linfo.queueTrackIds) {
                var pos = 0
                var ids = []

                metaDataCurrentTrackId = linfo.currentTrackId

                userDefinedItems = []
                for(i=0;i<linfo.queueTrackIds.length;i++) {
                    if(linfo.queueTrackIds[i].dtype === "cs")
                        ids[pos++] = linfo.queueTrackIds[i].data
                    else if(linfo.queueTrackIds[i].dtype === "ud")
                        userDefinedItems.push({index: i, data: linfo.queueTrackIds[i].data})
                }

                if(ids.length > 0) {
                    resumeState = 1
                    upnp.getMetaData(ids)
                }
            }
        } catch(err) {
            app.error("Exception in loadResumeMetaData: "+err);
            app.showErrorDialog(qsTr("Failed to load previously saved Queue Ids.\nCan not Resume."))
            showBusy = false
        }
        if(resumeState == 0) // not loading the queue
            loadBrowseStackMetaData()
    }

    function searchForRendererAndServer() {
        var started = false
        // check if configured renderer and server can be reached
        if(renderer_friendlyname.value && renderer_udn.value !== "donnie-player-udn") {
            upnp.getRendererJson(renderer_friendlyname.value, search_window.value)
            started = true
        }
        else if(renderer_friendlyname.value && renderer_udn.value === "donnie-player-udn")
            app.useBuiltInPlayer = true
        if(server_friendlyname.value) {
            upnp.getServerJson(server_friendlyname.value, search_window.value)
            started = true
        }
        showBusy = started
    }

    property bool startUp: false
    signal networkStateChange(int connected)
    onNetworkStateChange: {
        if(connected === UPnP.NetworkState.Unknown)
            return
        if(!startUp) {
            startUp = true
            if(connected !== UPnP.NetworkState.Connected) {
                app.showConfirmDialog(qsTr("There seems to be no internet connection (wifi off). Your Renderer and Media Server might not be reachable."),
                                      qsTr("Continue"),
                                      function() { searchForRendererAndServer() },
                                      function() { Qt.quit() }
                )
            } else
                searchForRendererAndServer()
        } else {
            // ToDo
        }
    }

    //Component.onCompleted: {
        // check wlan
        //console.log("state: " + app.wlanDetectState.value + ", type: " + app.wlanDetectType.value)
    //}

    property string metaDataCurrentTrackId

    //property bool rendererDone: false
    //property bool serverDone: false

    Connections {
        target: upnp

        onGetRendererDone: {
            var i;

            try {
                var devices = JSON.parse(rendererJson);

                if(devices["renderer"] && devices["renderer"].length>0)
                    app.setCurrentRenderer(devices["renderer"][0]);
            } catch(err) {
                app.error("Exception in onGetRendererDone: "+err);
                app.error("json: " + rendererJson);

            }

            showBusy = false; // VISIT both should be done
        }

        onGetServerDone: {
            var i;

            try {
                var devices = JSON.parse(serverJson);

                if(devices["server"] && devices["server"].length>0)
                    app.setCurrentServer(devices["server"][0]);
            } catch(err) {
                app.error("Exception in onGetServerDone: "+err);
                app.error("json: " + serverJson);
            }

            showBusy = false; // VISIT both should be done

            if(app.hasCurrentServer()) {
                if(resume_saved_info.value === 1) // 0: never, 1: ask, 2:always
                    app.showConfirmDialog(qsTr("Load previously saved queue?"), qsTr("Load"), function() {
                        loadResumeMetaData()
                    })
                else if(resume_saved_info.value === 2)
                    loadResumeMetaData()
            }
        }

        onError: {
            console.log("Main::onError: " + msg);
            app.error(msg);
            showBusy = false; // VISIT only one could fail
        }

        onMprisControl: {
            console.log("onMprisControl: " + action);
            switch(action) {
            case "Play":
                app.getPlayerPage().pause();
                break;
            case "Pause":
                app.getPlayerPage().pause();
                break;
            case "Next":
                app.getPlayerPage().next();
                break;
            case "Previous":
                app.getPlayerPage().prev();
                break;
            }
        }

        onMprisOpenUri: {
            console.log("Donnie.onMprisOpenUri: " + uri)
            // assume broadcast
            var track = UPnP.createUserAddedTrack(uri, "Mpris Added", UPnP.AudioItemType.AudioBroadcast)
            app.getPlayerPage().openTrack(track)
        }

        // called when metadata has been collected from stored resume info
        onMetaData: {
            //console.log("onMetaData: " + metaDataJson);
            if(error !== 0) {
                app.showErrorDialog(qsTr("Failed to retrieve metadata for previously saved Ids.\nCan not Resume."))
                showBusy = false
                if(resumeState == 1)
                    loadBrowseStackMetaData()
                else
                    resumeState = 0
                return
            }

            try {
                var metaData = JSON.parse(metaDataJson);

                switch(resumeState) {
                case 1:
                    // restore queue and current track
                    var currentTrackIndex = -1
                    var tracks = []
                    var i
                    var track
                    // todo: getPlayerPage().reset() but does not exist

                    // create items for stored id's
                    for(i=0;i<metaData.length;i++) {
                        if(metaData[i].items && metaData[i].items.length>0) {
                            track = UPnP.createListItem(metaData[i].items[0])
                            tracks.push(track)
                            if(track.id === metaDataCurrentTrackId)
                                currentTrackIndex = tracks.length - 1
                        }
                    }

                    // create items for user added uris
                    for(i=0;i<userDefinedItems.length;i++) {
                        track = UPnP.createUserAddedTrack(userDefinedItems[i].data.uri,
                                                          userDefinedItems[i].data.title,
                                                          userDefinedItems[i].data.streamType)
                        tracks.splice(userDefinedItems[i].index, 0, track)
                        if(track.id === metaDataCurrentTrackId)
                            currentTrackIndex = tracks.length - 1
                    }

                    metaDataCurrentTrackId = ""

                    getPlayerPage().addTracks(tracks,
                                              currentTrackIndex,
                                              UPnP.isBroadcast(track) ? -1 : app.last_playing_position.value)
                    loadBrowseStackMetaData()
                    break;

                case 2:
                    // restore browse stack
                    var index = 0
                    browsePage.reset()
                    browsePage.pushOnBrowseStack("0", "-1", qsTr("[Top Level]"), -1);
                    for(var i=0;i<metaData.length;i++) {
                        if(metaData[i].containers && metaData[i].containers.length>0) {
                            var item = metaData[i].containers[0]
                            browsePage.pushOnBrowseStack(item.id, item.pid, item.title, index);
                            index++
                        }
                    }
                    browsePage.cid = app.currentBrowseStack.peek().id
                    resumeState = 0
                    break;
                }
                showBusy = false
            } catch(err) {
                app.error("Exception in onMetaData: "+err);
                app.error("json: " + metaDataJson);
                app.showErrorDialog(qsTr("Failed to parse previously saved Ids.\nCan not Resume."))
                showBusy = false
            }
        }
    }

    ConfigurationValue {
        id: search_window
        key: "/donnie/search_window"
        defaultValue: 2
    }
    ConfigurationValue {
        id: renderer_friendlyname
        key: "/donnie/renderer_friendlyname"
    }
    ConfigurationValue {
        id: renderer_udn
        key: "/donnie/renderer_udn"
    }
    ConfigurationValue {
        id: server_friendlyname
        key: "/donnie/server_friendlyname"
    }
    ConfigurationValue {
        id: show_open_logpage
        key: "/donnie/show_open_logpage"
        defaultValue: "false"
    }
    ConfigurationValue {
        id: resume_saved_info
        key: "/donnie/resume_saved_info"
        defaultValue: 0
    }
}
