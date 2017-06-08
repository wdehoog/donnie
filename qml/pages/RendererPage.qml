/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
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
    property string defaultImageSource : "image://theme/icon-l-music"
    property string imageItemSource : defaultImageSource
    property string playIconSource : "image://theme/icon-l-play"
    property int currentItem: -1
    property bool metaShown : false
    property string trackText : ""
    property string albumText : ""

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

    function refreshTransportState(tstate) {
        var newState;
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

    /*function getPositionInfo() {
        var pinfoJson = upnp.getPositionInfoJson();
        //console.log(pinfoJson);
        try {
            return JSON.parse(pinfoJson);
        } catch(err) {
            app.error("Exception in getPositionInfo: "+err);
            app.error("json: " + pinfoJson);
        }
    }*/

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
            var r;
            if((r = upnp.pause()) !== 0) {
                app.showErrorDialog("Failed to Pause the Renderer");
                return;
            }
            playIconSource =  "image://theme/icon-l-play";
            cover.playIconSource = "image://theme/icon-cover-play";
        } else {
            play();
        }
    }

    function play() {
        var r;
        if((r = upnp.play()) !== 0) {
            // rygel: 701 means not "Stopped" nor "Paused" so assume already playing
            if(r !== 701) {
                app.showErrorDialog("Failed to Start the Renderer");
                return;
            }
        }
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
        var r;
        if((r = upnp.stop()) !== 0) {
            app.showErrorDialog("Failed to Stop to Renderer");
            //return;
        }
        playing = false;
        playIconSource =  "image://theme/icon-l-play";
        cover.playIconSource = "image://theme/icon-cover-play";
    }

    function reset() {
        playing = false;
        playIconSource =  "image://theme/icon-l-play";
        cover.playIconSource = "image://theme/icon-cover-play";
    }

    function setVolume(volume) {
        var r;
        if((r = upnp.setVolume(volume)) !== 0) {
            app.showErrorDialog("Failed to set volume on Renderer");
        }
    }

    function setMute(mute) {
        var r;
        if((r = upnp.setMute(mute)) !== 0) {
            app.showErrorDialog("Failed to mute/unmute Renderer");
        }
    }

    property int prevVolume;
    function toggleMute() {
        var mute = !upnp.getMute();
        if(mute)
            prevVolume = upnp.getVolume();
        setMute(mute);
        if(mute)
            muteIconSource =  "image://theme/icon-m-speaker-mute";
        else {
            setVolume(prevVolume);
            muteIconSource =  "image://theme/icon-m-speaker";
        }
    }

    function updateUIForTrack(track) {
        if(track.albumArtURI) {
            imageItemSource = track.albumArtURI;
            cover.imageSource = track.albumArtURI;
        } else {
            imageItemSource = defaultImageSource;
            cover.imageSource = cover.defaultImageSource;
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
        var track = trackListModel.get(currentItem)

        prevTrackURI = ""
        prevTrackDuration = -1
        prevTrackTime = -1

        console.log("loadTrack " + currentItem + ", "+track.uri)
        var r
        if((r = upnp.setTrack(track.uri, track.didl)) !== 0) {
            app.showErrorDialog("Failed to set track to play on Renderer")
            return
        }

        updateUIForTrack(track)
        updateMprisForTrack(track)

        if(!playing)
            play()

        // if available set next track
        if(useNextURI && trackListModel.count > (currentItem+1)) {
            track = trackListModel.get(currentItem+1)
            console.log("loadTrack setNextTrack "+track.uri)
            upnp.setNextTrack(track.uri, track.didl)
        }
    }

    function clearList() {
        //rendererPageActive = false;
        stop();
        listView.model.clear();
        trackText = "";
        albumText = "";
        currentItem = -1;
        imageItemSource = defaultImageSource;

        cover.imageSource = cover.defaultImageSource;
        cover.coverProgressBar.label = "";
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
                property int position: timeSliderValue
                property string positionText: timeSliderValueText

                enabled: true
                anchors.left: parent.left
                anchors.right: parent.right
                handleVisible: false;

                label: timeSliderLabel
                maximumValue: timeSliderMaximumValue

                onPositionChanged: {
                    if (!pressed)
                        value = position
                }

                onPositionTextChanged: {
                    if (!pressed)
                        valueText = positionText
                }

                onReleased: {
                    console.log("calling seek with " + sliderValue);
                    refreshState = 5
                    positionInfo = undefined
                    upnp.seek(sliderValue);
                    updateSlidersProgress(sliderValue);
                    upnp.getPositionInfoJsonAsync()
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
                        setVolume(sliderValue);
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

    property var transportInfo
    property var mediaInfo
    property var positionInfo

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

        onTransportInfo: {
            //console.log("onTransportInfo: " + transportInfoJson)
            try {
                transportInfo = JSON.parse(transportInfoJson)
                refreshTransportState(transportInfo["tpstate"])
            } catch(err) {
                app.error("Exception in onTransportInfo: "+err)
                app.error("json: " + transportInfoJson)
            }
            refreshState = 2
        }

        // On receiving position info parse and set the data
        // It seems that a renderer can send position 0 after a seek
        // this position info is then ignored
        //
        // {"abscount":"9080364","abstime":"27",
        //  "relcount":"9080364","reltime":"27",
        //  "trackduration":"378","trackuri":"http....."}
        onPositionInfo: {
            //console.log("OnPositionInfo: refreshState:" + refreshState + ", json:" + positionInfoJson)
            if(refreshState == 5) { // ignore first positionInfo after a seek
                refreshState = 6
                return
            }
            try {
                positionInfo = JSON.parse(positionInfoJson)
                console.log(positionInfoJson)

                if(refreshState == 6) {
                    // ignore positionInfo after a seek having abs/reltime == 0
                    // the value is useless and it would make the slider jump back and forth
                    if(positionInfo["reltime"] == 0
                       && positionInfo["abstime"] == 0
                       && positionInfo["trackuri"] === prevTrackURI) {
                        positionInfo = undefined
                        return
                    }
                }

            } catch(err) {
                app.error("Exception in onPositionInfo: "+err)
                app.error("json: " + positionInfoJson)
            }
            refreshState = 4
        }

        onMediaInfo: {
            //console.log("onMediaInfo: " + mediaInfoJson)
            try {
                mediaInfo = JSON.parse(mediaInfoJson)
            } catch(err) {
                app.error("Exception in onMediaInfo: "+err)
                app.error("json: " + mediaInfoJson)
            }
        }

        onError: {
            switch(refreshState) {
            case 1:
                refreshState = 2
                break
            case 3:
            case 5:
            case 6:
                refreshState = 4
                break
            }
        }
    }

    function increaseVolume() {
        // max is 100
        if(volumeSliderValue <= 95)
            volumeSliderValue = volumeSliderValue + 5;
        else
            volumeSliderValue = 100;
        setVolume(volumeSliderValue);
    }

    function decreaseVolume() {
        // max is 100
        if(volumeSliderValue >= 5)
            volumeSliderValue = volumeSliderValue - 5;
        else
            volumeSliderValue = 0;
        setVolume(volumeSliderValue);
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

    MediaKey {
        enabled: true
        key: Qt.Key_ToggleCallHangup
        onReleased: pause()
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

    function addTracksNoStart(tracks) {
        var i;
        for(i=0;i<tracks.length;i++)
            trackListModel.append(tracks[i])
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
                volumeSliderValue = upnp.getVolume()

            if(!hasTracks) {
                var minfo = getMediaInfo();
                if(minfo !== undefined) {
                    var track
                    if(minfo["curmeta"] !== undefined
                       && minfo["curmeta"].id !== "") {
                        track = UPnP.createListItem(minfo["curmeta"])
                        addTracksNoStart([track])
                        updateUIForTrack(track)
                        updateMprisForTrack(track)
                    }
                    if(minfo["nextmeta"] !== undefined
                            && minfo["nextmeta"].id !== "") {
                        track = UPnP.createListItem(minfo["nextmeta"])
                        addTracksNoStart([track])
                    }
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

    // testing
    /*Timer {
        interval: 5000;
        running: app.hasCurrentRenderer()
        repeat: true
        onTriggered: {
            var minfo = getMediaInfo();
            if(minfo !== undefined) {
                if(minfo["curmeta"] !== undefined) {
                    console.log(minfo["curmeta"]);
                }
            }
        }
    }*/

    function updateSlidersProgress(value) {
        //console.log("updateSlidersProgress value:"+value)
        timeSliderValue = value
        timeSliderValueText = UPnP.formatDuration(value)
        cover.coverProgressBar.value = value
    }

    function updateCoverProgress() {
        if(currentItem > -1)
          cover.coverProgressBar.label = (currentItem+1) + " of " + trackListModel.count + " - " + timeSliderValueText
        else
          cover.coverProgressBar.label = ""
    }

    // 0 - inactive
    // 1 - transportInfo requested
    // 2 - transportInfo received
    // 3 - positionInfo requested
    // 4 - positionInfo received
    // 5 - ignore after seek has been called
    // 6 - check vor valid times after seek has been called
    property int refreshState: 0

    property int skipRefresh: 1
    property int failedAttempts: 0
    property int stoppedPlayingDetection: 0
    Timer {
        interval: 1000;
        running: app.hasCurrentRenderer()
        repeat: true
        onTriggered: {

            // check and trigger update of transport state and position info
            switch(refreshState) {
            case 0:
            case 4:
                upnp.getTransportInfoJsonAsync()
                refreshState = 1
                break
            case 2:
                upnp.getPositionInfoJsonAsync()
                refreshState = 3
                break
            case 1:
            case 3:
                // do nothing
                break
            case 5:
            case 6:
                // in state 5/6 positionInfo can be skipped so does need to be refreshed
                // to get a good one asap
                upnp.getPositionInfoJsonAsync()
                // while seeking it is of no use to update the player info so bail out
                return
            }

            // do not refresh all info every second but do show progress
            skipRefresh++
            if(skipRefresh>1) {
                if(transportState === 1) {
                    updateSlidersProgress(timeSliderValue + 1)
                    updateCoverProgress()
                }
                skipRefresh = 0
                return
            }

            /* Disabled since it is triggered too soon
              if(playing && transportState <= 0) { // detect renderer has stopped unexpectedly
                stoppedPlayingDetection++
                if(stoppedPlayingDetection > 3) {
                    playing = false
                    playIconSource =  "image://theme/icon-l-play"
                    cover.playIconSource = "image://theme/icon-cover-play"
                    app.showErrorDialog("The renderer has stopped playing unexpectedly.")
                }
            } else
                stoppedPlayingDetection = 0
            */

            // update ui and detect track changes
            var pinfo = positionInfo
            positionInfo = undefined // use only once
            if(pinfo === undefined) {
                if(refreshState >= 5) // 5 & 6 skip positionInfo
                    return
                failedAttempts++
                if(failedAttempts > 3) {
                    reset()
                    var errTxt = "Lost connection with Renderer."
                    app.error(errTxt)
                    app.showErrorDialog(errTxt)
                }
                return
            } else
                failedAttempts = 0

            var trackuri = pinfo["trackuri"]
            var trackduration = parseInt(pinfo["trackduration"])
            var tracktime = parseInt(pinfo["reltime"])
            var abstime = parseInt(pinfo["abstime"])

            // track duration
            timeSliderLabel = UPnP.formatDuration(trackduration)
            //console.log("setting timeSliderLabel to "+timeSliderLabel + " based on " + trackduration);
            //cover.coverProgressBar.label = timeSliderLabel;

            if(timeSliderMaximumValue != trackduration && trackduration > -1) {
                timeSliderMaximumValue = trackduration
                cover.coverProgressBar.maximumValue = trackduration
            }

            updateSlidersProgress(tracktime)
            updateCoverProgress()

            // how to detect track change? uri will mostly work
            // but not when a track appears twice and next to each other.
            // upplay has a nifty solution but I am too lazy now.
            // (maybe we should start using upplay's avtransport_qo.h etc.)
            if(playing) {

                if(prevTrackURI !== "" && prevTrackURI !== trackuri) {

                    // track changed
                    console.log("uri changed from ["+prevTrackURI + "] to [" + trackuri + "]");
                    var trackIndex = getTrackIndexForURI(trackuri)
                    if(trackIndex >= 0)
                        onChangedTrack(trackIndex)
                    else if(trackuri === "") { // no setNextAVTransportURI support?
                        if(transportInfo["tpstate"] === "Stopped")
                           next();
                    }

                } else if(tracktime === 0
                          && abstime === prevAbsTime
                          && prevTrackTime > 0) {

                    // stopped playing so load next track
                    if(transportInfo["tpstate"] === "Stopped")
                       next();

                }

            }

            //
            prevTrackURI = trackuri
            prevTrackDuration = trackduration
            prevTrackTime = tracktime
            prevAbsTime = abstime
        }
    }

    ConfigurationValue {
            id: use_setnexturi
            key: "/donnie/use_setnexturi"
            defaultValue: "false"
    }
}
