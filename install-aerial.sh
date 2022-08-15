#!/bin/bash

URL='https://github.com/glouel/AerialCompanion/releases/latest/download'
FILE='AerialCompanion.dmg'
APP_NAME='Aerial Companion'
APP_LOCATION="/Applications/$APP_NAME.app"
APP_GREPPER_NAME='Aerial'

### INSTALLATION

if [ -e $APP_LOCATION ]; then
    INSTALLED_VERSION=$(defaults read "$APP_LOCATION/Contents/info" CFBundleShortVersionString)
    echo "`date` | Installed version of $APP_NAME is $INSTALLED_VERSION at $APP_LOCATION"
else
    echo "`date` | No current installation of $APP_NAME found as $APP_LOCATION"
fi


echo "`date` | Downloading installer disk image from $URL/$FILE"
TMP_LOCATION=/tmp/app-install.dmg
/usr/bin/curl -Ls "${URL}/${FILE}" -o "$TMP_LOCATION"

if [ -e $TMP_LOCATION ]; then
    echo "`date` | Downloaded $APP_NAME to $TMP_LOCATION"
else
    echo "`date` | Could not find any downloads for $APP_NAME on $TMP_LOCATION"
    exit 1
fi

while true; do
    MOUNT_PATH=$(df | grep $APP_GREPPER_NAME | sed '1q' | awk '{print $1}')
    if [ -z $MOUNT_PATH ]; then
        break
    elif [ -e $MOUNT_PATH ]; then
        echo "`date` | Detaching $MOUNT_PATH."
        hdiutil detach $MOUNT_PATH -quiet
    fi
done

echo "`date` | Mounting installer disk image for $APP_NAME"
hdiutil mount $TMP_LOCATION -noverify -nobrowse -noautoopen -quiet
sleep 10

MOUNT_NAME=$(df | grep $APP_GREPPER_NAME | sed '1q' | sed 's/.*Volumes/\/Volumes/' | sed 's/\ *$//g')

if [ -e "$MOUNT_NAME" ]; then
    echo "`date` | Mounted $APP_NAME on $MOUNT_NAME"
else
    echo "`date` | Could not mount dmg for $APP_NAME"
    rm $TMP_LOCATION
    exit 1
fi

echo "`date` | Killing $APP_NAME if running."
killall "$APP_NAME" || echo

echo "`date` | Removing old version of $APP_NAME at $APP_LOCATION"
rm -rf $APP_LOCATION

echo "`date` | Copying $APP_NAME to $APP_LOCATION"
cp -r "$MOUNT_NAME/$APP_NAME.app" /Applications/

echo "`date` | Changing permissions for $APP_NAME on $APP_LOCATION"
chown -R root:wheel "$APP_LOCATION"
chmod -R 755 "$APP_LOCATION"

echo "`date` | Unmounting $APP_NAME disk image"
hdiutil detach $(df | grep "$APP_GREPPER" | awk '{print $1}') -quiet
sleep 10

echo "`date` | Deleting disk image for $APP_NAME"
rm $TMP_LOCATION

INSTALLED_VERSION=$(defaults read "$APP_LOCATION/Contents/info" CFBundleShortVersionString)
echo "`date` | Successfully installed $APP_NAME with version $INSTALLED_VERSION"

### SETTINGS

echo "`date` | Trying to move and add settings for $APP_NAME from /tmp"

CURRENT_USER=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')

echo "`date` | Moving com.glouel.ArialUodater to /Users/$CURRENT_USER/Library/HTTPStorages/"
mkdir -p /Users/$CURRENT_USER/Library/HTTPStorages/
ditto -xk /tmp/com.glouel.AerialUpdater.zip /Users/$CURRENT_USER/Library/HTTPStorages/.
echo "`date` | Moving /tmp/Aerial.saver to /Users/$CURRENT_USER/Library/Screen\ Savers/."
mkdir -p /Users/$CURRENT_USER/Library/Screen\ Savers/
ditto -xk /tmp/Aerial.saver.zip /Users/$CURRENT_USER/Library/Screen\ Savers/.
echo "`date` | Moving /tmp/com.glouel.AerialUpdaterAgent.plist to /Users/$CURRENT_USER/Library/LaunchAgents/."
mkdir -p /Users/$CURRENT_USER/Library/LaunchAgents/
ditto -xk /tmp/com.glouel.AerialUpdaterAgent.plist.zip /Users/$CURRENT_USER/Library/LaunchAgents/.

echo "`date` | Creating empty folder /Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application\ Support/Aerial/ for cache"
mkdir -p /Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application\ Support/Aerial

echo "`date` | Added settings for $APP_NAME"

### SCREENSAVER SETTINGS
# inspiration from https://community.jamf.com/t5/jamf-pro/screen-saver-settings/m-p/249757

## set key items for screensaver
# /usr/bin/sudo -u $CURRENT_USER /usr/bin/defaults -currentHost write com.apple.screensaver CleanExit -string "YES"
# /usr/bin/sudo -u $CURRENT_USER /usr/bin/defaults -currentHost write com.apple.screensaver PrefsVersion -int 100
# /usr/bin/sudo -u $CURRENT_USER /usr/bin/defaults -currentHost write com.apple.screensaver showClock -string "NO"
# /usr/bin/sudo -u $CURRENT_USER /usr/bin/defaults -currentHost write com.apple.screensaver idleTime -int 300 # wait time before start Screen saver in seconds 300=5 min

# /usr/bin/sudo -u $CURRENT_USER /usr/bin/defaults -currentHost write com.apple.screensaver moduleDict -dict moduleName -string "Customfile" path -string "/Users/$CURRENT_USER/Library/Screen\ Savers/Aerial.saver" type -int 0

# sudo killall -hup cfprefsd

#!/bin/sh

# adapted from https://support.carouselsignage.com/hc/en-us/articles/360047317971-Jamf-Setup-macOS-Screen-Saver-for-Carousel-Cloud
huuid=$(system_profiler SPHardwareDataType | awk '/Hardware UUID/ {print $3}')
ssPlist="/Users/$CURRENT_USER/Library/Preferences/ByHost/com.apple.screensaver.$huuid.plist"
configPlist="/Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost/com.trms.Carousel-Cloud-Screensaver.$huuid.plist"
screenSaverFileName="Aerial.saver"
screenSaverPath="/Users/$CURRENT_USER/Library/Screen Savers"

mkdir -p "/Users/$CURRENT_USER/Library/Preferences/ByHost"
mkdir -p "/Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost"
mkdir -p "$screenSaverPath"

# set the screen saver for the current user to the one we installed

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
    /usr/libexec/PlistBuddy -c "Add :moduleDict:path string $screenSaverPath/$screenSaverFileName" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set :moduleDict:path $screenSaverPath/$screenSaverFileName" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print moduleDict:showClock" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add :moduleDict:showClock string NO" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set :moduleDict:showClock NO" $ssPlist
fi


/usr/libexec/PlistBuddy -c "Print moduleDict:idleTime" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add :moduleDict:idleTime string NO" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set :moduleDict:idleTime NO" $ssPlist
fi


chown $CURRENT_USER "$ssPlist"


killall cfprefsd

exit 0