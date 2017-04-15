import QtQuick 2.0
import Sailfish.Silica 1.0

import org.nemomobile.configuration 1.0

Page {
    id: settingsPage

    allowedOrientations: Orientation.All

    ConfigurationValue {
            id: search_window
            key: "/donnie/search_window"
            defaultValue: 10
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) {
            swField.text = search_window.value;
        } else if (status === PageStatus.Deactivating) {
            search_window.value = swField.text;
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            //height: childRect.height

            PageHeader { title: "Settings" }

            TextField {
                id: swField
                label: "How long to search for UPnp Devices (seconds)"
                inputMethodHints: Qt.ImhDigitsOnly
                width: parent.width
            }

        }
    }

}

