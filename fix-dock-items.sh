#!/bin/bash


###############################################################################
################################## VARIABLES ##################################
###############################################################################


dockutil=$(which dockutil)
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
if [ "$currentUser" != "loginwindow" ]; then
    # launchctl asuser "$uid" sudo -u "$currentUser" "$@"
    echo "Running as $currentUser"
  else
    echo "no user logged in"
    # uncomment the exit command
    # to make the function exit with an error when no user is logged in
    exit 1
  fi

plistFile="/Users/zensum/Library/Preferences/com.apple.dock.plist "


###############################################################################
############################### APPLE DEFAULTS ################################
###############################################################################


"$dockutil" --remove 'Launchpad' --no-restart "$plistFile"
"$dockutil" --remove 'Messages' --no-restart "$plistFile"
"$dockutil" --remove 'Launchpad' --no-restart "$plistFile"
"$dockutil" --remove 'Maps' --no-restart "$plistFile"
"$dockutil" --remove 'Photos' --no-restart "$plistFile"
"$dockutil" --remove 'FaceTime' --no-restart "$plistFile"
"$dockutil" --remove 'Contacts' --no-restart "$plistFile"
"$dockutil" --remove 'Reminders' --no-restart "$plistFile"
"$dockutil" --remove 'Notes' --no-restart "$plistFile"
"$dockutil" --remove 'TV' --no-restart "$plistFile"
"$dockutil" --remove 'Music' --no-restart "$plistFile"
"$dockutil" --remove 'Podcasts' --no-restart "$plistFile"
"$dockutil" --remove 'News' --no-restart "$plistFile"
"$dockutil" --remove 'Numbers' --no-restart "$plistFile"
"$dockutil" --remove 'Pages' --no-restart "$plistFile"


###############################################################################
############################### JAMFY INSTALLS ################################
###############################################################################


if [ -d "/Applications/Slack.app" ] ; then
	"$dockutil" --add "/Applications/Slack.app" --no-restart "$plistFile"
else
	echo "Slack not installed, skipping Dock placement"
fi

if [ -d "/Applications/Telavox.app" ] ; then
	"$dockutil" --add "/Applications/Telavox.app" --position 1 --no-restart "$plistFile"
else
	echo "Telavox not installed, skipping Dock placement"
fi


if [ -d "/Applications/Filemaker.app" ] ; then
	"$dockutil" --add "/Applications/Filemaker.app" --position 1 --no-restart "$plistFile"
else
	echo "Filemaker not installed, skipping Dock placement"
fi

if [ -d "/Applications/Google Chrome.app" ] ; then
	"$dockutil" --add "/Applications/Google Chrome.app" --position 1 --no-restart "$plistFile"
else
	echo "Google Chrome not installed, skipping Dock placement"
fi

if [ -d "/Applications/Safari.app" ] ; then
	"$dockutil" --add "/Applications/Safari.app" --position 1 --no-restart "$plistFile"
else
	echo "Safari not installed, skipping Dock placement"
fi

# "$dockutil" --add "/Applications/Zensum App Store.app" --before "Safari" --no-restart "$plistFile"
"$dockutil" --add "/Applications/Zensum App Store.app" --restart --position 100 "$plistFile"

exit 0