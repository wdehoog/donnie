import QtQuick 2.0

import QtQuick 2.0
import Sailfish.Silica 1.0

import org.nemomobile.configuration 1.0

import "../UPnP.js" as UPnP

Page {
    id: searchPage

    property bool keepSearchFieldFocus: true
    property bool showBusy: false;
    property string searchString: ""
    property int startIndex: 0
    property int maxCount: max_search_results.value
    property int totalCount
    property var searchResults
    property var searchCapabilities: []
    //property var selectedSearchCapabilities: []
    property int selectedSearchCapabilitiesMask
    property var scMap: []
    property string groupByField: "album"

    onSearchStringChanged: {
        typeDelay.restart()
    }

    Timer {
        id: typeDelay
        interval: 1000
        running: false
        repeat: false
        onTriggered: refresh()
    }

    onSelectedSearchCapabilitiesMaskChanged: refresh()

    function refresh() {
        if(searchString.length >= 1 && selectedSearchCapabilitiesMask > 0) {
            var searchQuery = UPnP.createUPnPQuery(searchString, searchCapabilities, selectedSearchCapabilitiesMask);
            showBusy = true;
            upnp.search(searchQuery, 0, maxCount);
            console.log("search start="+startIndex);
        } else
            searchModel.clear();
    }

    function searchMore(start) {
        if(searchString.length < 1 || selectedSearchCapabilitiesMask == 0)
            return;
        var searchQuery = UPnP.createUPnPQuery(searchString, searchCapabilities, selectedSearchCapabilitiesMask);
        showBusy = true;
        startIndex = start;
        upnp.search(searchQuery, start, maxCount);
        console.log("search start="+startIndex);
    }

    Connections {
        target: upnp
        onSearchDone: {
            var i;

            try {
                searchResults = JSON.parse(searchResultsJson);

                //searchModel.clear();

                /* for now containers are skipped (query is also filtering them out?)
                 */

                for(i=0;i<searchResults.items.length;i++) {
                    var item = searchResults.items[i];
                    // query already takes care of this and .startsWith( throws an error
                    // Property 'startsWith( of object ... is not a function
                    //if(item.properties["upnp:class"]
                    //   && item.properties["upnp:class"].startsWith("object.item.audioItem")) {
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
                    //} else
                    //    console.log("onSearchDone: skipped loading of an object of class " + item.properties["upnp:class"]);
                }

                totalCount = searchResults["totalCount"];
                console.log("result totalCount="+totalCount+" model.count="+searchModel.count+", results.length="+searchResults.items.length);
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

            PullDownMenu {
                /*MenuItem {
                    text: qsTr("Add All To Player")
                    onClicked: addAllToPlayer()
                }*/
                MenuItem {
                    text: qsTr("Load More")
                    enabled: searchString.length >= 1
                             && selectedSearchCapabilitiesMask > 0
                             && searchModel.count < totalCount
                    onClicked: searchMore(startIndex+maxCount);
                }
                MenuItem {
                    text: qsTr("Load Next Set")
                    enabled: searchString.length >= 1
                             && selectedSearchCapabilitiesMask > 0
                             && (startIndex + searchModel.count) < totalCount
                    onClicked: {
                        searchModel.clear();
                        searchMore(startIndex+maxCount);
                    }
                }
                MenuItem {
                    text: qsTr("Load Previous Set")
                    enabled: searchString.length >= 1
                             && selectedSearchCapabilitiesMask > 0
                             && startIndex >= maxCount
                    onClicked: {
                        searchModel.clear();
                        searchMore(startIndex-maxCount);
                    }
                }
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

            /* Which fields to search in */
            ValueButton {
                property var indexes: []
                width: parent.width

                label: "Search In"

                ListModel {
                    id: items
                }

                Component.onCompleted: {
                    var c = 0;
                    value = "None"
                    indexes = []
                    items.clear()

                    // load capabilities
                    for (var u=0;u<searchCapabilities.length;u++) {
                        var scapLabel = UPnP.geSearchCapabilityDisplayString(searchCapabilities[u]);
                        if(scapLabel === undefined)
                            continue;

                        items.append( {id: c, name: scapLabel });
                        indexes.push(c);
                        scMap[c] = u;

                        c++;
                    }

                    // initially all are selected
                    if (indexes.length > 0) {
                        value = "";
                        for(var i=0;i<indexes.length;i++) {
                            value = value + ((i>0) ? ", " : "") + items.get(indexes[i]).name;
                            selectedSearchCapabilitiesMask |= 0x01 << scMap[indexes[i]];
                        }
                    }
                }

                onClicked: {
                    var ms = pageStack.push(Qt.resolvedUrl("../components/MultiItemPicker.qml"), { items: items, label: label, indexes: indexes } );
                    ms.accepted.connect(function() {
                        indexes = ms.indexes.sort(function (a, b) { return a - b });
                        selectedSearchCapabilitiesMask = 0;
                        if (indexes.length == 0) {
                            value = "None";
                            //delete selectedSearchCapabilities;
                        } else {
                            value = "";
                            var tmp = [];
                            selectedSearchCapabilitiesMap = 0;
                            for (var i=0 ; i<indexes.length ; i++) {
                                value = value + ((i>0) ? ", " : "") + items.get(indexes[i]).name;
                                //var tmpitem = {};
                                //tmpitem.label = items.get(indexes[i]).name;
                                //tmpitem.id = items.get(indexes[i]).id;
                                //tmp.push(tmpitem);
                                selectedSearchCapabilitiesMask |= 0x01 << scMap[indexes[i]];
                            }
                            //selectedSearchCapabilities = tmp;
                        }
                    })
                }

            }

            /* Group by */
            ComboBox {
                id: groupBy
                width: parent.width
                label: "Group By"
                currentIndex: 0
                menu: ContextMenu {
                    MenuItem {
                        text: "Album"
                        onClicked: groupByField = "album"
                    }
                    MenuItem {
                        text: "Artist"
                        onClicked: groupByField = "artist"
                    }
                    MenuItem {
                        text: "Title"
                        onClicked: groupByField = "title"
                    }
                }
            }
        }

        section.property : groupByField
        section.delegate : Component {
            id: sectionHeading
            Item {
                width: parent.width
                height: childrenRect.height

                Text {
                    text: section
                    font.bold: true
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.highlightColor
                }
            }
        }

        delegate: ListItem {
            id: delegate
            //height: Math.max(imageItem.height, label.height) makes it too small
            Row {
                spacing: Theme.paddingMedium
                width: parent.width

                Column {
                    width: parent.width

                    Item {
                        width: parent.width
                        height: tt.height

                        Label {
                            id: tt
                            color: Theme.primaryColor
                            textFormat: Text.StyledText
                            truncationMode: TruncationMode.Fade
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
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }
                }

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
                        text: "Add Group To Player"
                        onClicked: addGroupToPlayer(groupByField, listView.model.get(index)[groupByField]);
                    }
                    MenuItem {
                        text: "Add All To Player"
                        onClicked: addAllToPlayer();
                    }
                    MenuItem {
                        text: "Browse (experimental)"
                        onClicked: openBrowseOn(listView.model.get(index).pid);
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

        for(i=0;i<searchResults.items.length;i++) {
            if(searchResults.items[i].id === id) {
                var track = createTrack(id, searchResults.items[i]);
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

    function addGroupToPlayer(field, value) {
        var tracks = [];

        for(var i=0;i<listView.model.count;i++) {
            var track = getTrack(listView.model.get(i).id);
            if(track !== undefined
               && track[field] === value)
                tracks.push(track);
        }

        getPlayerPage().addTracks(tracks);
    }

    function addAllToPlayer() {
        var tracks = [];

        for(var i=0;i<listView.model.count;i++) {
            var track = getTrack(listView.model.get(i).id);
            if(track !== undefined)
                tracks.push(track);
        }

        getPlayerPage().addTracks(tracks);
    }

    function openBrowseOn(id) {
        pageStack.pop();
        mainPage.openBrowsePage(id);
    }

    ConfigurationValue {
            id: max_search_results
            key: "/donnie/max_search_results"
            defaultValue: 100
    }

}
