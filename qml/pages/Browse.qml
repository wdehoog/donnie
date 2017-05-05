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

import "../UPnP.js" as UPnP

Page {
    id: page

    property bool showBusy: false
    property string cid : ""
    property var contents

    //property string pathTreeText : "";
    property string pathText: "";
    //property bool showPathTree: false;

    allowedOrientations: Orientation.All

    Connections {
        target: upnp
        onBrowseDone: {
            var i;

            try {
                contents = JSON.parse(contentsJson);

                browseModel.clear();

                if(cid !== "0") { // no ".." for the root
                    var pid = getParentID();
                    browseModel.append({
                        type: "Container",
                        id: pid,
                        pid: "-2",
                        title: "..",
                        artist: "", album: "", duration: ""
                    });
                }

                for(i=0;i<contents.containers.length;i++) {
                    var container = contents.containers[i];
                    browseModel.append({
                        type: "Container",
                        id: container["id"],
                        pid: container["pid"],
                        title: container["title"],
                        artist: "", album: "", duration: ""
                    });
                }

                for(i=0;i<contents.items.length;i++) {
                    var item = contents.items[i];
                    var upnpClass = item.properties["upnp:class"];
                    if(upnpClass && UPnP.startsWith(upnpClass, "object.item.audioItem"))
                        browseModel.append({
                            type: "Item",
                            id: item["id"],
                            pid: item["pid"],
                            title: item["title"],
                            artist: item.properties["dc:creator"],
                            album: item.properties["upnp:album"],
                            duration: item.resources[0].attributes["duration"]
                        });
                    else
                        console.log("onBrowseDone: skipped loading of an object of class " + item.properties["upnp:class"]);
                }

                pathText = UPnP.getCurrentPathString(app.currentBrowseStack);
                //pathTreeText = UPnP.getCurrentPathTreeString(app.currentBrowseStack);
            } catch( err ) {
                app.error("Exception in onBrowseDone: " + err);
                app.error("json: " + contentsJson);
            }

            showBusy = false;
        }

        onError: {
            console.log("Browse::onError: " + msg);
            app.errorLog.push(msg);
            showBusy = false;            
        }
    }

    ListModel {
        id: browseModel
    }

    ListModel {
        id: pathListModel
    }

    SilicaListView {
        id: listView
        model: browseModel
        anchors.fill: parent
        anchors.margins: Theme.paddingMedium

        header: Column {
            id: lvColumn

            width: parent.width
            //height: pHeader.height + pathComboBox.height + Theme.paddingLarge * 2
            anchors.bottomMargin: Theme.paddingLarge
            spacing: Theme.paddingLarge

            PageHeader {
                id: pHeader
                title: qsTr("Browse")
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy;
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                id: path
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.paddingMedium
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
                elide: Text.ElideLeft
                text: pathText
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.push(menuDialogComponent)
                }
            }

        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add All To Player")
                onClicked: addAllToPlayer()
            }
        }

        delegate: ListItem {
            id: delegate
            //height: Math.max(imageItem.height, label.height) makes it too small
            Row {
                spacing: Theme.paddingMedium
                Image {
                  id: imageItem
                  fillMode: Image.PreserveAspectFit
                  anchors.verticalCenter: parent.verticalCenter
                  source: {
                      if(pid === "-2") // the ".." item
                          return "image://theme/icon-m-back";
                      if(type === "Container")
                          return "image://theme/icon-m-folder";
                      //if() currently non music files are filtered out
                        return "image://theme/icon-m-music";
                      //return "image://theme/icon-m-other";
                  }
                }

                Label {
                    id: titleLabel
                    //anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: title;
                }

                Label {
                    id: metaLabel
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors.baseline: titleLabel.baseline
                    //anchors {
                    //    right: parent.right
                    //    rightMargin: Theme.horizontalPageMargin
                        //bottom: parent.bottom
                        //bottomMargin: Theme.paddingSmall
                    //}
                    text: duration ? UPnP.getDurationString(model.duration) : "";
                }

            }
            menu: contextMenu

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        text: "Add To Player"
                        enabled: listView.model.get(index).type === "Item"
                        onClicked: addToPlayer(listView.model.get(index).id);
                    }
                    MenuItem {
                        text: "Add All To Player"
                        onClicked: addAllToPlayer();
                    }
                }
            }
            onClicked: {
                var item = listView.model.get(index);
                if(item.pid === "-2") // the ".." item
                    popFromBrowseStack();
                else if(item.type === "Container")
                    pushOnBrowseStack(item.id, item.pid, item.title);
                if(item.type !== "Item")
                  cid = item.id;
            }

        }

        VerticalScrollDecorator {}

    }

    // from ComboBox.qml
    Component {
        id: menuDialogComponent

        Page {
            allowedOrientations: Orientation.All

            Component.onCompleted: {
                var menuItems = app.currentBrowseStack.elements();
                for (var i = 0; i < menuItems.length; i++) {
                    var child = menuItems[menuItems.length-i];
                    items.append( {"item": child } );
                }
            }

            ListModel {
                id: items
            }

            SilicaListView {
                id: view

                anchors.fill: parent
                model: items

                header: PageHeader {
                    title: "Choose Path"
                }

                delegate: BackgroundItem {
                    id: delegateItem

                    onClicked: {
                        popFromBrowseStackUntil(model.item.id);
                        cid = item.id;
                        pageStack.pop();
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x*2
                        font.pixelSize: Theme.fontSizeSmall
                        elide: Text.ElideLeft
                        //text: model.item.title
                        text: UPnP.getPathString(app.currentBrowseStack, model.item.id)
                        color: (delegateItem.highlighted || model.item === cid)
                               ? Theme.highlightColor
                               : Theme.primaryColor
                    }
                }
                VerticalScrollDecorator {}
            }
        }
    }

    onCidChanged: {
        if(cid === "")
            return;

        showBusy = true;

        if(app.currentBrowseStack.empty()) {
            if(cid === "0") // root
                pushOnBrowseStack(cid, "-1", "[Top Level]");
            else {
                // probably arrived here from search page
                // so we have to query for the parent to create
                // a .. item
                var pathJson = upnp.getPathJson(cid);
                var pid = upnp.getParentID(cid);
                if(pid !== "") {
                    var arr = pid.split(",");
                    pushOnBrowseStack(arr[0], "-2", arr[1].length>0?arr[1]:"");
                } else
                    // no parent, add root again
                    pushOnBrowseStack("0", "-1", "[Top Level]");
            }
        }

        upnp.browse(cid);
    }

    onStatusChanged: {
        // add Player page if not yet done
//        if (status === PageStatus.Active) {
//            var page = pageStack.find(function (page) {
//                return page.id === playerPage || page.id === rendererPage;
//            });
//            if(!page)
//                pageStack.pushAttached(getPlayerPage(), {});
//        }
    }

    function reset() {
        pathListModel.clear();
        app.currentBrowseStack.empty();
        cid = "";
    }

    function getParentID() {
        // use browse stack if possible
        if(app.currentBrowseStack.length() > 0)
            return app.currentBrowseStack.peek().id;

        // look in contents VISIT is this ever used?
        if(contents.containers.length > 0)
            return upnp.getParentID(contents.containers[0]["pid"]);
        if(contents.items.length > 0)
            return upnp.getParentID(contents.items[0]["pid"]);

        // no idea, give root
        return "0";
    }

    function popFromBrowseStackUntil(id) {
        do {
            if(app.currentBrowseStack.peek().id === id)
                break;
            popFromBrowseStack();
        } while(app.currentBrowseStack.length()>0)
    }

    function popFromBrowseStack() {        
        app.currentBrowseStack.pop();
        if(pathListModel.count > 1) {
            pathListModel.remove(0);
            //pathComboBoxIndex = -1;
        } else
            console.log("popFromBrowseStack too often")
    }

    function pushOnBrowseStack(id, pid, title) {
        var dir = new Object();
        dir.id = id;
        dir.pid = pid;
        dir.title = title;
        app.currentBrowseStack.push(dir);

        pathListModel.insert(0, {id: id, pid: pid, title: title});
        //pathComboBoxIndex = -1;
    }

    function createTrack(id, item) {
        var track = new Object();
        track["id"] = id;
        track["title"] = item["title"];
        track["didl"] = item["didl"];
        track["artist"] = item.properties["dc:creator"];
        track["album"] = item.properties["upnp:album"];
        track["albumArtURI"] = item.properties["upnp:albumArtURI"];
        track["uri"] = item.resources[0]["Uri"];
        track["duration"] = item.resources[0].attributes["duration"];
        track["index"] = item.properties["upnp:originalTrackNumber"];
        return track;
    }

    function getTrack(id) {
        var i;

        for(i=0;i<contents.items.length;i++) {
            if(contents.items[i].id === id) {
                var track = createTrack(id, contents.items[i]);
                return track;
            }
        }
        return undefined;
    }

    function addToPlayer(id) {
        var track = getTrack(id);
        if(track !== undefined)
            getPlayerPage().addTracks([track]);
    }

    function addAllToPlayer() {
        var tracks = [];

        for(var i=0;i<listView.model.count;i++) {
            var item = listView.model.get(i);
            var track = getTrack(item.id);
            if(track !== undefined)
                tracks.push(track);
        }

        getPlayerPage().addTracks(tracks);
    }
}
