#!/bin/bash

# Installs a pinned Telavox version instead of latest.
# Jamf params (any position): --force, and a version like 2.5.1 (default 2.5.0).
# Args are scanned instead of read by position, because Jamf can split a
# computer name with spaces into several args and shift $4/$5.

VERSION=2.5.0
FORCE=0
for ARG in "$@"; do
    if [[ "$ARG" == "--force" ]]; then
        FORCE=1
    elif [[ "$ARG" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        VERSION="$ARG"
    fi
done

DOWNLOAD_URL="https://s3.eu-west-2.amazonaws.com/flow-desktop/Telavox-$VERSION.dmg"
APP_LOCATION=/Applications/Telavox.app
TMP_LOCATION=/private/var/tmp/telavox-$VERSION.dmg
MOUNT_POINT=/private/var/tmp/telavox-mount

echo "`date` | Running pinned version Telavox installer with args $@"
echo "`date` | Pinned version is $VERSION, force is $FORCE"

if [ -e $APP_LOCATION ]; then
    CURRENT_VERSION=$(defaults read "$APP_LOCATION/Contents/Info" CFBundleShortVersionString)
    echo "`date` | Installed version is $CURRENT_VERSION at $APP_LOCATION"
    if [[ "$VERSION" == "$CURRENT_VERSION" && $FORCE == 0 ]]; then
        echo "`date` | Already on version $VERSION, exiting"
        exit 0
    fi
else
    echo "`date` | No installation found"
fi

echo "`date` | Downloading Telavox $VERSION from $DOWNLOAD_URL"
if ! curl -fL -o $TMP_LOCATION "$DOWNLOAD_URL"; then
    echo "`date` | Could not download $DOWNLOAD_URL"
    rm -f $TMP_LOCATION
    exit 1
fi

# Leftover mount from a failed run would make attach fail
hdiutil detach $MOUNT_POINT -quiet 2>/dev/null

echo "`date` | Mounting installer disk image on $MOUNT_POINT"
if ! hdiutil attach $TMP_LOCATION -mountpoint $MOUNT_POINT -nobrowse -noautoopen -readonly -quiet; then
    echo "`date` | Could not mount dmg"
    rm -f $TMP_LOCATION
    exit 1
fi

# Old S3 files are not listed by Telavox, so check we got a real signed app
if ! codesign --verify --deep --strict "$MOUNT_POINT/Telavox.app" || \
   ! codesign -dv "$MOUNT_POINT/Telavox.app" 2>&1 | grep -q "TeamIdentifier=UZBXX7DZB7"; then
    echo "`date` | Telavox.app in dmg is not signed by Telavox AB, aborting"
    hdiutil detach $MOUNT_POINT -quiet
    rm -f $TMP_LOCATION
    exit 1
fi

echo "`date` | Killing Telavox if running."
killall Telavox || echo

echo "`date` | Removing old app at $APP_LOCATION."
rm -rf $APP_LOCATION

echo "`date` | Copying app to $APP_LOCATION"
cp -af "$MOUNT_POINT/Telavox.app" /Applications/

echo "`date` | Changing permissions on $APP_LOCATION"
chown -R root:wheel $APP_LOCATION
chmod -R 755 $APP_LOCATION

echo "`date` | Adding quarantine exception for $APP_LOCATION"
spctl --add --label "Telavox" $APP_LOCATION

echo "`date` | Unmounting disk image"
hdiutil detach $MOUNT_POINT -quiet

echo "`date` | Deleting disk image."
rm -f $TMP_LOCATION

echo "`date` | Installed Telavox $(defaults read "$APP_LOCATION/Contents/Info" CFBundleShortVersionString)"
