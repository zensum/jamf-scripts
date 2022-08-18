#!/bin/bash

URL='https://github.com/JohnCoates/Aerial/releases/latest/download'
FILE='Aerial.saver.zip'
APP_NAME='Aerial' # assuming it's a pretty name for jamf ui
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
SCREENSAVER_FILENAME="Aerial.saver"
SCREENSAVERS_PATH="/Library/Screen Savers"
SCREENSAVER_LOCATION="$SCREENSAVERS_PATH/$SCREENSAVER_FILENAME"

REINSTALL=""
ARGS=$@
if [[ " ${ARGS[*]} " =~ " -r " ]]; then
    echo "`date` | Reinstall requested with -r"
    REINSTALL=1
fi

### Check if installed or not
INSTALLED_VERSION=""
if [ -d "$SCREENSAVER_LOCATION" ]; then
    INSTALLED_VERSION=$(defaults read "$SCREENSAVER_LOCATION/Contents/info" CFBundleShortVersionString)
    if [ $? -ne 0 ]; then
        echo "`date` | Could not read installed version of $SCREENSAVER_LOCATION"
        echo "`date` | Deleting current installation at $SCREENSAVER_LOCATION"
        rm -rf $SCREENSAVER_LOCATION
        INSTALLED_VERSION=""
    else
        echo "`date` | Installed version of $APP_NAME is $INSTALLED_VERSION at $SCREENSAVER_LOCATION"
    fi
else
    echo "`date` | No current installation of $APP_NAME found as $SCREENSAVER_LOCATION"
fi

# Grab latest version
echo "`date` | Downloading zip from $URL/$FILE"
TMP_SAVER=/tmp/Aerial.saver # this is the unzipped file
TMP_LOCATION="$TMP_SAVER.zip"
/usr/bin/curl -Ls "${URL}/${FILE}" -o "$TMP_LOCATION"

if [ ! -e $TMP_LOCATION ] || [ $? -ne 0 ]; then
    echo "`date` | Downloaded $APP_NAME to $TMP_LOCATION"
else
    echo "`date` | Could not find any downloads for $APP_NAME on $TMP_LOCATION"
    exit 1
fi

if [ -d $TMP_SAVER ]; then
    echo "`date` | Found old screensaver removing $TMP_SAVER"
    rm -rf $TMP_SAVER
fi

unzip -q -o "$TMP_LOCATION" -d /tmp # you can remove -v to remove the debug stuff, or "tar xop " instead of unzip if your script runs very very early
if [ $? -ne 0 ]; then
    echo "`date` | Unzip and move failed for $APP_NAME on $TMP_LOCATION to $TMP_SAVER"
    exit 1
fi

if [ -d "$SCREENSAVER_LOCATION" ]; then
    LATEST_VERSION=$(plutil -p "$TMP_SAVER/Contents/Info.plist" | grep CFBundleShortVersionString | awk '{print $3}' | sed 's/[^0-9\.]*//g')
    if [ $? -ne 0 ]; then
        echo "`date` | Could not read latest version of $SCREENSAVER_LOCATION"
        echo "`date` | Deleting current installation at $SCREENSAVER_LOCATION"
        rm -rf "$SCREENSAVER_LOCATION"
        LATEST_VERSION="x"
    else
        echo "`date` | Latest version of $APP_NAME is $LATEST_VERSION at $SCREENSAVER_LOCATION"
        if [ $INSTALLED_VERSION == $LATEST_VERSION ] && [ ! $REINSTALL ]; then
            echo "`date` | Already on the latest version $LATEST_VERSION"
            exit 0
        else
            echo "`date` | Downloaded the latest version $LATEST_VERSION"
        fi
        echo "`date` | Removing old version of $APP_NAME at $SCREENSAVER_LOCATION"
        rm -rf "$SCREENSAVER_LOCATION"
    fi
fi

echo "`date` | Moving $TMP_SAVER/$FILE_NAME to $SCREENSAVERS_PATH"
mkdir -p "$SCREENSAVERS_PATH"
mv -f "$TMP_SAVER" "$SCREENSAVERS_PATH"
mkdir -p "/Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application Support/Aerial"

echo "`date` | Whitelisting $SCREENSAVER_LOCATION for GateKeeper"
/usr/bin/xattr -r -d com.apple.quarantine "$SCREENSAVER_LOCATION"

echo "`date` | Deleting zip file at $TMP_LOCATION for $APP_NAME"
rm $TMP_LOCATION

# Display the screensaver version installed, this works too for .saver ;)
NEWLY_INSTALLED_VERSION=$(defaults read "$SCREENSAVER_LOCATION/Contents/info" CFBundleShortVersionString)
echo "`date` | Successfully installed $APP_NAME with version $NEWLY_INSTALLED_VERSION"

if [ $INSTALLED_VERSION ] && [ ! $REINSTALL ]; then
    echo "`date` | Update completed for $APP_NAME from $INSTALLED_VERSION to $NEWLY_INSTALLED_VERSION"
    killall cfprefsd
    exit 0
fi

# macOS sometimes does not create this folder
echo "`date` | Creating empty folder /Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application\ Support/Aerial/ for cache"
mkdir -p /Users/Shared/ScreenSaverCache

echo "`date` | Added settings for $APP_NAME"

