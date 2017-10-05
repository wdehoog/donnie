/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.5

import "../UPnP.js" as UPnP

Page {
    id: playerPage

    property bool playerPageActive: false
    property alias audio: audio
    property string defaultImageSource : "image://theme/icon-l-music"
    property string imageItemSource : defaultImageSource
    property string playIconSource : "image://theme/icon-l-play"
    property int currentItem: -1
    property bool metaShown : false
    property string trackClass

    property string trackMetaText1 : ""
    property string trackMetaText2 : ""

    property bool hasTracks : listView.model.count > 0
    property bool canNext: hasTracks && (currentItem < (listView.model.count - 1))
    property bool canPrevious: hasTracks && (currentItem > 0)
    property bool canPlay: hasTracks && (audio.playbackState != audio.PlayingState)
    property bool canPause: audio.playbackState == audio.PlayingState

    // 1 playing, 2 paused, the rest inactive
    property int transportState : -1

    function refreshTransportState() {
        var newState;
        if(audio.playbackState == Audio.PlayingState)
            newState = 1;
        else if(audio.playbackState == Audio.PausedState)
            newState = 2;
        else
            newState = -1;
        transportState = newState;
        //console.log("RTS: count:" + listView.model.count+", currentItem"+currentItem+", hasTracks: "+hasTracks+", canNext: "+canNext)
        app.notifyTransportState(transportState);
    }

    Audio {
        id: audio

        autoLoad: true;
        autoPlay: false;

        onStatusChanged: {
            if(audio.status == Audio.Loaded && audio.position == 0) {
                //updateTrackInformation()
            }

            if(audio.status == Audio.EndOfMedia) {
                next();
            }

        }

        onPlaybackStateChanged: refreshTransportState()
        onSourceChanged: refreshTransportState()
        onBufferProgressChanged: {
            if(bufferProgress == 1.0) {
                play()
                updateIcons()
            }
        }
    }

    function next() {
        if(currentItem >= (trackListModel.count-1))
            return;
        currentItem++;
        loadTrack(trackListModel.get(currentItem));
    }

    function prev() {
        if(currentItem <= 0)
            return;
        currentItem--;
        loadTrack(trackListModel.get(currentItem));
    }

    function pause() {
        if(audio.playbackState == Audio.PlayingState) {
            audio.pause()
            updateIcons()
        } else {
            play()
        }
    }

    function play() {
        audio.play()
        updateIcons()
    }

    function stop() {
        audio.stop()
        updateIcons()
    }

    function loadTrack(track) {
        //audio.stop();
        audio.source = track.uri
        if(track.albumArtURI) {
            imageItemSource = track.albumArtURI
            cover.imageSource = track.albumArtURI
        } else {
            imageItemSource = defaultImageSource
            cover.imageSource = cover.defaultImageSource
        }
        updateIcons()

        trackMetaText1 = track.titleText
        trackMetaText2 = track.metaText
        trackClass = track.upnpclass;

        updateMprisForTrack(track);
        app.saveLastPlayingJSON(track, trackListModel)
    }

    function clearList() {
        playerPageActive = false
        stop()
        audio.source = ""
        listView.model.clear()
        trackMetaText1 = ""
        trackMetaText2 = ""
        trackClass = ""
        currentItem = -1
        imageItemSource = defaultImageSource

        cover.imageSource = cover.defaultImageSource
        cover.coverProgressBar.label = ""
    }

    function updateIcons() {
        if(audio.playbackState == Audio.PlayingState) {
            playIconSource = "image://theme/icon-l-pause";
            cover.playIconSource = "image://theme/icon-cover-pause";
        } else {
            playIconSource =  "image://theme/icon-l-play";
            cover.playIconSource = "image://theme/icon-cover-play";
        }
    }

    function updateMprisForTrackMetaData(track) {
        var meta = {};
        meta.Title = trackMetaText1;
        meta.Artist = trackMetaText2;
        meta.Album = track.album;
        meta.Length = 0;
        meta.ArtUrl = track.albumArtURI;
        meta.TrackNumber = currentItem;
        app.updateMprisMetaData(meta);
    }

    function updateMprisForTrack(track) {
        var meta = {};
        meta.Title = trackMetaText1;
        meta.Artist = trackMetaText2;
        meta.Album = track.album;
        meta.Length = track.duration * 1000; // ms -> us
        meta.ArtUrl = track.albumArtURI;
        meta.TrackNumber = currentItem;
        app.updateMprisMetaData(meta);
    }

    SilicaListView {
        id: listView
        model: trackListModel
        width: parent.width
        anchors.fill: parent
        anchors.margins: Theme.paddingMedium

        PullDownMenu {
            MenuItem {
                text: qsTr("Empty List")
                onClicked: {
                    clearList();
                }
            }
        }

        header: Column {
            width: parent.width
            anchors.bottomMargin: Theme.paddingLarge

            Rectangle {
                width: parent.width
                height:Theme.paddingLarge
                opacity: 0
            }

            Row {

                width: parent.width

                Rectangle {
                    width: Theme.paddingLarge
                    height: parent.height
                    opacity: 0
                }

                Image {
                    id: imageItem
                    source: imageItemSource
                    width: parent.width / 2
                    height: width
                    fillMode: Image.PreserveAspectFit
                }

                Column {
                  id: playerButtons
                  //property int currentPlayerState: Audio.Pl

                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Theme.paddingMedium
                  width: parent.width / 2
                  //height: playIcon.height

                  IconButton {
                      anchors.horizontalCenter: parent.horizontalCenter
                      icon.source: "image://theme/icon-m-previous"
                      enabled: canPrevious
                      onClicked: prev()
                  }

                  IconButton {
                      anchors.horizontalCenter: parent.horizontalCenter
                      id: playIcon
                      icon.source: playIconSource
                      onClicked: pause()
                  }

                  IconButton {
                      anchors.horizontalCenter: parent.horizontalCenter
                      icon.source: "image://theme/icon-m-next"
                      enabled: canNext
                      onClicked: next()
                  }
                }
            }

            Rectangle {
                width: parent.width
                height:Theme.paddingMedium
                opacity: 0
            }

            Slider { // for tracks
                id: timeSlider
                maximumValue: 1
                handleVisible: false
                enabled: !UPnP.isBroadcast(getCurrentTrack())

                anchors.left: parent.left
                anchors.right: parent.right

                label: UPnP.getDurationString(audio.duration)

                onReleased: {
                    audio.seek(sliderValue);
                }
            }

            Timer {
                id: updateTimer

                running: playerPageActive
                interval: 1000
                repeat: true

                onTriggered: {
                     if(timeSlider !== null) {

                        // slider on this page and progress bar on cover page
                        if(timeSlider.maximumValue != audio.duration) {
                            timeSlider.maximumValue = audio.duration;
                            timeSlider.label = formatTrackDuration(audio.duration)
                            cover.coverProgressBar.maximumValue = audio.duration;
                        }

                        timeSlider.valueText = formatTrackDuration(timeSlider.value);

                        if(currentItem > -1)
                          cover.coverProgressBar.label = (currentItem+1) + " of " + trackListModel.count + " - " + timeSlider.valueText
                        else
                          cover.coverProgressBar.label = ""

                        // User is using the slider, don't update the value
                        if(timeSlider.down) {
                            return;
                        }

                        timeSlider.value = audio.position;
                        cover.coverProgressBar.value = audio.position;
                    }
                }

            }

// player controls in a row
//            Row {
//              id: playerButtons
//              //property int currentPlayerState: Audio.Pl

//              anchors.horizontalCenter: parent.horizontalCenter
//              //spacing: 38
//              height: playIcon.height

//              IconButton {
//                  icon.source: "image://theme/icon-m-previous"
//                  onClicked: prev()
//              }

//              IconButton {
//                  id: playIcon
//                  icon.source: playIconSource
//                  onClicked: pause()
//              }

//              IconButton {
//                  icon.source: "image://theme/icon-m-next"
//                  onClicked: next()
//              }
//            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right

                Text {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeMedium
                    color:  Theme.highlightColor
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    text: trackMetaText1
                }
                Text {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.secondaryHighlightColor
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    text: trackMetaText2
                }
            }

            Separator {
                anchors.left: parent.left
                anchors.right: parent.right
                color: "white"
            }
        }

        VerticalScrollDecorator {}

        ListModel {
            id: trackListModel
            onCountChanged: refreshTransportState()
        }

        delegate: ListItem {
            id: delegate
            width: parent.width
            anchors.margins: Theme.paddingMedium

            Column {
                width: parent.width

                Item {
                    width: parent.width
                    height: tt.height

                    Label {
                        id: tt
                        color: currentItem === index ? Theme.highlightColor : Theme.primaryColor
                        textFormat: Text.StyledText
                        truncationMode: TruncationMode.Fade
                        width: parent.width - dt.width
                        text: titleText
                    }

                    Label {
                        id: dt
                        anchors.right: parent.right
                        color: currentItem === index ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: durationText
                    }
                }

                Label {
                    color: currentItem === index ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    textFormat: Text.StyledText
                    truncationMode: TruncationMode.Fade
                    width: parent.width
                    visible: metaText ? metaText.length > 0 : false
                    text: metaText
                }

            }

            menu: contextMenu

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        text: "Remove"
                        onClicked: {
                            var saveIndex = index;
                            trackListModel.remove(index);
                            if(currentItem === saveIndex) {
                                currentItem--;
                                next();
                            } else if(currentItem > saveIndex)
                                currentItem--;
                        }
                    }
                }
            }

            onClicked: {
                currentItem = index;
                var track = trackListModel.get(index);
                loadTrack(track);
            }
        }

    }

    // for internet radio the QT Audio object seems to support some metadata
    Timer {
        interval: 5000;
        running: useBuiltInPlayer && audio.hasAudio && trackClass === "object.item.audioItem.audioBroadcast"
        repeat: true
        onTriggered: {
            var title = audio.metaData.title
            var publisher = audio.metaData.publisher

            /*if(title !== undefined)
                albumText = title;
            if(publisher !== undefined)
                trackText = publisher;*/

            if(title === undefined)
                return
            trackMetaText1 = title
            trackMetaText2 = publisher
            updateMprisForTrackMetaData(getCurrentTrack())
        }
    }

    /*Component.onDestruction: {
        console.debug("Destruction of PlayerPage")
        safeLastPlayingInfo()
    }*/

    function safeLastPlayingInfo() {
        console.debug("PlayerPage safeLastPlayingInfo")
        //mainPage.saveLastPlayingJSON(getCurrentTrack(), audio.position, trackListModel)
    }

    //onStatusChanged: {
        //if(status !== PageStatus.Active)
        //    return;
    //}

    function addTracks(tracks) {
        var i;
        for(i=0;i<tracks.length;i++)
            trackListModel.append(tracks[i])
        if(currentItem == -1 && trackListModel.count>0) {
            if(arguments.length >= 2 && arguments[1] > -1)
                currentItem = arguments[1] - 1 // next will do +1
            next();        
        }
        playerPageActive = true;
    }

    function getCurrentTrack() {
        if(currentItem < 0 || currentItem >= trackListModel.count)
            return undefined
        return trackListModel.get(currentItem)
    }

    // Format track duration to format like HH:mm:ss / m:ss / 0:ss
    function formatTrackDuration(trackDuration /* track duration in milliseconds */) {
        return UPnP.formatDuration(Math.round(parseInt(trackDuration) / 1000));
    }

}
