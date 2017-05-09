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

.pragma library

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
    for(var i=1; i<elements.length;i++) {
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
    for(var i=1; i<elements.length;i++) {
        pathString += elements[i].title;
        if(i<(elements.length-1))
            pathString += "/";
    }
    return pathString;
}

function getCurrentPathTreeString(browseStack) {
    var pathTreeString = "";
    var elements = browseStack.elements();
    for(var i=1; i<elements.length;i++) {
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
        return "Artist";
    if(searchCapability === "dc:title")
        return "Title";
    if(searchCapability === "upnp:album")
        return "Album";
    if(searchCapability === "upnp:genre")
        return "Genre";
    if(searchCapability === "dc:creator")
        return "Creator";
    if(searchCapability === "dc:publisher")
        return "Publisher";
    if(searchCapability === "dc:description")
        return "Description";
    if(searchCapability === "upnp:userAnnotation")
        return "User Annotation";
    if(searchCapability === "upnp:longDescription")
        return "Long Description";

    return undefined;
}

function startsWith(str, start) {
    return str.match("^"+start) !== null;
}

function createTrack(item) {
    var track = {};
    track["id"] = item.id;
    track["title"] = item["title"];
    track["didl"] = item["didl"];
    track["artist"] = item.properties["dc:creator"];
    track["album"] = item.properties["upnp:album"];
    track["albumArtURI"] = item.properties["upnp:albumArtURI"];
    track["uri"] = item.resources[0]["Uri"];
    track["duration"] = item.resources[0].attributes["duration"];
    track["index"] = item.properties["upnp:originalTrackNumber"];
    return track;
}
