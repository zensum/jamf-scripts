#!/bin/bash

URL='https://github.com/glouel/AerialCompanion/releases/latest/download'
FILE='AerialCompanion.dmg'
APP_NAME='Aerial Companion'
APP_LOCATION="/Applications/$APP_NAME.app"
APP_GREPPER_NAME='Aerial'

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


echo "`date` | Trying to move and add settings for $APP_NAME from /tmp"

CURRENT_USER=$(echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }')

ditto -xk /tmp/com.glouel.AerialUpdater.zip /Users/$CURRENT_USER/Library/HTTPStorages/.
ditto -xk /tmp/Aerial.saver.zip /Users/$CURRENT_USER/Library/Screen\ Savers/.
ditto -xk /tmp/com.glouel.AerialUpdaterAgent.plist.zip /Users/$CURRENT_USER/Library/LaunchAgents/.

/Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application\ Support/Aerial

echo "`date` | Added settings for $APP_NAME"

exit 0