# adapted from https://support.carouselsignage.com/hc/en-us/articles/360047317971-Jamf-Setup-macOS-Screen-Saver-for-Carousel-Cloud
HUUID=$(system_profiler SPHardwareDataType | awk '/Hardware UUID/ {print $3}')
ssPlist="/Users/$CURRENT_USER/Library/Preferences/ByHost/com.apple.screensaver.$HUUID.plist"

mkdir -p "/Users/$CURRENT_USER/Library/Preferences/ByHost"

# set the screen saver for the current user to the one $SCd
echo "`date` | Adding settings for $CURRENT_USER"

/usr/libexec/PlistBuddy -c "Print askForPasswordDelay" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add askForPasswordDelay int 0" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set askForPasswordDelay 0" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print askForPassword" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add askForPassword bool true" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set askForPassword true" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print moduleDict" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add :moduleDict dict" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print moduleDict:moduleName" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add :moduleDict:moduleName string Aerial" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set :moduleDict:moduleName Aerial" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print moduleDict:path" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add :moduleDict:path string $SCREENSAVER_LOCATION" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set :moduleDict:path $SCREENSAVER_LOCATION" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print moduleDict:type" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add :moduleDict:type int 0" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set :moduleDict:type 0" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print showClock" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add showClock string NO" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set showClock NO" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print idleTime" $ssPlist
if [ $? -eq 1 ]; then
    # 300 seconds = 5 minutes
    /usr/libexec/PlistBuddy -c "Add idleTime int 300" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set idleTime 300" $ssPlist
fi

chown -R $CURRENT_USER "$ssPlist"

SETTINGS_FOLDER="/Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences"
PROPERTY_LIST="$SETTINGS_FOLDER/com.glouel.Aerial.plist"

if [ ! -f "$PROPERTY_LIST" ]; then
    echo "`date` | Creating empty property list at $PROPERTY_LIST"
    mkdir -p "$SETTINGS_FOLDER"
    touch "$PROPERTY_LIST"
else
    if [ ! $REINSTALL ]; then
        echo "`date` | Property list already exists at $PROPERTY_LIST"
        exit 0
    else
        echo "`date` | Removing old settings at $PROPERTY_LIST"
        rm $PROPERTY_LIST
    fi
fi

echo "`date` | Writing new $APP_NAME settings"
cat > "$PROPERTY_LIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>LayerClock</key>
	<string>{
  "clockFormat" : 0,
  "corner" : 3,
  "displays" : 0,
  "fontName" : "Helvetica Neue Medium",
  "fontSize" : 50,
  "hideAmPm" : false,
  "isEnabled" : false,
  "showSeconds" : true
}</string>
	<key>LayerMusic</key>
	<string>{
  "corner" : 2,
  "displays" : 0,
  "fontName" : "Helvetica Neue Medium",
  "fontSize" : 20,
  "isEnabled" : false
}</string>
	<key>cacheLimit</key>
	<real>10</real>
	<key>ciOverrideLanguage</key>
	<string>sv</string>
	<key>firstTimeSetup</key>
	<true/>
	<key>highQualityTextRendering</key>
	<true/>
	<key>darkModeNightOverride</key>
	<true/>
	<key>intCachePeriodicity</key>
	<integer>1</integer>
	<key>intVideoFormat</key>
	<integer>3</integer>
	<key>lastVideoCheck</key>
	<string>2022-08-16</string>
	<key>layers</key>
	<string>[
  "message",
  "clock",
  "date",
  "location",
  "battery",
  "weather",
  "countdown",
  "timer",
  "music"
]</string>
	<key>newShouldPlayString</key>
	<array>
		<string>location:Alabama</string>
		<string>location:California</string>
		<string>location:China</string>
		<string>location:Dubai</string>
		<string>location:England</string>
		<string>location:Florida</string>
		<string>location:Grand Canyon</string>
		<string>location:Greenland</string>
		<string>location:Hawaii</string>
		<string>location:Hong Kong</string>
		<string>location:Iceland</string>
		<string>location:Italy</string>
		<string>location:Liwa</string>
		<string>location:London</string>
		<string>location:Los Angeles</string>
		<string>location:Nevada</string>
		<string>location:New York</string>
		<string>location:Oregon</string>
		<string>location:Patagonia</string>
		<string>location:San Francisco</string>
		<string>location:Scotland</string>
		<string>location:Sea</string>
		<string>location:Space</string>
		<string>location:Texas</string>
		<string>location:Yosemite</string>
	</array>
	<key>overrideCache</key>
	<true/>
	<key>supportPath</key>
	<string>/Users/Shared/ScreenSaverCache</string>
</dict>
</plist>
EOF

chown -R "$CURRENT_USER" "$SETTINGS_FOLDER"
plutil -convert binary1 "$PROPERTY_LIST"
/usr/bin/xattr -r -d com.apple.quarantine "$PROPERTY_LIST"
chown $CURRENT_USER "$PROPERTY_LIST"

echo "`date` | Adding settings for $CURRENT_USER"
SET_SETTINGS=$(/usr/libexec/PlistBuddy -c "Print" "$PROPERTY_LIST")
echo "`date` | Settings are now $SET_SETTINGS"

# restart settings
killall cfprefsd

echo "`date` | $APP_NAME installation complete"

exit 0
