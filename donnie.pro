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
    src/upnpdiscoveryworker.cpp

OTHER_FILES += qml/donnie.qml \
    qml/cover/CoverPage.qml \
    qml/pages/FirstPage.qml \
    qml/pages/SecondPage.qml \
    rpm/donnie.changes.in \
    rpm/donnie.spec \
    rpm/donnie.yaml \
    translations/*.ts \
    donnie.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 256x256

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
# TRANSLATIONS += translations/donnie-de.ts

LIBS += -lupnpp

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
    qml/UPnP.js

HEADERS += \
    src/upnp.h \
    src/upnpbrowseworker.h \
    src/upnpdiscoveryworker.h \
    src/IconProvider.h
