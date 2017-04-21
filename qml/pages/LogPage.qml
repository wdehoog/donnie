import QtQuick 2.0
import Sailfish.Silica 1.0

import org.nemomobile.configuration 1.0

Page {
    id: logPage
    property string logText : ""

    allowedOrientations: Orientation.All


    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            //height: childRect.height

            PageHeader { title: "Log" }

            TextArea {
                id: logTextArea
                width: parent.width
                readOnly: true
                text: logText
            }
        }

        VerticalScrollDecorator{}
    }

}

