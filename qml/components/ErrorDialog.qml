import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property string errorMessageText : ""

    id: errorDialog
    canAccept: true

    allowedOrientations: Orientation.All

    //onAccepted: {
    //}

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            //height: childRect.height

            PageHeader { title: "Error" }

            TextArea {
                id: logTextArea
                width: parent.width
                readOnly: true
                text: errorMessageText
            }
        }

        VerticalScrollDecorator{}
    }
}
