/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.5
import Sailfish.Silica 1.0

import "../UPnP.js" as UPnP

CoverBackground {
    id: cover

    property string defaultImageSource : app.getAppIconSource2(Theme.iconSizeLarge)
    property string imageSource : defaultImageSource
    property string playIconSource : "image://theme/icon-cover-play"
    //property alias coverProgressBar : coverProgressBar
    property string labelText : ""

    Column {
        width: parent.width

        //anchors.topMargin: Theme.paddingMedium
        //anchors.top: parent.top + Theme.paddingMedium
        // nothing works. try a filler...
        Rectangle {
            width: parent.width
            height: Theme.paddingMedium
            opacity: 0
        }

        Item {
            width: parent.width - (Theme.paddingMedium * 2)
            height: width
            x: Theme.paddingMedium

            Image {
                id: image
                width: imageSource === defaultImageSource ? sourceSize.width : parent.width
                height: width
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                source: imageSource
            }
        }

        Text {
            id: label
            anchors.left: parent.left
            anchors.right: parent.right
            text: labelText.length > 0 ? labelText : qsTr("Donnie")
            horizontalAlignment: Text.AlignHCenter
            visible: imageSource === defaultImageSource
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.primaryColor

            NumberAnimation on x {
                from: parent.width
                to: -1 * label.width
                loops: Animation.Infinite
                duration: 3000
            }
        }

        ProgressBar {
            id: progressBar
            valueText: ""
            anchors.left: parent.left
            anchors.right: parent.right
        }

        CoverActionList {
            id: coverAction

            CoverAction {
                iconSource: "image://theme/icon-cover-previous"              
                onTriggered: app.prev()
            }

            CoverAction {
                iconSource: playIconSource
                onTriggered: app.pause()
            }

            CoverAction {
                iconSource: "image://theme/icon-cover-next"
                onTriggered: app.next()
            }

        }
    }

    function resetDisplayData() {
        imageSource = defaultImageSource
        playIconSource = "image://theme/icon-cover-play"
        labelText = ""
        progressBar.label = ""
        progressBar.value = 0
    }

    function updateDisplayData(imageSource, text, trackClass) {
        cover.imageSource = imageSource ? imageSource : defaultImageSource
        labelText = text
        if(trackClass === UPnP.AudioItemType.AudioBroadcast) {
            progressBar.label = ""
            progressBar.value = 0
        }
    }

    function updatePlayIcon(imageSource) {
        cover.playIconSource = imageSource
    }

    function updateProgressBar(value, maximumValue, label) {
        progressBar.value = value
        progressBar.maximumValue = maximumValue
        progressBar.label = label
    }
}


