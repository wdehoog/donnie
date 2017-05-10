/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
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
            msrField.text = max_number_of_results.value
            allowContainers.checked = search_allow_containers.value
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
                label: "Maximum number of results per request"
                inputMethodHints: Qt.ImhDigitsOnly
                width: parent.width
                onTextChanged: {
                    max_number_of_results.value = text;
                    max_number_of_results.sync();
                }
            }

            TextSwitch {
                id: allowContainers
                text: "Allow Containers"
                description: "Also show Containers in search results"
                checked: search_allow_containers.value
                onCheckedChanged: {
                    search_allow_containers.value = checked;
                    search_allow_containers.sync();
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
            id: max_number_of_results
            key: "/donnie/max_number_of_results"
            defaultValue: 200
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

    ConfigurationValue {
            id: search_allow_containers
            key: "/donnie/search_allow_containers"
            defaultValue: false
    }
}

