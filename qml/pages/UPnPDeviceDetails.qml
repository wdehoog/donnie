/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
