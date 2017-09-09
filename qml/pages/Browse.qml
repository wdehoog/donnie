/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0

import org.nemomobile.configuration 1.0

import "../UPnP.js" as UPnP

Page {
    id: page

    property bool showBusy: false
    property string cid : "" // current id
    property int cScrollIndex: -1 // index to scroll to when going 'back'
    property var contents

    property int startIndex: 0
    property int maxCount: max_number_of_results.value
    property int totalCount

    //property string pathTreeText : "";
    property string pathText: "";
    //property bool showPathTree: false;

    allowedOrientations: Orientation.All

    Connections {
        target: upnp
        onBrowseDone: {
            var i;

            try {

                //console.log(contentsJson)
                contents = JSON.parse(contentsJson);

                // no ".." for the root or if there already is one
                if(cid !== "0" && browseModel.count == 0) {
                    browseModel.append({
                        type: "Container",
                        id: app.currentBrowseStack.peek().pid,
                        pid: "-2",
                        title: "..",
                        artist: "", album: "", duration: "",
                        titleText: "..", metaText: "", durationText: "",
                        currentIndex: app.currentBrowseStack.peek().currentIndex
                    });
                }

                for(i=0;i<contents.containers.length;i++) {
                    var container = contents.containers[i];
                    browseModel.append(UPnP.createListContainer(container));
                }

                for(i=0;i<contents.items.length;i++) {
                    var item = contents.items[i];
                    var upnpClass = item.properties["upnp:class"];
                    if(upnpClass && UPnP.startsWith(upnpClass, "object.item.audioItem")) {                        
                        browseModel.append(UPnP.createListItem(item));
                    } else
                        console.log("onBrowseDone: skipped loading of an object of class " + item.properties["upnp:class"]);
                }

                pathText = UPnP.getCurrentPathString(app.currentBrowseStack);
                //pathTreeText = UPnP.getCurrentPathTreeString(app.currentBrowseStack);

                totalCount = contents["totalCount"];

                // scroll to previous position
                if(cScrollIndex > -1 && cScrollIndex < browseModel.count) {
                    listView.positionViewAtIndex(cScrollIndex, ListView.Center)
                }

            } catch( err ) {
                app.error("Exception in onBrowseDone: " + err);
                app.error("json: " + contentsJson);
            }

            showBusy = false;
        }

        onError: {
            if(cid !== "0" && browseModel.count == 0) { // no ".." for the root
                browseModel.append({
                    type: "Container",
                    id: app.currentBrowseStack.peek().pid,
                    pid: "-2",
                    title: "..",
                    artist: "", album: "", duration: "",
                    titleText: "..", metaText: "", durationText: "",
                    currentIndex: app.currentBrowseStack.peek().currentIndex
                });
            }
            pathText = UPnP.getCurrentPathString(app.currentBrowseStack);
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
                text: qsTr("Load Previous Set")
                enabled: startIndex >= maxCount
                onClicked: {
                    browseModel.clear();
                    browse(startIndex-maxCount);
                }
            }
            MenuItem {
                text: qsTr("Load Next Set")
                enabled: (startIndex + browseModel.count) < totalCount
                onClicked: {
                    browseModel.clear();
                    browse(startIndex+maxCount);
                }
            }
            MenuItem {
                text: qsTr("Load More")
                enabled: browseModel.count < totalCount
                onClicked: browse(startIndex+maxCount);
            }
        }

        PushUpMenu {
            MenuItem {
                text: qsTr("Load More")
                enabled: browseModel.count < totalCount
                onClicked: browse(startIndex+maxCount);
            }
            MenuItem {
                text: qsTr("Load Next Set")
                enabled: (startIndex + browseModel.count) < totalCount
                onClicked: {
                    browseModel.clear();
                    browse(startIndex+maxCount);
                }
            }
            MenuItem {
                 text: qsTr("Load Previous Set")
                 enabled: startIndex >= maxCount
                 onClicked: {
                     browseModel.clear();
                     browse(startIndex-maxCount);
                 }
            }
        }

        delegate: ListItem {
            id: delegate

            Row {
                spacing: Theme.paddingMedium
                width: parent.width
                anchors.rightMargin: Theme.paddingMedium

                Image {
                  id: imageItem
                  width: sourceSize.width > 0 ? Theme.iconSizeMedium : 0
                  height: sourceSize.height > 0 ? Theme.iconSizeMedium : 0
                  fillMode: Image.PreserveAspectFit
                  anchors.verticalCenter: parent.verticalCenter
                  source: {
                      if(pid === "-2") // the ".." item
                          return "image://theme/icon-m-back";
                      if(type === "Container") { //
                          if(albumArtURI && albumArtURI.length > 0)
                              return albumArtURI
                          else if(upnpclass == "object.container.album.musicAlbum")
                              return "image://theme/icon-m-music"
                          else
                              return "image://theme/icon-m-folder"
                      }
                      return ""
                  }
                }

                Column {
                    width: parent.width - imageItem.width
                    anchors.verticalCenter: imageItem.verticalCenter

                    Item {
                        width: parent.width
                        height: tt.height

                        Label {
                            id: tt
                            color: Theme.primaryColor
                            textFormat: Text.StyledText
                            truncationMode: TruncationMode.Fade
                            width: parent.width - dt.width
                            text: titleText ? titleText : ""
                        }
                        Label {
                            id: dt
                            anchors.right: parent.right
                            color: Theme.secondaryColor
                            font.pixelSize: Theme.fontSizeExtraSmall
                            text: durationText ? durationText : ""

                        }
                    }

                    Label {
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        textFormat: Text.StyledText
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                        visible: metaText ? (metaText.length > 0) : false
                        text: metaText ? metaText : ""
                    }
                }

            }

            menu: contextMenu

            Component {
                id: contextMenu
                ContextMenu {
                    enabled: (listView.model.get(index).type === "Item")
                    MenuItem {
                        text: "Add To Player"
                        onClicked: addToPlayer(listView.model.get(index));
                    }
                    MenuItem {
                        text: "Replace In Player"
                        onClicked: replaceInPlayer(listView.model.get(index));
                    }
                    MenuItem {
                        text: "Add All To Player"
                        onClicked: addAllToPlayer();
                    }
                    MenuItem {
                        text: "Replace All In Player"
                        onClicked: replaceAllInPlayer();
                    }
                }
            }

            onClicked: {
                var item = listView.model.get(index)
                if(item.pid === "-2") // the ".." item
                    popFromBrowseStack()
                else if(item.type === "Container")
                    pushOnBrowseStack(item.id, item.pid, item.title, index);
                if(item.type !== "Item") {
                    if(item.id !== "-1" )
                        cid = item.id
                    else // something went wrong
                        cid = "0"
                }
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
                for (var i = 1; i <= menuItems.length; i++) {
                    var child = menuItems[menuItems.length-i];
                    items.append( {"item": child } );
                    console.log("added:" +child.title)
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
                        popFromBrowseStackUntil(model.item.id)
                        cid = item.id
                        cScrollIndex = item.currentIndex
                        pageStack.pop()
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
            if(cid === "0") { // root
                pushOnBrowseStack(cid, "-1", "[Top Level]", -1);
            } /*else {
                // probably arrived here from search page
                // so we have to 'create' a browse stack
                // BUT that option has been disabled
                createBrowseStackFor(cid);
                pathText = UPnP.getCurrentPathString(app.currentBrowseStack);
            }*/
        }

        browseModel.clear();
        browse(0);
    }

    function browse(start) {
        startIndex = start;
        upnp.browse(cid, start, maxCount);
    }

    function reset() {
        pathListModel.clear();
        app.currentBrowseStack.empty();
        cid = "";
        cScrollIndex = -1
    }

    function popFromBrowseStackUntil(id) {
        do {
            if(app.currentBrowseStack.peek().id === id)
                break;
            popFromBrowseStack();
        } while(app.currentBrowseStack.length()>0)
    }

    function popFromBrowseStack() {        
        cScrollIndex = app.currentBrowseStack.peek().currentIndex;
        app.currentBrowseStack.pop();
        if(pathListModel.count > 1) {
            pathListModel.remove(0);
            //pathComboBoxIndex = -1;
        } else
            console.log("popFromBrowseStack too often")
    }

    function pushOnBrowseStack(id, pid, title, currentIndex) {
        app.currentBrowseStack.push( {id: id, pid: pid, title: title, currentIndex: currentIndex});
        pathListModel.insert(0, {id: id, pid: pid, title: title});
        //pathComboBoxIndex = -1;
    }

    function addToPlayer(track) {
        getPlayerPage().addTracks([track]);
    }

    function replaceInPlayer(track) {
        getPlayerPage().clearList();
        getPlayerPage().addTracks([track]);
    }

    function getAllTracks() {
        var tracks = [];
        for(var i=0;i<listView.model.count;i++) {
            if(listView.model.get(i).type === "Item")
                tracks.push(listView.model.get(i));
        }
        return tracks;
    }

    function addAllToPlayer() {
        var tracks = getAllTracks();
        getPlayerPage().addTracks(tracks);
    }

    function replaceAllInPlayer() {
        var tracks = getAllTracks();
        getPlayerPage().clearList();
        getPlayerPage().addTracks(tracks);
    }

    /*function createBrowseStackFor(id) {
        var i;

        pushOnBrowseStack("0", "-1", "[Top Level]");
        var pathJson = upnp.getPathJson(id);
        try {
            var path = JSON.parse(pathJson);
            for(i=path.length-1;i>=0;i--)
                pushOnBrowseStack(path[i].id, path[i].pid, path[i].title);
        } catch( err ) {
            app.error("Exception in createBrowseStackFor: " + err);
            app.error("json: " + pathJson);
        }
    }*/

    ConfigurationValue {
            id: max_number_of_results
            key: "/donnie/max_number_of_results"
            defaultValue: 200
    }

}
