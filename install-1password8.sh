#!/bin/bash


user_id="$(scutil <<< 'show State:/Users/ConsoleUser' | awk '($1 == "Name" && $NF == "loginwindow") { exit } ($1 == "UID") { print $NF; exit }')"

URL="https://downloads.1password.com/mac"
case "$(arch)" in
  arm64)
    FILE="1Password-latest-aarch64.zip"
    ;;

  i386)
    FILE="1Password-latest.zip"
    ;;
esac

echo "`date` | Fetching 1Password from $URL"
/usr/bin/curl -Ls "${URL}/${FILE}" -o /tmp/"${FILE}"
/usr/bin/ditto -xk /tmp/"${FILE}" /Applications/.


old_apps=(
    "/Applications/1Password 6.app"
    "/Applications/1Password 7.app"
    "/Applications/1Password.app"
)

for i in "${old_apps[@]}"; do
    if [[ -d "$i" ]]; then
		echo "`date` | Removing old 1Password installation at $i"
        /bin/rm -rf "$i"
    fi
done

old_launchd=(
    "2BUA8C4S2C.com.agilebits.onepassword7-helper"
    "com.agilebits.onepassword7-launcher"
)

if [[ ! -z "$user_id" ]]; then
    for l in "${old_launchd[@]}"; do
		echo "`date` | Removing old helpers"
        /bin/launchctl asuser "$user_id" /bin/launchctl stop "$l"
        /bin/launchctl asuser "$user_id" /bin/launchctl remove "$l"
    done
fi

echo "`date` | Killing old 1Password"
/usr/bin/killall "1Password 7"

echo "`date` | Moving 1Password out of quartine"
/usr/bin/xattr -r -d com.apple.quarantine "/Applications/1Password.app"

echo "`date` | Cleaning up"
/bin/rm /tmp/"${FILE}"

exit 0

