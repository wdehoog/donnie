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

    ConfigurationValue {
            id: use_setnexturi
            key: "/donnie/use_setnexturi"
            defaultValue: "false"
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
                label: "How long to search for UPnp Devices (sec)"
                inputMethodHints: Qt.ImhDigitsOnly
                width: parent.width
            }

            /*TextSwitch {
                id: useNextURI
                text: "Gapless"
                description: "Use setNextAVTransportURI"
                checked: use_setnexturi.value === "true"
                onCheckedChanged: {
                    use_setnexturi.value = checked ? "true" : "false";
                    use_setnexturi.sync();
                }
            }*/
        }
    }

}

