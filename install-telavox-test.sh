#!/bin/bash

# Installs Telavox's test build from their flow-desktop-test bucket instead of the
# official release that install-telavox.sh installs.
# Jamf parameter 4: --force reinstalls even when this build is already installed.

TELAVOX_URL='https://flow-desktop-test.s3.eu-west-2.amazonaws.com/Telavox-2.6.1.dmg'
TEAM_ID='UZBXX7DZB7'
APP_LOCATION=/Applications/Telavox.app
STATE_FILE='/Library/Application Support/Zensum/telavox-test-build'

echo "`date` | Running Telavox test installer with args $@"

FORCE=0

if [[ "$4" == "--force" ]]; then
    echo "`date` | Forcing install"
    FORCE=1
fi

installed_cdhash() {
    codesign -dvvv "$APP_LOCATION" 2>&1 | awk -F= '/^CDHash=/{print $2}'
}

signed_team_id() {
    codesign -dv "$1" 2>&1 | awk -F= '/^TeamIdentifier=/{print $2}'
}

# The test bucket isn't Telavox's official download, so only accept an app that
# is intact and signed by Telavox's Developer ID.
is_telavox_signed() {
    codesign --verify --deep --strict "$1" && [[ "$(signed_team_id "$1")" == "$TEAM_ID" ]]
}

# The test build has the same version number as the official release, so the
# version string can't tell them apart. The disk image's S3 ETag identifies the
# build, and the app's CDHash shows it is still the copy this script installed.
echo "`date` | Fetching test build ETag from $TELAVOX_URL"
LATEST_ETAG=$(curl -sfI "$TELAVOX_URL" | awk 'tolower($1)=="etag:"{print $2}' | tr -d '"\r')
if [ -z "$LATEST_ETAG" ]; then
    echo "`date` | Could not reach $TELAVOX_URL"
    exit 1
fi
echo "`date` | Test build ETag is $LATEST_ETAG"

if [ -e "$APP_LOCATION" ] && [ -e "$STATE_FILE" ]; then
    read -r INSTALLED_ETAG INSTALLED_CDHASH < "$STATE_FILE"
    if [[ "$INSTALLED_ETAG" == "$LATEST_ETAG" && "$INSTALLED_CDHASH" == "$(installed_cdhash)" ]]; then
        echo "`date` | Test build already installed at $APP_LOCATION"
        if [[ $FORCE == 0 ]]; then
            echo "`date` | Not forcing install, exiting"
            exit 0
        fi
        echo "`date` | Forcing install"
    fi
fi

# Private root-only directory, so other local users can't plant or swap the disk
# image or mount point in the world-writable /private/var/tmp.
WORK_DIR=$(mktemp -d /private/var/tmp/telavox-test.XXXXXX) || exit 1
TMP_LOCATION="$WORK_DIR/telavox-test.dmg"
MOUNT_POINT="$WORK_DIR/mount"

cleanup() {
    hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "`date` | Downloading installer disk image from $TELAVOX_URL"
if ! curl -sfL "$TELAVOX_URL" -o "$TMP_LOCATION"; then
    echo "`date` | Download failed"
    exit 1
fi
echo "`date` | Downloaded to $TMP_LOCATION"

echo "`date` | Mounting installer disk image on $MOUNT_POINT"
mkdir "$MOUNT_POINT"
if ! hdiutil attach "$TMP_LOCATION" -mountpoint "$MOUNT_POINT" -nobrowse -noautoopen -quiet; then
    echo "`date` | Could not mount dmg"
    exit 1
fi

NEW_APP="$MOUNT_POINT/Telavox.app"
if [ ! -e "$NEW_APP" ]; then
    echo "`date` | No Telavox.app in disk image"
    exit 1
fi

if ! is_telavox_signed "$NEW_APP"; then
    echo "`date` | $NEW_APP is signed by team '$(signed_team_id "$NEW_APP")' or invalid, expected valid $TEAM_ID signature, not installing"
    exit 1
fi
NEW_VERSION=$(defaults read "$NEW_APP/Contents/Info" CFBundleShortVersionString)
NEW_BUILD=$(defaults read "$NEW_APP/Contents/Info" CFBundleVersion)
echo "`date` | Disk image holds Telavox $NEW_VERSION ($NEW_BUILD) signed by $TEAM_ID"

echo "`date` | Killing Telavox if running."
killall Telavox || echo

echo "`date` | Removing old app at $APP_LOCATION."
rm -rf "$APP_LOCATION"

echo "`date` | Copying app to $APP_LOCATION"
cp -af "$NEW_APP" /Applications/

echo "`date` | Changing permissions on $APP_LOCATION"
chown -R root:wheel "$APP_LOCATION"
chmod -R 755 "$APP_LOCATION"

if ! is_telavox_signed "$APP_LOCATION"; then
    echo "`date` | Installed $APP_LOCATION failed the signature check, removing it"
    rm -rf "$APP_LOCATION"
    exit 1
fi

echo "`date` | Adding quarantine exception for $APP_LOCATION"
spctl --add --label "Telavox" "$APP_LOCATION"

mkdir -p "$(dirname "$STATE_FILE")"
echo "$LATEST_ETAG $(installed_cdhash)" > "$STATE_FILE"
echo "`date` | Installed Telavox test build $LATEST_ETAG"
