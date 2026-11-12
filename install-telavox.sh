#!/bin/bash

# Installs the latest Telavox release.
# Jamf parameters, in any of the parameter fields and in any order:
#   --force           Reinstall even when the latest version is already installed.
#   --delay-days=N    Upgrade an installed Telavox only once the latest release is
#                     N days old, counted from the Last-Modified date of Telavox's
#                     disk image. A computer without Telavox installs right away.
#                     The policy must run on a recurring trigger so it retries.
# Parameters are matched by name, not position, because Jamf can split a computer
# name with spaces into several args and shift the positions.

TELAVOX_URL='https://deopappmanager.telavox.com/flow/download/mac/latest'
APP_LOCATION=/Applications/Telavox.app

echo "`date` | Running Telavox installer with args $@"

FORCE=0
DELAY_DAYS=0

for ARG in "$@"; do
    case "$ARG" in
        --force) FORCE=1 ;;
        --delay-days=*) DELAY_DAYS="${ARG#--delay-days=}" ;;
    esac
done

if [[ $FORCE == 1 ]]; then
    echo "`date` | Forcing install"
fi

if ! [[ "$DELAY_DAYS" =~ ^[0-9]+$ ]]; then
    echo "`date` | Invalid --delay-days value '$DELAY_DAYS', expected a whole number of days"
    exit 1
fi

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
        if [[ $FORCE == 0 ]]; then
            echo "`date` | Not forcing install, exiting"
            exit 0
        fi
        echo "`date` | Forcing install"
    fi

    if [[ "$LATEST_VERSION" != "$CURRENT_VERSION" && $DELAY_DAYS -gt 0 ]]; then
        LAST_MODIFIED=$(curl -sIL $TELAVOX_URL | awk 'tolower($1)=="last-modified:"' | tail -1 | cut -d' ' -f2- | tr -d '\r')
        RELEASED_AT=$(LC_ALL=C /bin/date -j -u -f '%a, %d %b %Y %H:%M:%S GMT' "$LAST_MODIFIED" +%s 2>/dev/null)
        if [ -z "$RELEASED_AT" ]; then
            echo "`date` | Could not read release date from Last-Modified '$LAST_MODIFIED', not upgrading"
            exit 1
        fi
        INSTALL_AFTER=$((RELEASED_AT + DELAY_DAYS * 86400))
        echo "`date` | Version $LATEST_VERSION was released `/bin/date -r $RELEASED_AT`, delay is $DELAY_DAYS days"
        if [ "$(/bin/date +%s)" -lt "$INSTALL_AFTER" ]; then
            echo "`date` | Not upgrading before `/bin/date -r $INSTALL_AFTER`, exiting"
            exit 0
        fi
    fi
else
    echo "`date` | No installation found"
fi

TMP_LOCATION=/private/var/tmp/telavox.dmg
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
cp -af "$MOUNT_NAME/Telavox.app" /Applications/

echo "`date` | Changing permissions on $APP_LOCATION"
chown -R root:wheel $APP_LOCATION
chmod -R 755 $APP_LOCATION

echo "`date` | Adding quarantine exception for $APP_LOCATION"
spctl --add --label "Telavox" $APP_LOCATION
# chmod +x /Applications/Telavox.app/Contents/MacOS/Telavox || echo

echo "`date` | Unmounting disk image"
hdiutil detach $(df | grep Telavox | awk '{print $1}') -quiet
sleep 10

echo "`date` | Deleting disk image."
rm $TMP_LOCATION

