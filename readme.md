## Donnie

A UPnP Control Point and Audio Player for SailfishOS. It is written in QML and C++. For UPnP it relies on [libupnpp](https://opensourceprojects.eu/p/libupnpp/).

I use it on my Oneplus One running it's SailfishOS port. For Content Server I use `minidlna` and `minimserver` and for Renderer `mopidy/upmpdcli` on a Pi and `rygel` on my phone.

See the [screenshots](https://github.com/wdehoog/donnie/tree/master/screenshots) directory for how it looks.

Note that it is still fresh and under development so things might not work as expected.

### Features
  * Browse and Search Content Server
  * Control a Renderer
  * Play on phone with built-in Player (QT-Audio)
  * Album Art
  * Gapless (setNextAVTransportURI)
  * MPris support (Lock Screen and Gestures)


### Issues
  * Sometimes not all UPnP devices are discovered. Refresh the list might help.
  * Donnie will probably fail if another control point interferes.
  * When the same track appears twice in the list and next to each other a
    track change will not be detected and the next track will not be started.
  * When wlan is turned on after Donnie is started it will not use it. Donnie has to be restarted.
    This is caused by one of the underlying libraries.
  * When Donnie crashes it can happen that the MPRIS registration cannot be done again or by another app. A reboot seems required.

### Future
There are already a lot of Audio Player for Sailfish. Many of which look and work better then Donnie. It is a lot of work to come at the same level as those. Hopefully  one of those players will integrate the UPnP functionality Donnie has.


### Installation
Packages of Donnie and some libraries it needs can be installed from my [OBS repository]( http://repo.merproject.org/obs/home:/wdehoog:/donnie/sailfish_latest_armv7hl/).

To add this repo:

```
devel-su ssu ar wdehoog http://repo.merproject.org/obs/home:/wdehoog:/donnie/sailfish_latest_armv7hl/
```

Then install with

```
devel-su pkcon ref
devel-su pkcon install donnie
```

Maybe you also need to restart pulse audio to have it load the policy file for Donnie.

```
systemctl --user restart pulseaudio
```

###  Usage
#### Main page
Shows the current Renderer and Content Server. Click on the area to select another one.

Three buttons open the Browse, Renderer or Player pages.

Pully menus give access to:

  * Settings Page
  * About Page

#### Browser
Will browse the Content Server. 

Click on a folder or album to open it. A long press on an item will open a context menu with: 

  * Add to Player
  * Replace in Player
  * Add All to Player
  * Replace All in Player

Pully/Push menus will allow to load more list items (if available):

  * Load More
  * Load Next Set
  * Load Previous Set
  
#### Search
Will allow to query the Content Server. The result list provides the same functions as the Browse list.

The search can be performd on one or more of the following fields: Creator, Title, Album, Artist or Genre.

The search results can be grouped by Creator, Title, Album, Artist and Genre.

#### Player
Gives access to the player controls. You can:

  * Pause/Play/Stop
  * Next/Previous
  * Set Volume and Mute
  * Seek
  * Select track
  * Remove a track

A Pully menu allows to Empty the list.

### Development
This project is developed with the Sailfish OS IDE (QT Creator). It needs libupnpp, libupnp and libmpdclient to be installed on the Build Target (VM) and the Deploy Target (phone). All three can be found in my [OBS repository]( http://repo.merproject.org/obs/home:/wdehoog:/donnie/sailfish_latest_armv7hl/).



### Thanks
  * J.F.Dockes for upplay + libupnpp, amazing UPnP support 
  * equeim for unplayer
  * jabbounet for upnpplayer 
  * kimmoli for IconProvider and MultiItemPicker
  * Morpog for icon shape
