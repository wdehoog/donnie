# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = donnie

CONFIG += sailfishapp

SOURCES += src/donnie.cpp \
    src/upnp.cpp \
    src/upnpbrowseworker.cpp \
    src/upnpdiscoveryworker.cpp \
    src/upnpgetrendererworker.cpp \
    src/upnpgetserverworker.cpp \
    src/upnpsearchworker.cpp

OTHER_FILES += qml/donnie.qml \
    qml/cover/CoverPage.qml \
    qml/pages/FirstPage.qml \
    qml/pages/SecondPage.qml \
    rpm/donnie.changes.in \
    rpm/donnie.spec \
    rpm/donnie.yaml \
    donnie.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

INCLUDEPATH += /usr/include/qt5/MprisQt
INCLUDEPATH += /usr/include/qt5/QtDBus

LIBS += -lupnpp
LIBS += -lmpris-qt5

DISTFILES += \
    qml/pages/Browse.qml \
    qml/pages/DiscoveryPage.qml \
    qml/pages/PlayerPage.qml \
    qml/pages/RendererPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/UPnPDeviceDetails.qml \
    qml/icons/icon-m-stop.png \
    qml/pages/AboutPage.qml \
    qml/license/License.txt \
    qml/UPnP.js \
    qml/pages/MainPage.qml \
    qml/pages/LogPage.qml \
    qml/pages/Search.qml \
    qml/components/MultiItemPicker.qml \
    license/License.txt \
    qml/components/Messagebox.qml \
    qml/components/ErrorDialog.qml \
    qml/components/ConfirmDialog.qml

HEADERS += \
    src/upnp.h \
    src/upnpbrowseworker.h \
    src/upnpdiscoveryworker.h \
    src/IconProvider.h \
    src/upnpgetrendererworker.h \
    src/upnpgetserverworker.h \
    src/upnpsearchworker.h \
    src/upnpgettransportinforunnable.h \
    src/upnpgetmediainforunnable.h \
    src/upnpgetpositioninforunnable.h \
    src/upnpsettrackrunnable.h \
    src/upnpsetnexttrackrunnable.h \
    src/upnpgetmetadatarunnable.h
    
 TRANSLATIONS += \
    translations/donnie-es.ts \
    translations/donnie-nl.ts \
    translations/donnie.ts 

