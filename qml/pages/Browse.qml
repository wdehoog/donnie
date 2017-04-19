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

import "../UPnP.js" as UPnP

Page {
    id: page

    property bool showBusy: false;
    property var cid;
    property var contents;

    //property string pathTreeText : "";
    property string pathText: "";
    //property bool showPathTree: false;

    allowedOrientations: Orientation.All

    Connections {
        target: upnp
        onBrowseDone: {
            var i;

            console.log(contentsJson);
            contents = JSON.parse(contentsJson);

            browseModel.clear();

            if(cid !== "0") // no ".." for the root
                browseModel.append({
                    type: "Container",
                    id: app.currentBrowseStack.peek().pid,
                    pid: "-2",
                    title: "..",
                    artist: "", album: "", duration: ""
                });

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
                if(item.properties["upnp:class"] === "object.item.audioItem.musicTrack")
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

            showBusy = false;
        }

        onError: {
            console.log(msg);
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
                      //if()
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
        showBusy = true;
        if(app.currentBrowseStack.empty())
            pushOnBrowseStack(cid, "-1", "[Top Level]");
        upnp.browse(cid);
    }

    onStatusChanged: {
        // add Player page if not yet done
        if (status === PageStatus.Active) {
            var page = pageStack.find(function (page) {
                return page.id === playerPage || page.id === rendererPage;
            });
            if(!page)
                pageStack.pushAttached(getPlayerPage(), {});
        }
    }

    function reset() {
        pathListModel.clear();
        app.currentBrowseStack.empty();
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

    function getPlayerPage() {
        if(useBuiltInPlayer)
            return playerPage;
        else
            return rendererPage;
    }

    function addToPlayer(id) {
        var i;

        for(i=0;i<contents.items.length;i++) {
            if(contents.items[i].id === id) {
                var track = createTrack(id, contents.items[i]);
                getPlayerPage().addTracks([track]);
                break;
            }
        }
    }

    function addAllToPlayer() {
        for(var i=0;i<listView.model.count;i++) {
            var item = listView.model.get(i);
            addToPlayer(item.id);
        }
    }
}
