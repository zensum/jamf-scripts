#!/bin/bash

# Installs the latest Telavox release.
# Jamf parameters, in any of the parameter fields and in any order:
#   --force           Reinstall even when the latest version is already installed.
#   --waves=P:D,...   Roll an upgrade out in waves. Each wave is P percent of the
#                     computers, upgraded once the latest release is D days old,
#                     e.g. --waves=10:1,30:3,60:5. The percents must add up to 100.
#                     A hash of the computer's hardware UUID picks its wave, so a
#                     computer stays in the same wave on every run.
#   --delay-days=N    Upgrade every computer once the latest release is N days old.
#                     Same as --waves=100:N.
# A release's age counts from the Last-Modified date of Telavox's disk image. A
# computer without Telavox installs right away. With --waves or --delay-days the
# policy must run on a recurring trigger, so a computer that waits retries later.
# Parameters are matched by name, not position, because Jamf can split a computer
# name with spaces into several args and shift the positions.

TELAVOX_URL='https://deopappmanager.telavox.com/flow/download/mac/latest'
APP_LOCATION=/Applications/Telavox.app

echo "`date` | Running Telavox installer with args $@"

FORCE=0
WAVES=""
WAVE_ARGS=0

for ARG in "$@"; do
    case "$ARG" in
        --force) FORCE=1 ;;
        --delay-days=*) WAVES="100:${ARG#--delay-days=}"; WAVE_ARGS=$((WAVE_ARGS + 1)) ;;
        --waves=*) WAVES="${ARG#--waves=}"; WAVE_ARGS=$((WAVE_ARGS + 1)) ;;
        # A misspelled rollout parameter would otherwise upgrade with no delay
        *--delay-days*|*--waves*)
            echo "`date` | Invalid parameter '$ARG', use --waves=P:D,... or --delay-days=N in its own field"
            exit 1
            ;;
    esac
done

if [[ $FORCE == 1 ]]; then
    echo "`date` | Forcing install"
fi

if [ $WAVE_ARGS -gt 1 ]; then
    echo "`date` | Give only one --waves or --delay-days parameter"
    exit 1
fi

if [ $WAVE_ARGS -gt 0 ]; then
    WAVES_PATTERN='^[0-9]+:[0-9]+(,[0-9]+:[0-9]+)*$'
    if ! [[ $WAVES =~ $WAVES_PATTERN ]]; then
        echo "`date` | Invalid waves '$WAVES', expected percent:days pairs like 10:1,30:3,60:5"
        exit 1
    fi
    TOTAL_PERCENT=0
    for WAVE in ${WAVES//,/ }; do
        TOTAL_PERCENT=$((TOTAL_PERCENT + 10#${WAVE%%:*}))
    done
    if [ $TOTAL_PERCENT -ne 100 ]; then
        echo "`date` | Invalid waves '$WAVES', the percents add up to $TOTAL_PERCENT, not 100"
        exit 1
    fi
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

    if [[ "$LATEST_VERSION" != "$CURRENT_VERSION" && -n "$WAVES" ]]; then
        HARDWARE_UUID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}')
        if [ -z "$HARDWARE_UUID" ]; then
            echo "`date` | Could not read the hardware UUID to pick a wave, not upgrading"
            exit 1
        fi
        UUID_HASH=$(/sbin/md5 -q -s "$HARDWARE_UUID")
        BUCKET=$((0x${UUID_HASH:0:8} % 100))
        WAVE_NUMBER=0
        WAVE_END=0
        for WAVE in ${WAVES//,/ }; do
            WAVE_NUMBER=$((WAVE_NUMBER + 1))
            WAVE_END=$((WAVE_END + 10#${WAVE%%:*}))
            DELAY_DAYS=$((10#${WAVE##*:}))
            if [ $BUCKET -lt $WAVE_END ]; then
                break
            fi
        done
        echo "`date` | Computer is in bucket $BUCKET, wave $WAVE_NUMBER of $WAVES, delay is $DELAY_DAYS days"

        if [ $DELAY_DAYS -gt 0 ]; then
            LAST_MODIFIED=$(curl -sIL $TELAVOX_URL | awk 'tolower($1)=="last-modified:"' | tail -1 | cut -d' ' -f2- | tr -d '\r')
            RELEASED_AT=$(LC_ALL=C /bin/date -j -u -f '%a, %d %b %Y %H:%M:%S GMT' "$LAST_MODIFIED" +%s 2>/dev/null)
            if [ -z "$RELEASED_AT" ]; then
                echo "`date` | Could not read release date from Last-Modified '$LAST_MODIFIED', not upgrading"
                exit 1
            fi
            INSTALL_AFTER=$((RELEASED_AT + DELAY_DAYS * 86400))
            echo "`date` | Version $LATEST_VERSION was released `/bin/date -r $RELEASED_AT`"
            if [ "$(/bin/date +%s)" -lt "$INSTALL_AFTER" ]; then
                echo "`date` | Not upgrading before `/bin/date -r $INSTALL_AFTER`, exiting"
                exit 0
            fi
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

