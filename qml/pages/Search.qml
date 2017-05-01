import QtQuick 2.0

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../UPnP.js" as UPnP

Page {
    id: searchPage

    property bool keepSearchFieldFocus: true
    property bool showBusy: false;
    property string searchString: ""
    property int startIndex: 0
    property int maxCount: 50
    property var searchResults

    onSearchStringChanged: {
        if(searchString.length>=3) {
            var query;
            query  = "upnp:artist contains \"" + searchString + "\"";
            query += "or dc:creator contains \"" + searchString + "\"";
            showBusy = true;
            upnp.search(query, 0, maxCount);
        }
    }

    Connections {
        target: upnp
        onSearchDone: {
            var i;

            try {
                searchResults = JSON.parse(searchResultsJson);

                searchModel.clear();

                /*for(i=0;i<searchResults.containers.length;i++) {
                    var container = searchResults.containers[i];
                    searchModel.append({
                        type: "Container",
                        id: container["id"],
                        pid: container["pid"],
                        title: container["title"],
                        artist: "", album: "", duration: ""
                    });
                }*/

                for(i=0;i<searchResults.items.length;i++) {
                    var item = searchResults.items[i];
                    if(item.properties["upnp:class"] === "object.item.audioItem.musicTrack") {
                        var durationText = "";
                        if(item.resources[0].attributes["duration"])
                          durationText = UPnP.getDurationString(item.resources[0].attributes["duration"]);
                        var titleText = item["title"];
                        var metaText  = item.properties["dc:creator"] + " - " + item.properties["upnp:album"];
                        searchModel.append({
                            type: "Item",
                            id: item["id"],
                            titleText: titleText,
                            metaText: metaText,
                            durationText: durationText,
                            pid: item["pid"],
                            title: item["title"],
                            artist: item.properties["dc:creator"],
                            album: item.properties["upnp:album"],
                            duration: item.resources[0].attributes["duration"]
                        });
                    } else
                        console.log("onSearchDone: skipped loading of an object of class " + item.properties["upnp:class"]);
                }

            } catch( err ) {
                app.error("Exception in onSearchDone: " + err);
                app.error("json: " + searchResultsJson);
            }

            showBusy = false;
        }

        onError: {
            console.log("Search::onError: " + msg);
            app.errorLog.push(msg);
            showBusy = false;
        }
    }

    ListModel {
        id: searchModel
    }

    SilicaListView {
        id: listView
        model: searchModel
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
                title: qsTr("Search")
                BusyIndicator {
                    id: busyThingy
                    parent: pHeader.extraContent
                    anchors.left: parent.left
                    running: showBusy;
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            SearchField {
                id: searchField
                width: parent.width
                placeholderText: "Search text"
                Binding {
                    target: searchPage
                    property: "searchString"
                    value: searchField.text.toLowerCase().trim()
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
                width: parent.width

                /*Image {
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
                }*/

                Column {
                    width: parent.width

                    Item {
                        width: parent.width
                        height: tt.height

                        Label {
                            id: tt
                            color: Theme.primaryColor
                            textFormat: Text.StyledText
                            //truncationMode: TruncationMode.Fade
                            width: parent.width - dt.width
                            //anchors.right: dt.left
                            text: titleText
                        }
                        Label {
                            id: dt
                            //anchors.left: tt.right
                            anchors.right: parent.right
                            color: Theme.secondaryColor
                            text: durationText
                        }
                    }

                    Label {
                        color: Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: metaText
                        textFormat: Text.StyledText
                        //truncationMode: TruncationMode.Fade
                        width: parent.width
                    }
                }

//                Label {
//                    id: titleLabel
//                    //anchors.leftMargin: Theme.paddingLarge
//                    anchors.verticalCenter: parent.verticalCenter
//                    color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
//                    text: title;
//                }

//                Label {
//                    id: metaLabel
//                    font.pixelSize: Theme.fontSizeExtraSmall
//                    anchors.baseline: titleLabel.baseline
//                    //anchors {
//                    //    right: parent.right
//                    //    rightMargin: Theme.horizontalPageMargin
//                        //bottom: parent.bottom
//                        //bottomMargin: Theme.paddingSmall
//                    //}
//                    text: duration ? UPnP.getDurationString(model.duration) : "";
//                }

            }
            menu: contextMenu

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        text: "Add To Player"
                        //enabled: listView.model.get(index).type === "Item"
                        onClicked: addToPlayer(listView.model.get(index).id);
                    }
                    MenuItem {
                        text: "Add All To Player"
                        onClicked: addAllToPlayer();
                    }
                }
            }
            onClicked: {
//                var item = listView.model.get(index);
//                if(item.pid === "-2") // the ".." item
//                    popFromBrowseStack();
//                else if(item.type === "Container")
//                    pushOnBrowseStack(item.id, item.pid, item.title);
//                if(item.type !== "Item")
//                  cid = item.id;
            }

        }

        VerticalScrollDecorator {}

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
