#!/bin/bash

TELAVOX_URL='https://deopappmanager.telavox.com/flow/download/mac/latest'
APP_LOCATION=/Applications/Telavox.app


echo "`date` | Fetching Telavox version from $TELAVOX_URL"
DOWNLOAD_URL=$(curl $TELAVOX_URL -i | grep Location: | awk {'print $2'})
FILE_NAME=$(echo $DOWNLOAD_URL | sed -r 's/.*\///' | sed -r 's/\.dmg//g')

LATEST_VERSION=$(echo $FILE_NAME | sed -r 's/\.dmg//g' | sed 's/.*-//' | sed -e 's/[^0-9]*\([0-9]*\)%.*/\1/' | tr -d '\r')
LATEST_VERSION="$LATEST_VERSION"
echo "`date` | Latest version is $LATEST_VERSION from Telavox"

if [ -e $APP_LOCATION ]; then
	CURRENT_VERSION=$(defaults read "$APP_LOCATION/Contents/info" CFBundleShortVersionString)
    echo "`date` | Installed version is $CURRENT_VERSION at $APP_LOCATION"
    if [[ "$LATEST_VERSION" == "$CURRENT_VERSION" ]]; then
        echo "`date` | Already on the latest version"
        exit 0
    fi
else
    echo "`date` | No installation found"
fi

TMP_LOCATION=/tmp/telavox.dmg
echo "`date` | Downloading installer disk image from $DOWNLOAD_URL"
curl $TELAVOX_URL -L -o $TMP_LOCATION

if [ -e $TMP_LOCATION ]; then
    echo "`date` | Downloaded to $TMP_LOCATION"
else
    echo "`date` | Could not find any downloads on $TMP_LOCATION"
    exit 1
fi

while true; do
    MOUNT_PATH=$(df | grep Telavox | sed '1q' | awk '{print $1}')
    if [ -z $MOUNT_PATH ]; then
        break
    elif [ -e $MOUNT_PATH ]; then
        echo "`date` | Detaching $MOUNT_PATH."
        hdiutil detach $MOUNT_PATH -quiet
    fi
done

echo "`date` | Mounting installer disk image."
hdiutil mount $TMP_LOCATION -noverify -nobrowse -noautoopen -quiet
sleep 10

MOUNT_NAME=$(df | grep Telavox | sed '1q' | sed 's/.*Volumes/\/Volumes/' | sed 's/\ *$//g')

if [ -e "$MOUNT_NAME" ]; then
    echo "`date` | Mounted on $MOUNT_NAME"
else
    echo "`date` | Could not mount dmg"
    rm $TMP_LOCATION
    exit 1
fi

echo "`date` | Killing Telavox if running."
killall Telavox || echo

echo "`date` | Removing old app at $APP_LOCATION."
rm -rf $APP_LOCATION

echo "`date` | Copying app to $APP_LOCATION"
cp -r "$MOUNT_NAME/Telavox.app" /Applications/

echo "`date` | Changing permissions on $APP_LOCATION"
chown -R root:wheel $APP_LOCATION
chmod -R 755 $APP_LOCATION

echo "`date` | Unmounting disk image"
hdiutil detach $(df | grep Telavox | awk '{print $1}') -quiet
sleep 10

echo "`date` | Deleting disk image."
rm $TMP_LOCATION

