import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.5

import "../UPnP.js" as UPnP

Page {
    id: playerPage

    property bool playerPageActive: false
    property alias audio: audio
    property string imageItemSource : ""
    property string playIconSource : "image://theme/icon-l-play"
    property int currentItem: -1
    property bool metaShown : false
    property string trackText
    property string albumText

    Audio {
        id: audio

        autoPlay: true;

        onStatusChanged: {
            if(audio.status == Audio.Loaded && audio.position == 0) {
                //updateTrackInformation()
            }

            if(audio.status == Audio.EndOfMedia) {
                next();
            }
        }

    }

    //Playlist { only available in 5.8
    //            id: playlist
    //}

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
            audio.pause();
            playIconSource =  "image://theme/icon-l-play";
            cover.playIconSource = "image://theme/icon-cover-play";
        } else {
            play();
        }
    }

    function play() {
        audio.play();
        if(audio.playbackState == Audio.PlayingState) {
            playIconSource = "image://theme/icon-l-pause";
            cover.playIconSource = "image://theme/icon-cover-pause";
        }
    }

    function stop() {
        audio.stop();
        playIconSource =  "image://theme/icon-l-play";
        cover.playIconSource = "image://theme/icon-cover-play";
    }

    function loadTrack(track) {
        //audio.stop();
        audio.source = track.uri;
        imageItemSource = track.albumArtURI;
        cover.imageSource = track.albumArtURI;
        //audio.play();
        if(audio.playbackState == Audio.PlayingState) {
            playIconSource = "image://theme/icon-l-pause";
            cover.playIconSource = "image://theme/icon-cover-pause";
        }

        trackText = track.titleText;
        albumText = track.metaText;
    }

    function clearList(){
        playerPageActive = false;
        stop();
        audio.source = "";
        listView.model.clear();
        trackText = "";
        albumText = "";
        currentItem = -1;
        imageItemSource = "";

        cover.imageSource = "";
        cover.coverProgressBar.label = ""
    }

    SilicaListView {
        id: listView
        model: trackListModel
        width: parent.width
        anchors.fill: parent

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
                      onClicked: next()
                  }
                }
            }

            Slider {
                id: timeSlider
                maximumValue: 1
                enabled: true

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
                            cover.coverProgressBar.maximumValue = audio.duration;
                        }

                        // Update the value text
                        var seconds = Math.floor((timeSlider.value / 1000) % 60);

                        if (seconds < 10)
                            seconds = "0" + seconds;
                        var minutes = Math.floor((timeSlider.value / 1000) / 60);
                        timeSlider.valueText = minutes + ":" + seconds;

                        if(currentItem > -1)
                          cover.coverProgressBar.label = (currentItem+1) + " of " + trackListModel.count + " - " + minutes + ":" + seconds;
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

        }

        VerticalScrollDecorator {}

        ListModel {
            id: trackListModel
        }

        delegate: BackgroundItem {
            id: delegate
            width: parent.width

            Column {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: durationLabel.left
                    rightMargin: Theme.paddingMedium
                    horizontalCenter: parent.horizontalCenter
                }

                Label {
                    color: currentItem === index ? Theme.highlightColor : Theme.primaryColor
                    textFormat: Text.StyledText
                    //truncationMode: TruncationMode.Fade
                    width: parent.width
                    text: titleText
                }

                Label {
                    color: currentItem === index ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: metaText
                    textFormat: Text.StyledText
                    //truncationMode: TruncationMode.Fade
                    width: parent.width
                }
            }

            Label {
                id: durationLabel

                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    top: parent.top
                    topMargin: Theme.paddingSmall
                    //bottomMargin: Theme.paddingSmall
                }

                color: currentItem === index ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: durationText
            }


            onClicked: {
                currentItem = index;
                var track = trackListModel.get(index);
                loadTrack(track);
            }
        }

    }

    //onStatusChanged: {
        //if(status !== PageStatus.Active)
        //    return;
    //}

    function addTracks(tracks) {
        var i;
        for(i=0;i<tracks.length;i++) {
            var idx = trackListModel.count;
            var durationText = "";
            if(tracks[i].duration)
              durationText = UPnP.getDurationString(tracks[i].duration);
            var titleText = tracks[i].title;
            var metaText  = tracks[i].artist + " - " + tracks[i].album;
            trackListModel.append(
                        {id: tracks[i].id,
                         titleText: titleText,
                         metaText: metaText,
                         durationText: durationText,
                         uri: tracks[i].uri,
                         albumArtURI: tracks[i].albumArtURI,
                         index: idx});
        }
        if(currentItem == -1 && trackListModel.count>0) {
            next();
        }
        playerPageActive = true;
    }

    // Adds leading zeros to number
    function zeroPad(number, digits) {
        var num = number + "";
        while(num.length < digits) {
            num= '0' + num;
        }
        return num;
    }

    // Format track duration to format like HH:mm:ss / m:ss / 0:ss
    function formatTrackDuration(trackDuration /* track duration in milliseconds */) {
        trackDuration = Math.round(parseInt(trackDuration) / 1000);

        var seconds = trackDuration % 60;
        var totalMinutes = (trackDuration - seconds) / 60;
        var minutes = totalMinutes % 60;
        var hours = (totalMinutes - minutes) / 60;

        return (hours > 0 ? hours + ":" : "")
                + (minutes > 0 ? (hours > 0 ? zeroPad(minutes, 2) : minutes) + ":" : "0:")
                + zeroPad(seconds, 2);
    }

}
