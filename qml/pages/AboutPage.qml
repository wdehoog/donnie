/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: qsTr("About")
            }

            Item {
                width: parent.width
                height: childrenRect.height

                Image {
                    id: icon

                    anchors.horizontalCenter: parent.horizontalCenter
                    asynchronous: true
                    source: app.getAppIconSource()
                }

                Column {
                    id: appTitleColumn

                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        top: icon.bottom
                        topMargin: Theme.paddingMedium
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeLarge
                        text: "Donnie 0.8"
                    }

                    Label {
                        horizontalAlignment: Text.AlignHCenter
                        text: qsTr("UPnP control point and player for Sailfish OS")
                        width: parent.width
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        //: I doubt this needs to be translated
                        text: qsTr("Copyright ") + "(C) 2018 Willem-Jan de Hoog"
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }
                    Label {
                        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        text: qStr("License: MIT")
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }
                }

            }

            SectionHeader {
                text: qsTr("Translations")
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                text:
"Carlos Gonzalez"
            }

            SectionHeader {
                text: qsTr("Thanks to")
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                text:
"carlosgonz: " + qsTr("testing and UI rigor") + "\n"
"J.F.Dockes: upplay & libupnpp" + "\n"
"equeim: unplayer" + "\n"
"jabbounet: upnpplayer" + "\n"
"kimmoli: IconProvider & MultiItemPicker" + "\n"
"Morpog: icon shape"
            }
        }

        VerticalScrollDecorator { }
    }
}
