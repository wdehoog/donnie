/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

Page {
    id: page
    property bool showBusy : false

    allowedOrientations: Orientation.All


    ListModel {
      id: devicesModel;
      /*ListElement {
          type: "Renderer"
          friendlyName: "A"
          modelName: "AA"
      }
      ListElement {
          type: "Renderer"
          friendlyName: "B"
          modelName: "BB"
      }
      ListElement {
          type: "Server"
          friendlyName: "A"
          modelName: "AA"
      }
      ListElement {
          type: "Server"
          friendlyName: "B"
          modelName: "BB"
      }*/
    }

    SilicaListView {
        id: devicesList
        model: devicesModel;
        width: parent.width
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Discover UPnP Devices")
                onClicked: discover();
            }
            /*MenuItem {
                text: qsTr("Browse")
                onClicked: {
                    browsePage.reset();
                    pageStack.push(browsePage, {cid: "0"});
                }
            }*/
        }

        header: PageHeader {
            id: pHeader
            title: qsTr("UPnP Devices")

            BusyIndicator {
                id: busyThingy
                parent: pHeader.extraContent
                anchors.left: parent.left
                running: showBusy
            }
        }

        section {
            property: "type"
            criteria: ViewSection.FullString
            delegate: SectionHeader {
                text: section;
            }
        }

        delegate: BackgroundItem {
            id: listItem
            height: icolumn.height

            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.paddingLarge
            }

            Column {
                id: icolumn
                anchors {
                    left: parent.left
                    right: checkbox.left
                }

                Text {
                    id: fName

                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.primaryColor
                    wrapMode: Text.Wrap
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    text: friendlyName
                }

                Text {
                    id: mName

                    //anchors.top: fName.bottom
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    wrapMode: Text.Wrap
                    anchors {
                        left: parent.left
                        right: parent.right
                    }

                    text: modelName
                }
            }

            Switch {
                id: checkbox
                checked: selected
                automaticCheck: false
                anchors {
                    right: parent.right;
                    rightMargin: Theme.horizontalPageMargin
                    //verticalCenter: listItem.verticalCenter
                }

                onClicked: {
                    var device = devicesModel.get(index);

                    // clear current choice
                    for(var i=0;i<devicesModel.count;i++) {
                        if(devicesModel.get(i).type === device.type)
                            devicesModel.set(i, { "selected": false })
                    }

                    // update for new choice
                    devicesModel.set(index, { "selected": true })
                    if(device.type === "Content Server") {
                        app.setCurrentServer(app.discoveredServers[device.discoveryIndex]);
                        storeSelectedServer(device);
                    } else {
                        if(device.UDN === "donnie-player-udn") {
                            app.useBuiltInPlayer = true;
                            app.setCurrentRenderer(undefined);
                        } else {
                            app.useBuiltInPlayer = false;
                            app.setCurrentRenderer(app.discoveredRenderers[device.discoveryIndex]);
                        }
                        storeSelectedRenderer(device);
                    }

                }
            }

            onClicked: {
                var item = devicesList.model.get(index);
                pageStack.push(upnpDeviceDetails, {
                    type: item.type,
                    friendlyName: item.friendlyName,
                    manufacturer: item.manufacturer,
                    modelName: item.modelName,
                    udn: item.UDN,
                    urlBase: item.URLBase,
                    deviceType: item.deviceType
                });
            }
        }

        ViewPlaceholder {
            enabled: devicesList.count == 0;
            text: "No Devices"
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        discover();
    }

    Connections {
        target: upnp
        onDiscoveryDone: {
            var i;

            try {
                var devices = JSON.parse(devicesJson);

                app.discoveredRenderers = devices["renderers"];
                app.discoveredServers = devices["servers"];

                devicesModel.clear();
                var selected;
                var hasSelected = false;

                for(i=0;i<app.discoveredRenderers.length;i++) {
                    var renderer = app.discoveredRenderers[i];
                    selected = renderer["UDN"] === renderer_udn.value;
                    if(selected) {
                        app.setCurrentRenderer(renderer);
                        updateSelectedRenderer(renderer["friendlyName"]);
                        hasSelected = true;
                    }
                    devicesModel.append({
                        type: "Renderer",
                        discoveryIndex: i,
                        friendlyName: renderer["friendlyName"],
                        manufacturer: renderer["manufacturer"],
                        modelName: renderer["modelName"],
                        UDN: renderer["UDN"],
                        URLBase: renderer["URLBase"],
                        deviceType: renderer["deviceType"],
                        selected: selected
                    });
                }

                // add local player
                selected = "donnie-player-udn" === renderer_udn.value;
                if(selected)
                    hasSelected = true;
                devicesModel.append({
                    type: "Renderer",
                    discoveryIndex: app.discoveredRenderers.length,
                    friendlyName: "Built-in Player",
                    manufacturer: "donnie",
                    modelName: "Sailfish QTAudio Player",
                    UDN: "donnie-player-udn",
                    URLBase: "",
                    deviceType: "a page with audio player controls and list of tracks",
                    selected: selected
                });

                // make sure one player is selected
                if(!hasSelected) {
                    // if no renderer is selected select the first one
                    devicesModel.set(0, { "selected": true });
                    storeSelectedRenderer(devicesModel.get(0));
                    if(app.discoveredRenderers.length>0)
                        app.setCurrentRenderer(app.discoveredRenderers[0]);
                    else
                        app.useBuiltInPlayer = true;
                }

                hasSelected = false;
                for(i=0;i<app.discoveredServers.length;i++) {
                    var server = app.discoveredServers[i];
                    selected = server["UDN"] === server_udn.value;
                    if(selected) {
                        app.setCurrentServer(server);
                        updateSelectedServer(server["friendlyName"]);
                        hasSelected = true;
                    }
                    devicesModel.append({
                        type: "Content Server",
                        discoveryIndex: i,
                        friendlyName: server["friendlyName"],
                        manufacturer: server["manufacturer"],
                        modelName: server["modelName"],
                        UDN: server["UDN"],
                        URLBase: server["URLBase"],
                        deviceType: server["deviceType"],
                        selected: selected
                    });
                }
                if(!hasSelected && app.discoveredServers.length>0) {
                    // if no server is selected select the first one
                    app.setCurrentServer(app.discoveredServers[0]);
                    var firstIndex = app.discoveredRenderers?app.discoveredRenderers.length+1:1;
                    devicesModel.set(firstIndex, { "selected": true });
                    storeSelectedServer(devicesModel.get(firstIndex));
                }
            } catch(err) {
                app.error("Exception in Discovery: "+err);
                app.error("json: " + devicesJson);
            }
            showBusy = false;
        }
    }

    function discover() {
        showBusy = true;
        //search_upnp_devices.sendMessage({search_window: search_window.value});
        upnp.discover(search_window.value);
    }

    function storeSearchWindow(searchWindow) {
        search_window.value = searchWindow;
        search_window.sync();
    }

    function storeSelectedRenderer(device) {
        renderer_udn.value = device.UDN;
        renderer_udn.sync();
        renderer_friendlyname.value = device.friendlyName;
        renderer_friendlyname.sync();
    }

    function updateSelectedRenderer(friendlyName) {
        renderer_friendlyname.value = friendlyName;
        renderer_friendlyname.sync();
    }

    function storeSelectedServer(device) {
        server_udn.value = device.UDN;
        server_udn.sync();
        server_friendlyname.value = device.friendlyName;
        server_friendlyname.sync();
    }

    function updateSelectedServer(friendlyName) {
        server_friendlyname.value = friendlyName;
        server_friendlyname.sync();
    }

    ConfigurationValue {
            id: search_window
            key: "/donnie/search_window"
            defaultValue: 10
    }
    ConfigurationValue {
            id: renderer_udn
            key: "/donnie/renderer_udn"
    }
    ConfigurationValue {
            id: renderer_friendlyname
            key: "/donnie/renderer_friendlyname"
    }
    ConfigurationValue {
            id: server_udn
            key: "/donnie/server_udn"
    }
    ConfigurationValue {
            id: server_friendlyname
            key: "/donnie/server_friendlyname"
    }
    ConfigurationValue {
            id: server_use_nexturi
            key: "/donnie/server_use_nexturi"
    }
}

