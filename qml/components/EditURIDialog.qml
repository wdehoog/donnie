import QtQuick 2.0
import Sailfish.Silica 1.0

import "../UPnP.js" as UPnP

Dialog {
    property string titleText: ""

    property alias uri : uriTextArea.text
    property alias label : labelTextArea.text
    property string streamType : UPnP.AudioType.MusicTrack

    id: editURIDialog
    canAccept: true

    allowedOrientations: Orientation.All

    /*onStatusChanged: {
        if (status === PageStatus.Activating) {
        }
    }*/

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader { title: titleText }

            TextField {
                id: uriTextArea
                placeholderText: label
                label: qsTr("URI")
                width: parent.width
                //text: uri
            }

            TextField {
                id: labelTextArea
                placeholderText: label
                label: qsTr("Title")
                width: parent.width
                //text: label
            }

            ComboBox {
                 label: qsTr("Stream Type")
                 description: qsTr("Type of stream the URI referes to")

                 currentIndex: {
                     if(streamType === UPnP.AudioType.AudioBroadcast)
                         return 1
                     return 0
                 }

                 menu: ContextMenu {
                     MenuItem {
                         text: qsTr("Music Track")
                         onClicked: streamType = UPnP.AudioType.MusicTrack
                     }
                     MenuItem {
                         text: qsTr("Audio Broadcast")
                         onClicked: streamType = UPnP.AudioType.AudioBroadcast
                     }
                 }
             }
        }

        VerticalScrollDecorator{}
    }
}

