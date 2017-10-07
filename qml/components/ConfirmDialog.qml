import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    property string confirmMessageText : ""
    property string titleText : "Confirm"

    id: confirmDialog
    canAccept: true

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader { title: titleText }

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
