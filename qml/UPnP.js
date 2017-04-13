
.pragma library

var dataStructures = {
    Stack : function() {
        var elements = [];
        this.push = function(element) {
            elements.push(element);
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
