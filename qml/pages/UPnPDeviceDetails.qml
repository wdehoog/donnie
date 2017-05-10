/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


import QtQuick 2.0
import Sailfish.Silica 1.0

import org.nemomobile.configuration 1.0

Page {
    id: upnpDetails

    allowedOrientations: Orientation.All

    property var type;
    property var friendlyName;
    property var manufacturer;
    property var modelName;
    property var udn;
    property var urlBase;
    property var deviceType;

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            //height: childRect.height

            PageHeader { title: "Device Details" }

            Text {
                x: Theme.horizontalPageMargin
                text: type + ": " + friendlyName
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
                font.bold: true
                wrapMode: Text.Wrap
            }
            Text {
                x: Theme.horizontalPageMargin
                text: "model: " + modelName
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
                wrapMode: Text.Wrap
            }
            Text {
                x: Theme.horizontalPageMargin
                text: "manufacturer: " + manufacturer
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
                wrapMode: Text.Wrap
            }
            Text {
                x: Theme.horizontalPageMargin
                text: "UDN: " + udn
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
                wrapMode: Text.Wrap
            }
            Text {
                x: Theme.horizontalPageMargin
                text: "URLBase: " + urlBase
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
                wrapMode: Text.Wrap
            }
            Text {
                x: Theme.horizontalPageMargin
                text: "deviceType: " + deviceType
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
                wrapMode: Text.Wrap
            }

        }
    }
}
