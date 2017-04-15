/*
 * Unplayer
 * Copyright (C) 2015 Alexey Rochev <equeim@gmail.com>
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

import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

Page {
    property bool showBusy : false

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

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

                Image {
                    id: icon

                    anchors.horizontalCenter: parent.horizontalCenter
                    asynchronous: true
                    source: {
                        var iconSize = Theme.iconSizeExtraLarge
                        if (iconSize < 108)
                            iconSize = 86
                        else if (iconSize < 128)
                            iconSize = 108
                        else if (iconSize < 256)
                            iconSize = 128
                        else iconSize = 256

                        return "/usr/share/icons/hicolor/" + iconSize + "x" + iconSize + "/apps/donnie.png"
                    }
                }

                Column {
                    id: appTitleColumn
                    spacing: Theme.paddingLarge

                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        top: icon.bottom
                        topMargin: Theme.paddingMedium
                    }

                    Text {
                        id: rName

                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.primaryColor
                        wrapMode: Text.Wrap
                        anchors {
                            left: parent.left
                            right: parent.right
                        }

                        text: "Renderer: " + (renderer_friendlyname.value
                              ? renderer_friendlyname.value
                              : "[use Discovery to select one]");
                    }

                    Text {
                        id: sName

                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.primaryColor
                        wrapMode: Text.Wrap
                        anchors {
                            left: parent.left
                            right: parent.right
                        }

                        text: "Content Server: " + (server_friendlyname.value
                              ? server_friendlyname.value
                              : "[use Discovery to select one]");
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Discover Devices"
                        onClicked: pageStack.push(Qt.resolvedUrl("DiscoveryPage.qml"));
                    }
                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Browse"
                        //enabled: app.hasCurrentServer();
                        onClicked: pageStack.push(browsePage, {cid: "0"});
                    }
                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Settings"
                        onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"));
                    }
                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "About"
                        onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"));
                    }
                }

            }

        }

        VerticalScrollDecorator { }
    }

    Component.onCompleted: {
        // check if configured renderer and server can be reached
        showBusy = true;
        if(renderer_friendlyname.value && renderer_udn !== "donnie-player-udn")
            upnp.getRendererJson(renderer_friendlyname.value);
        if(server_friendlyname.value)
            upnp.getServerJson(server_friendlyname.value);
    }

    Connections {
        target: upnp

        onGetRendererDone: {
            var i;

            console.log(rendererJson);
            var devices = JSON.parse(rendererJson);

            if(devices["renderer"] && devices["renderer"].length>0)
                app.setCurrentRenderer(devices["renderer"][0]);

            showBusy = false; // VISIT both should be done
        }

        onGetServerDone: {
            var i;

            console.log(serverJson);
            var devices = JSON.parse(serverJson);

            if(devices["server"] && devices["server"].length>0)
                app.setCurrentServer(devices["server"][0]);

            showBusy = false; // VISIT both should be done
        }

        onError: {
            console.log(msg);
            showBusy = false; // VISIT only one could fail
        }
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

}
