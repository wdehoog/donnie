/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

Page {
    property bool showBusy : false

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
            }
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
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

                                    text: "Renderer";
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
                                      : "[Click to select one]"
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

                                    text: "Content Server"
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
                                         : "[Click to select one]";
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
                            text: "Browser"
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
                            text: "Search"
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
                            text: "Player"
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

    Component.onCompleted: {
        // check if configured renderer and server can be reached
        showBusy = true;
        if(renderer_friendlyname.value && renderer_udn.value !== "donnie-player-udn")
            upnp.getRendererJson(renderer_friendlyname.value, search_window.value);
        else if(renderer_friendlyname.value && renderer_udn.value === "donnie-player-udn")
            app.useBuiltInPlayer = true;
        if(server_friendlyname.value)
            upnp.getServerJson(server_friendlyname.value, search_window.value);
    }

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
        }

        onError: {
            console.log(msg);
            app.error(msg);
            showBusy = false; // VISIT only one could fail
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

}
