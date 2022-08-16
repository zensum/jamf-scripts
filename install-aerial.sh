#!/bin/bash

URL='https://github.com/JohnCoates/Aerial/releases/latest/download'
FILE='Aerial.saver.zip'
APP_NAME='Aerial' # assuming it's a pretty name for jamf ui
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
SCREENSAVER_FILENAME="Aerial.saver"
SCREENSAVERS_PATH="/Users/$CURRENT_USER/Library/Screen\ Savers"
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

if [ -e $TMP_LOCATION ]; then
    echo "`date` | Downloaded $APP_NAME to $TMP_LOCATION"
else
    echo "`date` | Could not find any downloads for $APP_NAME on $TMP_LOCATION"
    exit 1
fi

if [ -d $TMP_SAVER ]; then
    echo "`date` | Found old screensaver removing $TMP_SAVER"
    rm -rf $TMP_SAVER
fi

# unzip the screensaver
unzip -q -o "$TMP_LOCATION" -d /tmp # you can remove -v to remove the debug stuff, or "tar xop " instead of unzip if your script runs very very early

if [ $? -ne 0 ]; then
    echo "`date` | Unzip failed for $APP_NAME on $TMP_LOCATION to $TMP_SAVER"
    exit 1
fi

if [ -d "$SCREENSAVER_LOCATION" ]; then
    LATEST_VERSION=$(plutil -p "$TMP_SAVER/Contents/Info.plist" | grep CFBundleShortVersionString)
    if [ $? -ne 0 ]; then
        echo "`date` | Could not read latest version of $SCREENSAVER_LOCATION"
        echo "`date` | Deleting current installation at $SCREENSAVER_LOCATION"
        rm -rf "$SCREENSAVER_LOCATION"
        LATEST_VERSION=""
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


echo "`date` | Moving $TMP_SAVER/$FILE_NAME to /Users/$CURRENT_USER/Library/Screen\ Savers/."
mkdir -p "$SCREENSAVERS_PATH"
mv -f "$TMP_SAVER" "$SCREENSAVERS_PATH/."
chown -R $CURRENT_USER "$SCREENSAVER_LOCATION"

echo "`date` | Deleting zip file at $TMP_LOCATION for $APP_NAME"
rm $TMP_LOCATION

# Display the screensaver version installed, this works too for .saver ;)
NEWLY_INSTALLED_VERSION=$(defaults read "$SCREENSAVER_LOCATION/Contents/info" CFBundleShortVersionString)
echo "`date` | Successfully installed $APP_NAME with version $NEWLY_INSTALLED_VERSION"

if [ $INSTALLED_VERSION ] && [ ! $REINSTALL ]; then
    echo "`date` | Update completed for $APP_NAME from $INSTALLED_VERSION to $NEWLY_INSTALLED_VERSION"
    exit 0
fi
exit 0
# macOS sometimes does not create this folder
echo "`date` | Creating empty folder /Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application\ Support/Aerial/ for cache"
mkdir -p /Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application\ Support/Aerial

echo "`date` | Added settings for $APP_NAME"

# adapted from https://support.carouselsignage.com/hc/en-us/articles/360047317971-Jamf-Setup-macOS-Screen-Saver-for-Carousel-Cloud
HUUID=$(system_profiler SPHardwareDataType | awk '/Hardware UUID/ {print $3}')
ssPlist="/Users/$CURRENT_USER/Library/Preferences/ByHost/com.apple.screensaver.$HUUID.plist"

mkdir -p "/Users/$CURRENT_USER/Library/Preferences/ByHost"

# set the screen saver for the current user to the one $SCd
echo "`date` | Adding settings for $CURRENT_USER"

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
    /usr/libexec/PlistBuddy -c "Set :moduleDict:path $SCREENSAVER_LOCATION" $SCi

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

/usr/libexec/PlistBuddy -c "Print CleanExit" $ssPlist
if [ $? -eq 1 ]; then
    # 300 seconds = 5 minutes
    /usr/libexec/PlistBuddy -c "Add CleanExit string YES" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set CleanExit YES" $ssPlist
fi
chown -R $CURRENT_USER "$ssPlist"

# restart settings
killall cfprefsd

exit 0
