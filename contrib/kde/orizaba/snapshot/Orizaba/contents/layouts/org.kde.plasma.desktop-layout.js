// Generado automáticamente por MyKdeCustom/extract_kde.sh
// Plasma 6.6.6; API de scripting 20
"use strict";

function orizabaAsset(relativePath) {
    return userDataPath("data", "plasma/look-and-feel/Orizaba/contents/assets/" + relativePath);
}

var orizabaPanel0 = new Panel;
orizabaPanel0.location = "bottom";
orizabaPanel0.height = 46;
orizabaPanel0.hiding = "none";
orizabaPanel0.alignment = "center";
orizabaPanel0.offset = 0;
orizabaPanel0.lengthMode = "fill";
var orizabaPanelViewRoot0 = ConfigFile("plasmashellrc", "PlasmaViews");
var orizabaPanelView0 = ConfigFile(orizabaPanelViewRoot0, "Panel " + orizabaPanel0.id);
orizabaPanelView0.writeEntry("floating", "1");
orizabaPanelView0.writeEntry("panelOpacity", "2");
var orizabaPanelView0Group0 = ConfigFile(orizabaPanelView0, "Defaults");
orizabaPanelView0Group0.writeEntry("thickness", "46");
var orizabaPanel0Widget0 = orizabaPanel0.addWidget("org.kde.plasma.kickoff");
orizabaPanel0Widget0.userBackgroundHints = "StandardBackground";
orizabaPanel0Widget0.currentConfigGroup = [];
orizabaPanel0Widget0.writeConfig("popupHeight", "509");
orizabaPanel0Widget0.writeConfig("popupWidth", "663");
orizabaPanel0Widget0.currentConfigGroup = ["ConfigDialog"];
orizabaPanel0Widget0.writeConfig("DialogHeight", "630");
orizabaPanel0Widget0.writeConfig("DialogWidth", "810");
orizabaPanel0Widget0.currentConfigGroup = ["General"];
orizabaPanel0Widget0.writeConfig("favoritesPortedToKAstats", "true");
orizabaPanel0Widget0.writeConfig("icon", orizabaAsset("home/Descargas/Gentoo-logo-dark.svg"));
orizabaPanel0Widget0.writeConfig("systemFavorites", "suspend\\,hibernate\\,reboot\\,shutdown");
orizabaPanel0Widget0.reloadConfig();
var orizabaPanel0Widget1 = orizabaPanel0.addWidget("org.kde.plasma.pager");
orizabaPanel0Widget1.userBackgroundHints = "StandardBackground";
orizabaPanel0Widget1.reloadConfig();
var orizabaPanel0Widget2 = orizabaPanel0.addWidget("org.kde.plasma.icontasks");
orizabaPanel0Widget2.userBackgroundHints = "StandardBackground";
orizabaPanel0Widget2.currentConfigGroup = ["General"];
orizabaPanel0Widget2.writeConfig("launchers", "applications:systemsettings.desktop,preferred://filemanager,preferred://browser");
orizabaPanel0Widget2.reloadConfig();
var orizabaPanel0Widget3 = orizabaPanel0.addWidget("org.kde.plasma.marginsseparator");
orizabaPanel0Widget3.userBackgroundHints = "StandardBackground";
orizabaPanel0Widget3.reloadConfig();
var orizabaPanel0Widget4 = orizabaPanel0.addWidget("org.kde.plasma.systemtray");
orizabaPanel0Widget4.userBackgroundHints = "StandardBackground";
orizabaPanel0Widget4.currentConfigGroup = [];
orizabaPanel0Widget4.writeConfig("popupHeight", "432");
orizabaPanel0Widget4.writeConfig("popupWidth", "432");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "138"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.mediacontroller");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "129"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.volume");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "129", "Configuration", "General"];
orizabaPanel0Widget4.writeConfig("migrated", "true");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "118"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.vault");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "123"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.notifications");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "128"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.keyboardlayout");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "125"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.cameraindicator");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "137"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.bluetooth");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "135"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.brightness");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "122"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.keyboardindicator");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "136"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.battery");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "121"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.weather");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "127"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.manage-inputmethod");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "126"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.devicenotifier");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "119"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.networkmanagement");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "119", "Configuration", "General"];
orizabaPanel0Widget4.writeConfig("currentDetailsTab", "details");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "120"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.kscreen");
orizabaPanel0Widget4.currentConfigGroup = ["Applets", "124"];
orizabaPanel0Widget4.writeConfig("immutability", "1");
orizabaPanel0Widget4.writeConfig("plugin", "org.kde.plasma.clipboard");
orizabaPanel0Widget4.currentConfigGroup = ["General"];
orizabaPanel0Widget4.writeConfig("extraItems", "org.kde.plasma.vault,org.kde.plasma.bluetooth,org.kde.plasma.networkmanagement,org.kde.kscreen,org.kde.plasma.weather,org.kde.plasma.keyboardindicator,org.kde.plasma.notifications,org.kde.plasma.clipboard,org.kde.plasma.cameraindicator,org.kde.plasma.mediacontroller,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.brightness,org.kde.plasma.battery,org.kde.plasma.keyboardlayout,org.kde.plasma.volume");
orizabaPanel0Widget4.writeConfig("knownItems", "org.kde.plasma.vault,org.kde.plasma.bluetooth,org.kde.plasma.networkmanagement,org.kde.kscreen,org.kde.plasma.weather,org.kde.plasma.keyboardindicator,org.kde.plasma.notifications,org.kde.plasma.clipboard,org.kde.plasma.cameraindicator,org.kde.plasma.mediacontroller,org.kde.plasma.devicenotifier,org.kde.plasma.manage-inputmethod,org.kde.plasma.brightness,org.kde.plasma.battery,org.kde.plasma.keyboardlayout,org.kde.plasma.volume");
orizabaPanel0Widget4.reloadConfig();
var orizabaPanel0Widget5 = orizabaPanel0.addWidget("org.kde.plasma.digitalclock");
orizabaPanel0Widget5.userBackgroundHints = "StandardBackground";
orizabaPanel0Widget5.currentConfigGroup = [];
orizabaPanel0Widget5.writeConfig("popupHeight", "451");
orizabaPanel0Widget5.writeConfig("popupWidth", "560");
orizabaPanel0Widget5.reloadConfig();
var orizabaPanel0Widget6 = orizabaPanel0.addWidget("org.kde.plasma.showdesktop");
orizabaPanel0Widget6.userBackgroundHints = "StandardBackground";
orizabaPanel0Widget6.reloadConfig();

