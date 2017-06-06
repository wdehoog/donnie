/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.5
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    property string defaultImageSource : "image://theme/icon-l-music"
    property string imageSource : defaultImageSource
    property string playIconSource : "image://theme/icon-cover-play"
    property alias coverProgressBar : coverProgressBar

    Column {
        width: parent.width

        //anchors.topMargin: Theme.paddingMedium
        //anchors.top: parent.top + Theme.paddingMedium
        // nothing works. try a filler...
        Rectangle {
            width: parent.width
            height:Theme.paddingMedium
            opacity: 0
        }

        Label {
            anchors.left: parent.left
            anchors.right: parent.right
            id: label
            text: qsTr("Donnie")
            horizontalAlignment: Text.AlignHCenter
            visible: imageSource.toString().length == 0
        }

        Image {
            id: image
            width: parent.width - (Theme.paddingMedium * 2)
            height: parent.width - (Theme.paddingMedium * 2)
            //anchors.topMargin: Theme.paddingMedium
            //anchors.top: parent.top + Theme.paddingMedium
            anchors.horizontalCenter: parent.horizontalCenter
            source: imageSource
        }

        ProgressBar {
            id: coverProgressBar
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
}


