/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


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
    property int maxCount: max_number_of_results.value
    property int totalCount
    property bool allowContainers : search_allow_containers.value
    property var searchResults
    property var searchCapabilities: []
    property int selectedSearchCapabilitiesMask: selected_search_capabilities.value
    property var scMap: []
    property string groupByField: groupby_search_results.value

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
            var searchQuery = UPnP.createUPnPQuery(searchString, searchCapabilities, selectedSearchCapabilitiesMask, allowContainers);
            showBusy = true;
            upnp.search(searchQuery, 0, maxCount);
            //console.log("search start="+startIndex);
        } else
            searchModel.clear();
    }

    function searchMore(start) {
        if(searchString.length < 1 || selectedSearchCapabilitiesMask == 0)
            return;
        var searchQuery = UPnP.createUPnPQuery(searchString, searchCapabilities, selectedSearchCapabilitiesMask, allowContainers);
        showBusy = true;
        startIndex = start;
        upnp.search(searchQuery, start, maxCount);
        //console.log("search start="+startIndex);
    }

    Connections {
        target: upnp
        onSearchDone: {
            var i;

            try {
                searchResults = JSON.parse(searchResultsJson);

                // containers
                for(i=0;i<searchResults.containers.length;i++) {
                    var container = searchResults.containers[i];
                    searchModel.append(UPnP.createListContainer(container));
                }

                // items
                for(i=0;i<searchResults.items.length;i++) {
                    var item = searchResults.items[i];
                    if(UPnP.startsWith(item.properties["upnp:class"], "object.item.audioItem")) {
                        searchModel.append(UPnP.createListItem(item));
                    } else
                        console.log("onSearchDone: skipped loading of an object of class " + item.properties["upnp:class"]);
                }

                totalCount = searchResults["totalCount"];

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
                    text: qsTr("Load More")
                    enabled: searchString.length >= 1
                             && selectedSearchCapabilitiesMask > 0
                             && searchModel.count < totalCount
                    onClicked: searchMore(startIndex+maxCount);
                }
            }

            PushUpMenu {
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
                        scMap[c] = u;

                        c++;
                    }

                    // the selected
                    value = "";
                    for(var i=0;i<scMap.length;i++) {
                        if(selectedSearchCapabilitiesMask & (0x01 << scMap[i])) {
                            var first = value.length == 0;
                            value = value + (first ? "" : ", ") + items.get(i).name;
                            indexes.push(i);
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
                        } else {
                            value = "";
                            var tmp = [];
                            selectedSearchCapabilitiesMask = 0;
                            for(var i=0;i<indexes.length;i++) {
                                value = value + ((i>0) ? ", " : "") + items.get(indexes[i]).name;
                                selectedSearchCapabilitiesMask |= (0x01 << scMap[indexes[i]]);
                            }
                        }
                        selected_search_capabilities.value = selectedSearchCapabilitiesMask;
                        selected_search_capabilities.sync();
                    })
                }

            }

            /* Group by */
            ComboBox {
                id: groupBy
                width: parent.width
                label: "Group By"
                currentIndex: {
                    if(groupby_search_results.value === "album")
                        return 0;
                    if(groupby_search_results.value === "artist")
                        return 1;
                    if(groupby_search_results.value === "title")
                        return 2;
                    return -1;
                }
                menu: ContextMenu {
                    MenuItem {
                        text: "Album"
                        onClicked: {
                            groupby_search_results.value = "album";
                            groupby_search_results.sync();
                        }
                    }
                    MenuItem {
                        text: "Artist"
                        onClicked: {
                            groupby_search_results.value = "artist";
                            groupby_search_results.sync();
                        }
                    }
                    MenuItem {
                        text: "Title"
                        onClicked: {
                            groupby_search_results.value = "title";
                            groupby_search_results.sync();
                        }
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
                        visible: listView.model.get(index).type === "Item"
                        onClicked: addToPlayer(listView.model.get(index).id);
                    }
                    MenuItem {
                        text: "Add Group To Player"
                        visible: listView.model.get(index).type === "Item"
                        onClicked: addGroupToPlayer(groupByField, listView.model.get(index)[groupByField]);
                    }
                    MenuItem {
                        text: "Add All To Player"
                        visible: listView.model.get(index).type === "Item"
                        onClicked: addAllToPlayer();
                    }
                    // minidlna and minimserver give complete collection as parent
                    // so browsing that is useless (and for some reason does not work)
                    //MenuItem {
                    //    text: "Browse (experimental)"
                    //    onClicked: openBrowseOn(listView.model.get(index).pid);
                    //}
                }
            }
        }

        VerticalScrollDecorator {}

    }

    function getTrack(id) {
        var i;

        for(i=0;i<searchResults.items.length;i++) {
            if(searchResults.items[i].id === id) {
                var track = UPnP.createTrack(searchResults.items[i]);
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
            id: max_number_of_results
            key: "/donnie/max_number_of_results"
            defaultValue: 200
    }
    ConfigurationValue {
            id: search_allow_containers
            key: "/donnie/search_allow_containers"
            defaultValue: false
    }
    ConfigurationValue {
            id: selected_search_capabilities
            key: "/donnie/selected_search_capabilities"
            defaultValue: 0xFFF
    }
    ConfigurationValue {
            id: groupby_search_results
            key: "/donnie/groupby_search_results"
            defaultValue: "album"
    }
}