function orizabaActivity(activityNameToFind, useCurrent) {
    if (useCurrent) {
        var activeId = currentActivity();
        setActivityName(activeId, activityNameToFind);
        return activeId;
    }
    var ids = activities();
    for (var i = 0; i < ids.length; ++i) {
        if (activityName(ids[i]) === activityNameToFind) return ids[i];
    }
    return createActivity(activityNameToFind);
}

var orizabaActivity0 = orizabaActivity("Por omisión", true);
var orizabaActivity0Desktops = desktopsForActivity(orizabaActivity0);
var orizabaActivity0Desktop0 = null;
for (var orizabaDesktopSearch = 0; orizabaDesktopSearch < orizabaActivity0Desktops.length; ++orizabaDesktopSearch) {
    if (orizabaActivity0Desktops[orizabaDesktopSearch].screen === 0) {
        orizabaActivity0Desktop0 = orizabaActivity0Desktops[orizabaDesktopSearch];
        break;
    }
}
if (orizabaActivity0Desktop0) {
    orizabaActivity0Desktop0.wallpaperPlugin = "org.kde.image";
    orizabaActivity0Desktop0.currentConfigGroup = [];
    orizabaActivity0Desktop0.writeConfig("ItemGeometriesHorizontal", "");
    orizabaActivity0Desktop0.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    orizabaActivity0Desktop0.writeConfig("Image", "file://" + orizabaAsset("usr/share/wallpapers/Path/"));
    orizabaActivity0Desktop0.writeConfig("SlidePaths", orizabaAsset("usr/share/wallpapers/"));
    orizabaActivity0Desktop0.currentConfigGroup = ["ConfigDialog"];
    orizabaActivity0Desktop0.writeConfig("DialogHeight", "630");
    orizabaActivity0Desktop0.writeConfig("DialogWidth", "810");
    orizabaActivity0Desktop0.reloadConfig();
}
