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
import Sailfish.Media 1.0               // for MediaKey
import QtMultimedia 5.5
import org.nemomobile.policy 1.0        // for Permissions
import org.nemomobile.configuration 1.0 // for ConfigurationValue

import "../UPnP.js" as UPnP

Page {
    id: rendererPage
    //property bool rendererPageActive: false
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
    property int prevAbsTime: -1

    property int volumeSliderValue
    property string muteIconSource : "image://theme/icon-m-speaker"

    property bool useNextURI : use_setnexturi.value
    property bool hasTracks : listView.model.count > 0

    property bool canNext: hasTracks && (currentItem < (listView.model.count - 1))
    property bool canPrevious: hasTracks && (currentItem > 0)
    property bool canPlay: hasTracks && transportState != 1
    property bool canPause: transportState == 1

    // 1 playing, 2 paused, the rest inactive
    property int transportState : -1

    // state initiated by the app. not the actual state
    property bool playing : false

    function refreshTransportState() {
        var newState;
        var tstate = getTransportState();
        if(tstate === "Playing")
            newState = 1;
        else if(tstate === "PausedPlayback")
            newState = 2;
        else
            newState = -1;
        transportState = newState;
        //console.log("RTS: count:" + trackListModel.count+", currentItem"+currentItem+", hasTracks: "+hasTracks+", canNext: "+canNext)
        app.notifyTransportState(transportState);
    }

    function getPositionInfo() {
        // {"abscount":"9080364","abstime":"27","relcount":"9080364","reltime":"27","trackduration":"378"}
        var pinfoJson = upnp.getPositionInfoJson();
        //console.log(pinfoJson);
        try {
            return JSON.parse(pinfoJson);
        } catch(err) {
            app.error("Exception in getPositionInfo: "+err);
            app.error("json: " + pinfoJson);
        }
    }

    function getTransportState() {
        // {"curspeed":"1","tpstate":"Playing","tpstatus":"OK"}
        var stateJson = upnp.getTransportInfoJson()
        try {
            var tstate = JSON.parse(stateJson);
            return tstate["tpstate"];
        } catch(err) {
            app.error("Exception in getTransportState: "+err);
            app.error("json: " + stateJson);
        }
    }

    function getMediaInfo() {
        var mediaInfoJson = upnp.getMediaInfoJson();
        try {
            return JSON.parse(mediaInfoJson);
        } catch(err) {
            app.error("Exception in getMediaInfo: "+err);
            app.error("json: " + mediaInfoJson);
        }
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
        playing = true;
        // VISIT we also get "Stopped" here
        //var tstate = getTransportState();
        //if(tstate === "Playing" || tstate === "Transitioning" ) {
            playIconSource = "image://theme/icon-l-pause";
            cover.playIconSource = "image://theme/icon-cover-pause";
        //} else
        //    console.log("play() unexpected tstate: "+tstate);
    }

    function stop() {
        playing = false;
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

    function updateUIForTrack(track) {
        if(track.albumArtURI) {
            imageItemSource = track.albumArtURI;
            cover.imageSource = track.albumArtURI;
        } else {
            imageItemSource = "";
            cover.imageSource = "";
        }
        trackText = track.titleText;
        albumText = track.metaText;
    }

    function updateMprisForTrack(track) {
        // mpris
        var meta = {};
        meta.Title = track.title;
        meta.Artist = track.artist;
        meta.Album = track.album;
        meta.Length = track.duration * 1000000; // s -> us
        meta.ArtUrl = track.albumArtURI;
        //meta.TrackNumber = track.???;
        app.updateMprisMetaData(meta);
    }

    function onChangedTrack(trackIndex) {
        currentItem = trackIndex;
        var track = trackListModel.get(currentItem);
        updateUIForTrack(track);
        updateMprisForTrack(track);

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

        prevTrackURI = "";
        prevTrackDuration = -1;
        prevTrackTime = -1;

        console.log("loadTrack " + currentItem + ", "+track.uri);
        upnp.setTrack(track.uri, track.didl);

        updateUIForTrack(track);
        updateMprisForTrack(track);

        play();

        // if available set next track
        if(useNextURI && trackListModel.count > (currentItem+1)) {
            track = trackListModel.get(currentItem+1);
            console.log("loadTrack setNextTrack "+track.uri);
            upnp.setNextTrack(track.uri, track.didl);
        }
    }

    function clearList() {
        //rendererPageActive = false;
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
                          enabled: canPrevious
                          onClicked: prev()
                      }

                      IconButton {
                          //anchors.horizontalCenter: parent.horizontalCenter
                          icon.source: "image://theme/icon-m-next"
                          enabled: canNext
                          onClicked: next()
                      }
                  }

                  IconButton {
                      anchors.horizontalCenter: parent.horizontalCenter
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
                handleVisible: false;

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
                    handleVisible: false;
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

        delegate: ListItem {
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
                loadTrack();
            }
        }

    }

    Connections {
        target: upnp
        onMprisControl: {
            console.log("onMprisControl: " + action);
            switch(action) {
            case "Play":
                pause();
                break;
            case "Pause":
                pause();
                break;
            case "Next":
                next();
                break;
            case "Previous":
                prev();
                break;
            }
        }
    }

    function increaseVolume() {
        // max is 100
        if(volumeSliderValue <= 95)
            volumeSliderValue = volumeSliderValue + 5;
        else
            volumeSliderValue = 100;
        upnp.setVolume(volumeSliderValue);
    }

    function decreaseVolume() {
        // max is 100
        if(volumeSliderValue >= 5)
            volumeSliderValue = volumeSliderValue - 5;
        else
            volumeSliderValue = 0;
        upnp.setVolume(volumeSliderValue);
    }

    MediaKey {
        enabled: volumeKeysResource.acquired
        key: Qt.Key_VolumeUp
        onPressed: increaseVolume()
    }

    MediaKey {
        enabled: volumeKeysResource.acquired
        key: Qt.Key_VolumeDown
        onPressed: decreaseVolume()
    }

    // needed for Volume Keys
    Permissions {
        enabled: true
        autoRelease: true
        applicationClass: "player"

        Resource {
            id: volumeKeysResource
            //type: Resource.ScaleButton
            type: Resource.HeadsetButtons
            optional: true
        }
    }

    //onStatusChanged: {
        //if(status !== PageStatus.Active)
        //    return;
    //}

    function addTracksNoStart(tracks) {
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
                         title: tracks[i].title,
                         artist: tracks[i].artist,
                         duration: tracks[i].duration,
                         album: tracks[i].album});
        }
    }

    function addTracks(tracks) {
        addTracksNoStart(tracks);
        if(currentItem == -1 && trackListModel.count > 0) {
            currentItem = 0;
            loadTrack();
        }

        //rendererPageActive = true;
    }

    onStatusChanged: {
        if(status == PageStatus.Active) {
            if(app.hasCurrentRenderer())
                volumeSliderValue = upnp.getVolume();

            if(!hasTracks) {
                var minfo = getMediaInfo();
                if(minfo !== undefined) {
                    var track;
                    if(minfo["curmeta"] !== undefined
                       && minfo["curmeta"].id !== "") {
                        track = UPnP.createTrack(minfo["curmeta"])
                        addTracksNoStart([track]);
                        updateUIForTrack(track);
                        updateMprisForTrack(track);
                    }
                    if(minfo["nextmeta"] !== undefined
                            && minfo["nextmeta"].id !== "")
                        track = UPnP.createTrack(minfo["nextmeta"])
                        addTracksNoStart([track]);
                }
            }

        }
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

    function loadNextTrack() {
        // still playing? then do not start next track
        var tstate = getTransportState();
        if(tstate === "Stopped")
           next();
    }

    property int failedAttempts: 0

    Timer {
        interval: 1000;
        //running: rendererPageActive;
        running: app.hasCurrentRenderer()
        repeat: true
        onTriggered: {

            // read time to update ui and detect track changes

            refreshTransportState();

            // {"abscount":"9080364","abstime":"27","relcount":"9080364","reltime":"27","trackduration":"378"}
            var pinfo = getPositionInfo();
            if(pinfo === undefined) {
                failedAttempts++;
                app.error("Error: getPositionInfo() failed")
                if(failedAttempts > 3) {
                    stop();
                    app.error("Error: STOP due to too many failed attempts");
                }
                return;
            } else
                failedAttempts = 0;

            var trackuri = pinfo["trackuri"];
            var trackduration = parseInt(pinfo["trackduration"]);
            var tracktime = parseInt(pinfo["reltime"]);
            var abstime = parseInt(pinfo["abstime"]);

            // track duration
            timeSliderLabel = UPnP.formatDuration(trackduration);
            //console.log("setting timeSliderLabel to "+timeSliderLabel + " based on " + trackduration);
            //cover.coverProgressBar.label = timeSliderLabel;

            if(timeSliderMaximumValue != trackduration && trackduration > -1) {
                timeSliderMaximumValue = trackduration;
                //console.log("setting timeSliderMaximumValue to "+timeSliderMaximumValue)
                cover.coverProgressBar.maximumValue = trackduration;
            }

            // Check User is using the slider, if so don't update the value
            if(!timeSliderDown) {

                // value
                timeSliderValue = tracktime;
                cover.coverProgressBar.value = tracktime;
                //console.log("setting timeSliderValue to "+tracktime)
                timeSliderValueText = UPnP.formatDuration(tracktime);
                //console.log("setting timeSliderValueText to "+timeSliderValueText)
                if(currentItem > -1)
                  cover.coverProgressBar.label = (currentItem+1) + " of " + trackListModel.count + " - " + timeSliderValueText;
                else
                  cover.coverProgressBar.label = ""

            }

            // how to detect track change? uri will mostly work
            // but not when a track appears twice and next to each other.
            // upplay has a nifty solution but I am too lazy now.
            // (maybe we should start using upplay's avtransport_qo.h etc.)
            if(playing) {

                if(prevTrackURI !== "" && prevTrackURI !== trackuri) {

                    // track changed
                    console.log("uri changed from ["+prevTrackURI + "] to [" + trackuri + "]");
                    var trackIndex = getTrackIndexForURI(trackuri);
                    if(trackIndex >= 0)
                        onChangedTrack(trackIndex);
                    else if(trackuri === "") // no setNextAVTransportURI support?
                        loadNextTrack();

                } else if(tracktime === 0
                          && abstime === prevAbsTime
                          && prevTrackTime > 0) {

                    // stopped playing so load next track
                    loadNextTrack();

                }

            }

            //
            prevTrackURI = trackuri;
            prevTrackDuration = trackduration;
            prevTrackTime = tracktime;
            prevAbsTime = abstime;
        }
    }

    ConfigurationValue {
            id: use_setnexturi
            key: "/donnie/use_setnexturi"
            defaultValue: "false"
    }
}
