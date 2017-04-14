import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.5

import "../UPnP.js" as UPnP

Page {
    id: rendererPage
    property bool rendererPageActive: false
    property string imageItemSource : ""
    property string playIconSource : "image://theme/icon-l-play"
    property int currentItem: -1
    property bool metaShown : false
    property string trackText : ""
    property string albumText : ""

    property bool timeSliderDown: false
    property string timeSliderLabel : ""
    property int timeSliderValue : 0
    property int timeSliderMaximumValue : 0
    property string timeSliderValueText : ""

    property string prevTrackURI: ""
    property int prevTrackDuration: -1
    property int prevTrackTime: -1

    property int volumeSliderValue
    property string muteIconSource : "image://theme/icon-m-speaker"

    property bool useNextURI : false

    function getTransportState() {
        var stateJson = upnp.getTransportInfoJson()
        var tstate = JSON.parse(stateJson);
        return tstate["tpstate"];
    }

    function next() {
        if(currentItem >= (trackListModel.count-1))
            return;
        currentItem++;
        loadTrack();
    }

    function prev() {
        if(currentItem <= 0)
            return;
        currentItem--;
        loadTrack();
    }

    function pause() {
        var tstate = getTransportState();
        if(tstate === "Playing") {
            upnp.pause();
            playIconSource =  "image://theme/icon-l-play";
            cover.playIconSource = "image://theme/icon-cover-play";
        } else {
            play();
        }
    }

    function play() {
        upnp.play();
        var tstate = getTransportState();
        if(tstate === "Playing" || tstate === "Transitioning" ) {
            playIconSource = "image://theme/icon-l-pause";
            cover.playIconSource = "image://theme/icon-cover-pause";
        }
    }

    function stop() {
        upnp.stop();
        playIconSource =  "image://theme/icon-l-play";
        cover.playIconSource = "image://theme/icon-cover-play";
    }

    property int prevVolume;
    function toggleMute() {
        var mute = !upnp.getMute();
        if(mute)
            prevVolume = upnp.getVolume();
        upnp.setMute(mute);
        if(mute)
            muteIconSource =  "image://theme/icon-m-speaker-mute";
        else {
            upnp.setVolume(prevVolume);
            muteIconSource =  "image://theme/icon-m-speaker";
        }
    }

    function onChangedTrack(trackIndex) {
        currentItem = trackIndex;
        var track = trackListModel.get(currentItem);
        if(track.albumArtURI) {
            imageItemSource = track.albumArtURI;
            cover.imageSource = track.albumArtURI;
        } else {
            imageItemSource = "";
            cover.imageSource = "";
        }
        trackText = track.titleText;
        albumText = track.metaText;

        // if available set next track
        if(useNextURI && trackListModel.count > (currentItem+1)) {
            track = trackListModel.get(currentItem+1);
            console.log("onChangedTrack setNextTrack "+track.uri);
            upnp.setNextTrack(track.uri, track.didl);
        }
        console.log("onChangedTrack: index="+trackIndex);
    }

    function loadTrack() {
        var track = trackListModel.get(currentItem);

        prevTrackURI = track.uri;
        prevTrackDuration = -1;
        prevTrackTime = -1;

        console.log("loadTrack " + currentItem + ", "+track.uri);
        upnp.setTrack(track.uri, track.didl);
        if(track.albumArtURI) {
            imageItemSource = track.albumArtURI;
            cover.imageSource = track.albumArtURI;
        } else {
            imageItemSource = "";
            cover.imageSource = "";
        }

        play();
        var tstate = getTransportState();
        if(tstate === "Playing") {
            playIconSource = "image://theme/icon-l-pause";
            cover.playIconSource = "image://theme/icon-cover-pause";
        }

        trackText = track.titleText;
        albumText = track.metaText;

        // if available set next track
        if(useNextURI && trackListModel.count > (currentItem+1)) {
            track = trackListModel.get(currentItem+1);
            console.log("loadTrack setNextTrack "+track.uri);
            upnp.setNextTrack(track.uri, track.didl);
        }
    }

    function clearList(){
        rendererPageActive = false;
        stop();
        listView.model.clear();
        trackText = "";
        albumText = "";
        currentItem = -1;
        imageItemSource = "";

        cover.imageSource = "image://theme/icon-l-pause";
        cover.coverProgressBar.label = "image://theme/icon-l-pause";
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
            id: headerColumn

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

                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Theme.paddingSmall
                  width: parent.width / 2
                  //height: playIcon.height

                  IconButton {
                      anchors.horizontalCenter: parent.horizontalCenter
                      id: playIcon
                      icon.source: playIconSource
                      onClicked: pause()
                  }

                  Row {
                      anchors.horizontalCenter: parent.horizontalCenter

                      IconButton {
                          //anchors.horizontalCenter: parent.horizontalCenter
                          icon.source: "image://theme/icon-m-previous"
                          onClicked: prev()
                      }

                      IconButton {
                          //anchors.horizontalCenter: parent.horizontalCenter
                          icon.source: "image://theme/icon-m-next"
                          onClicked: next()
                      }
                  }

                  IconButton {
                      anchors.horizontalCenter: parent.horizontalCenter
                      //icon.source: "image://theme/icon-m-clear"
                      icon.source: "image://donnie-icons/icon-m-stop"
                      onClicked: stop()
                  }

                }
            }

            Slider {
                id: timeSlider
                enabled: true
                anchors.left: parent.left
                anchors.right: parent.right

                label: timeSliderLabel
                maximumValue: timeSliderMaximumValue
                value: timeSliderValue
                valueText: timeSliderValueText

                onPressedChanged: {
                    timeSliderDown = pressed;
                    console.log("timeSlider onPressedChanged " + pressed);
                }
                onReleased: {
                    console.log("calling seek with " + sliderValue);
                    upnp.seek(sliderValue);
                }
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                //spacing: Theme.paddingSmall
                Slider {
                    id: volumeSlider
                    enabled: true
                    width: parent.width - leftMargin - muteIcon.width
                    //label: "Volume"
                    maximumValue: 100
                    value: volumeSliderValue
                    //valueText:

                    onReleased: {
                        console.log("setVolume "+sliderValue);
                        upnp.setVolume(sliderValue);
                    }
                }
                IconButton {
                    id: muteIcon
                    anchors.rightMargin: Theme.paddingLarge
                    icon.source: muteIconSource
                    onClicked: toggleMute();
                }
            }

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
                    //horizontalCenter: parent.horizontalCenter
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
                loadTrack();
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
                         didl: tracks[i].didl,
                         albumArtURI: tracks[i].albumArtURI,
                         index: idx});
        }
        if(currentItem == -1 && trackListModel.count>0) {
            currentItem = 0;
            loadTrack();
        }

        rendererPageActive = true;

        // hacked in here
        volumeSliderValue = upnp.getVolume();
    }

    // Adds leading zeros to number
    function zeroPad(number, digits) {
        var num = number + "";
        while(num.length < digits) {
            num= '0' + num;
        }
        return num;
    }

    // Formatduration like HH:mm:ss / m:ss / 0:ss
    function formatDuration(duration /* track duration in seconds */) {
        duration = Math.round(duration);

        var seconds = duration % 60;
        var totalMinutes = (duration - seconds) / 60;
        var minutes = totalMinutes % 60;
        var hours = (totalMinutes - minutes) / 60;

        return (hours > 0 ? hours + ":" : "")
                + (minutes > 0 ? (hours > 0 ? zeroPad(minutes, 2) : minutes) + ":" : "0:")
                + zeroPad(seconds, 2);
    }

    function getTrackIndexForURI(uri) {
        var i;
        for(i=0;i<trackListModel.count;i++) {
            var track = trackListModel.get(i);
            if(track.uri === uri)
                return i;
        }
        return -1;
    }

    Timer {
        interval: 1000;
        running: rendererPageActive;
        repeat: true
        onTriggered: {

            // read time to update ui and detect track changes

            // {"abscount":"9080364","abstime":"27","relcount":"9080364","reltime":"27","trackduration":"378"}
            var pinfoJson = upnp.getPositionInfoJson();
            console.log(pinfoJson);
            var pinfo = JSON.parse(pinfoJson);

            //var stateJson = upnp.getTransportInfoJson()
            //var tstate = JSON.parse(stateJson);
            //console.log(stateJson);

            var trackuri = pinfo["trackuri"];
            var trackduration = parseInt(pinfo["trackduration"]);
            var tracktime = parseInt(pinfo["reltime"]);

            // track duration
            timeSliderLabel = formatDuration(trackduration);
console.log("setting timeSliderLabel to "+timeSliderLabel + " based on " + trackduration);
            //cover.coverProgressBar.label = timeSliderLabel;

            if(timeSliderMaximumValue !== trackduration && trackduration > -1) {
                timeSliderMaximumValue = trackduration;
console.log("setting timeSliderMaximumValue to "+timeSliderMaximumValue)
                cover.coverProgressBar.maximumValue = trackduration;
            }

            // Check User is using the slider, if so don't update the value
            if(!timeSliderDown) {

                // value
                timeSliderValue = tracktime;
                cover.coverProgressBar.value = tracktime;
console.log("setting timeSliderValue to "+tracktime)
                timeSliderValueText = formatDuration(tracktime);
console.log("setting timeSliderValueText to "+timeSliderValueText)
                if(currentItem > -1)
                  cover.coverProgressBar.label = (currentItem+1) + " of " + trackListModel.count + " - " + timeSliderValueText;
                else
                  cover.coverProgressBar.label = ""

            }

            // how to detect track change? uri will mostly work
            // but not when a track appears twice and next to each other.
            // upplay has a nifty solution but I am too lazy now.
            // (maybe we should start using upplay's avtransport_qo.h etc.)
            if(useNextURI) {

                if(prevTrackURI !== trackuri) {
                    console.log("uri changed from ["+prevTrackURI + "] to [" + trackuri + "]");
                    var trackIndex = getTrackIndexForURI(trackuri);
                    if(trackIndex >=0 )
                        onChangedTrack(trackIndex);
                }
                //if(tstate["tpstate"] === "Playing" || tstate["tpstate"] === "Transitioning") {
                       // we have to load the next track ourselves
                       //if(trackListModel.count > (currentItem+1)) {
                       //    currentItem++;
                       //    loadTrack();
                       //}
                       //console.log("Missed track change.");
                //}
            } else {
              if(tracktime == 0 && pinfo["abstime"] == 0 && prevTrackTime > 0) {

                   var stateJson = upnp.getTransportInfoJson()
                   console.log(stateJson);
                   var tstate = JSON.parse(stateJson);

                   // still playing?
                   if(tstate["tpstate"] === "Stopped")
                      next();

               }
            }

            //
            prevTrackURI = trackuri;
            prevTrackDuration = trackduration;
            prevTrackTime = tracktime;
        }
    }

}
