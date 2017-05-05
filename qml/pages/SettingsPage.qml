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
    id: settingsPage

    allowedOrientations: Orientation.All


    onStatusChanged: {
        if (status === PageStatus.Activating) {
            swField.text = search_window.value;
            msrField.text = max_search_results.value
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
                onTextChanged: {
                    search_window.value = text;
                    search_window.sync();
                }
            }

            TextField {
                id: msrField
                label: "Maximum number of search results"
                inputMethodHints: Qt.ImhDigitsOnly
                width: parent.width
                onTextChanged: {
                    max_search_results.value = text;
                    max_search_results.sync();
                }
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

            /*TextSwitch {
                id: logPage
                text: "Log Page"
                description: "Show Open Log Page button"
                checked: show_open_logpage.value === "true"
                onCheckedChanged: {
                    show_open_logpage.value = checked ? "true" : "false";
                    show_open_logpage.sync();
                }
            }*/
        }
    }

    ConfigurationValue {
            id: search_window
            key: "/donnie/search_window"
            defaultValue: 10
    }

    ConfigurationValue {
            id: max_search_results
            key: "/donnie/max_search_results"
            defaultValue: 100
    }

    ConfigurationValue {
            id: use_setnexturi
            key: "/donnie/use_setnexturi"
            defaultValue: "false"
    }

    ConfigurationValue {
            id: show_open_logpage
            key: "/donnie/show_open_logpage"
            defaultValue: "false"
    }

}

