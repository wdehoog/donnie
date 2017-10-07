import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property string confirmMessageText : ""

    id: confirmDialog
    canAccept: true

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader { title: "Confirm" }

            TextArea {
                id: msgTextArea
                width: parent.width
                readOnly: true
                text: confirmMessageText
            }

        }

        VerticalScrollDecorator{}
    }
}
