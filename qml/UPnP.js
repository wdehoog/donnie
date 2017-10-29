/**
 * Donnie. Copyright (C) 2017 Willem-Jan de Hoog
 *
 * License: MIT
 */


.pragma library

var NetworkState = {
    Unknown: 1,
    Connected: 2,
    Disconnected: 3
}

var dataStructures = {
    Stack : function() {
        var elements = [];
        this.push = function(element) {
            return elements.push(element);
        }
        this.pop = function() {
            return elements.pop();
        }
        this.peek = function(element) {
            return elements[elements.length - 1];
        }
        this.empty = function() {
            return elements.length === 0;
        }
        this.elements = function() {
            return elements;
        }
        this.length = function() {
            return elements.length;
        }
    },

    Fifo : function() {
        var elements = [];
        this.push = function(element) {
            return elements.push(element);
        }
        this.shift = function(element) {
            return elements.shift();
        }
        this.empty = function() {
            return elements.length === 0;
        }
        this.elements = function() {
            return elements;
        }
        this.length = function() {
            return elements.length;
        }
    }
}

function secondsString(seconds) {
    var sstr = "0" + seconds;
    return sstr.substr(-2);
}

function getDurationString(d) {
    if(typeof d === 'string' || d instanceof String) {
        // probably: hh:mm:ss.xxx
        var a = d.split(':');
        if(a.length !== 3)
            return d;
        if(parseInt(a[0])>0)
            return a[0]+":"+a[1]+":"+secondsString(Math.round(parseInt(a[2])));
        else
            return a[1]+":"+secondsString(Math.round(parseInt(a[2])));
    } else {
      // assume ms
      d /= 1000;
      var minutes = Math.floor(d / 60);
      var seconds = "0" + (d - minutes * 60);
      return minutes + ":" + seconds.substr(-2);
    }
}

function repeatChar(count, ch) {
    if (count == 0) {
        return "";
    }
    var count2 = count / 2;
    var result = ch;

    // double the input until it is long enough.
    while (result.length <= count2) {
        result += result;
    }
    // use substring to hit the precise length target without
    // using extra memory
    return result + result.substring(0, count - result.length);
}

function getPathString(browseStack, id) {
    var pathString = "";
    var elements = browseStack.elements();
    for(var i=0; i<elements.length;i++) {
        pathString += elements[i].title;
        if(elements[i].id === id)
            break;
        if(i<(elements.length-1))
            pathString += "/";
    }
    return pathString;
}

function getCurrentPathString(browseStack) {
    var pathString = "";
    var elements = browseStack.elements();
    for(var i=0; i<elements.length;i++) {
        pathString += elements[i].title;
        if(i<(elements.length-1))
            pathString += "/";
    }
    return pathString;
}

function getCurrentPathTreeString(browseStack) {
    var pathTreeString = "";
    var elements = browseStack.elements();
    for(var i=0; i<elements.length;i++) {
        var spaces = repeatChar(i, ' ');
        pathTreeString += spaces + elements[i].title;
        if(i<(elements.length-1))
            pathTreeString += "\n";
    }
    return pathTreeString;
}

// Adds leading zeros to number
function zeroPad(number, digits) {
    var num = number + "";
    while(num.length < digits) {
        num= '0' + num;
    }
    return num;
}

// Formatduration like HH:mm:ss / m:ss / 0:ss
function formatDuration(duration /* track duration in seconds */) {
    duration = Math.round(duration);

    var seconds = duration % 60;
    var totalMinutes = (duration - seconds) / 60;
    var minutes = totalMinutes % 60;
    var hours = (totalMinutes - minutes) / 60;

    return (hours > 0 ? hours + ":" : "")
            + (minutes > 0 ? (hours > 0 ? zeroPad(minutes, 2) : minutes) + ":" : "0:")
            + zeroPad(seconds, 2);
}

function escapeUPNPString(str) {
    // \ -> \\
    str = str.replace(/\\/g,'\\\\');

    // " -> \"
    str = str.replace(/\"/g,'\\"');

    return str;
}

function createUPnPQuery(searchString, searchCapabilities, capabilitiesMask, allowContainers) {
    var query = "";
    var i, mask;

    var escapedSearchString = escapeUPNPString(searchString);

    for(i=0;i<searchCapabilities.length;i++) {
        mask = 1 << i;
        if(mask & capabilitiesMask) {
            if(query.length > 0)
                query += " or ";
            query += searchCapabilities[i] + " contains \"" + escapedSearchString + "\"";
        }
    }

    if(allowContainers)
        return query;
    else
        return "upnp:class derivedfrom \"object.item.audioItem\" and (" + query +")";
}

function geSearchCapabilityDisplayString(searchCapability) {
    if(searchCapability === "upnp:artist")
        return qsTr("Artist");
    if(searchCapability === "dc:title")
        return qsTr("Title");
    if(searchCapability === "upnp:album")
        return qsTr("Album");
    if(searchCapability === "upnp:genre")
        return qsTr("Genre");
    if(searchCapability === "dc:creator")
        return qsTr("Creator");
    if(searchCapability === "dc:publisher")
        return qsTr("Publisher");
    if(searchCapability === "dc:description")
        return qsTr("Description");
    if(searchCapability === "upnp:userAnnotation")
        return qsTr("User Annotation");
    if(searchCapability === "upnp:longDescription")
        return qsTr("Long Description");

    return undefined;
}

function startsWith(str, start) {
    return str.match("^"+start) !== null;
}

function createDisplayProperties(item) {
    var durationText = "";
    if(item.resources && item.resources[0] && item.resources[0].attributes["duration"])
      durationText = getDurationString(item.resources[0].attributes["duration"]);
    else if(item.duration)
      durationText = getDurationString(item.duration);

    var titleText = item["title"];

    var metaText = "";
    if(item.artist)
        metaText = item.artist;
    if(item.album) {
        if(metaText.length > 0)
            metaText += " - ";
        metaText += item.album;
    }

    var audioType = getAudioType(item);
    if(audioType.length > 0)
        metaText += " - " + audioType;

    return {
        titleText: titleText,
        metaText: metaText,
        durationText: durationText
    }
}

function getDateYear(dateStr) {
    var date = new Date(dateStr);
    if(!isNaN(date.getTime()))
        return date.getFullYear().toString();
    else
        return "";
}

function createListContainer(container) {
    if("object.container.album.musicAlbum" === container.properties["upnp:class"])
        return {
            type: "Container",
            dtype: DonnieItemType.ContentServer,
            id: container["id"],
            pid: container["pid"],
            title: container["title"],
            titleText: container["title"],
            metaText: container.properties["upnp:artist"],
            durationText: getDateYear(container.properties["dc:date"]),
            artist: container.properties["upnp:artist"],
            album: container["title"],
            albumArtURI: container.properties["upnp:albumArtURI"],
            duration: "",
            upnpclass: container.properties["upnp:class"]
        };
    else
        return {
            type: "Container",
            dtype: DonnieItemType.ContentServer,
            id: container["id"],
            pid: container["pid"],
            title: container["title"],
            titleText: container["title"],
            metaText: "", durationText: "",
            artist: "", album: "", albumArtURI: "", duration: "",
            upnpclass: container.properties["upnp:class"]
        };
}

function createListItem(item) {

    var listItem = {
        type: "Item",
        dtype: DonnieItemType.ContentServer,
        id: item["id"],
        pid: item["pid"],
        title: item["title"],
        artist: item.properties["dc:creator"],
        album: item.properties["upnp:album"],
        albumArtURI: item.properties["upnp:albumArtURI"],
        uri: item.resources[0]["Uri"],
        didl: item["didl"],
        duration: (item.resources[0] && item.resources[0].attributes["duration"])
                      ? item.resources[0].attributes["duration"] : "",
        protocolInfo: (item.resources[0] && item.resources[0].attributes["protocolInfo"])
                      ? item.resources[0].attributes["protocolInfo"] : "",
        upnpclass: item.properties["upnp:class"]
    };

    var dprops = createDisplayProperties(listItem);
    listItem.titleText = dprops.titleText;
    listItem.metaText = dprops.metaText;
    listItem.durationText = dprops.durationText;

    return listItem;
}

var DIDL_FRAME_START = "<DIDL-Lite " +
    "xmlns:dc=\"http://purl.org/dc/elements/1.1/\" " +
    "xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" " +
    "xmlns:dlna=\"urn:schemas-dlna-org:metadata-1-0/\" " +
    "xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\">";
var DIDL_FRAME_END = "</DIDL-Lite>";

function createDIDL(id, pid, uri, title, protocolInfo, streamType) {
    // TODO escaping
    var fragment = "<item id=\"" + id + "\" parentID=\"" + pid +"\" restricted=\"1\">";
    fragment += "<dc:title>" + title + "</dc:title><res protocolInfo=\"" + protocolInfo + "\">" + uri + "</res>";
    fragment += "<upnp:class>" + streamType + "</upnp:class></item>";
    return DIDL_FRAME_START + fragment + DIDL_FRAME_END;
}

var createdTrackId = 1;
function createUserAddedTrack(uri, label, streamType) {
    var id = "" + createdTrackId++;
    var pid = id;
    var protocolInfo = "http-get:*:*:*";
    var title = label ? label : "URI[" + id + "]";
    return {
        type: "Item",
        dtype: DonnieItemType.UserDefined,
        id: id,
        pid: pid,
        title: title,
        titleText: title,
        metaText: qsTr("User entered URI"),
        uri: uri,
        upnpclass: streamType,
        duration: 0,
        protocolInfo: protocolInfo,
        didl: createDIDL(id, pid, uri, label, protocolInfo, streamType)
    }
}


function getAudioType(item) {
    var p;
    var t;
    if(item.protocolInfo) {

        // protocolInfo: "http-get:*:audio/ogg:DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01700000000000000000000000000000"
        //               "http-get:*:*:*"
        var a = item.protocolInfo.split(':');
        if(a.length < 3)
            return "";

        p = a[2].indexOf("/");
        if(p === -1) {
            if(a[2].length > 1)
                return a[2];
            else
                return "";
        }

        t = a[2].substr(p+1);
        if(startsWith(t,"x-")) // for example audio/x-flac
            return t.substr(2);
        return t;

    } else if(item.uri) {
        p = item.uri.lastIndexOf(".");
        if(p === -1)
            return "";
        return item.uri.substr(p+1);
    } else
        return "";
}

function getUPNPErrorString(errorCode) {
    // 2.4.1.4. Errors
    switch(errorCode) {
    case 402: return "Invalid Args";
        // Could be any of the following: not enough in args, too many in
        // args, no in arg by that name, one or more in args are of the wrong
        // data type.
    case 701: return "Transition not available";
        //The immediate transition from current transport state to desired
        //transport state is not supported by this device.
    case 705: return "Transport is locked";
        // The transport is “hold locked”.
    case 710: return "Seek mode not supported";
        // The specified seek mode is not supported by the device.
    case 711: return "Illegal seek target";
        // The specified seek target is not specified in terms of the seek
        // mode, or is not present on the media.
    case 714: return "Illegal MIME-type";
        // The specified resource has a MIME-type which is not supported
        // by the AVTransport service
    case 715: return "Content ‘BUSY’";
        // This indicates the resource is already being played by other
        // means. The actual implementation might detect through HTTP
        // Busy, and returns this error code.
    case 716: return "Resource not found. The specified resource cannot be found in the network";
    case 718: return "Invalid InstanceID The specified instanceID is invalid for this AVTransport.";
    case 737: return "No DNS Server The DNS Server is not available (HTTP error 503)";
    case 738: return "Bad Domain Name Unable to resolve the Fully Qualified Domain Name. (HTTP error 502)";
    case 739:  return "Server Error The server that hosts the resource is unreachable or unresponsive (HTTP error 404/410).";
    default: return "";
    }
}

var AudioItemType = {
    MusicTrack: "object.item.audioItem.musicTrack",
    AudioBroadcast: "object.item.audioItem.audioBroadcast"
}

var DonnieItemType = {
    ContentServer: "Content Server",
    UserDefined: "User Defined"
}

function isBroadcast(track) {
    return track && track.upnpclass === AudioItemType.AudioBroadcast
}

