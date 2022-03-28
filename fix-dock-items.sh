#!/bin/bash


###############################################################################
################################## VARIABLES ##################################
###############################################################################


dockutil=$(which dockutil)
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
homeDict="/Users/zensum/"
if [ "$currentUser" != "loginwindow" ]; then
    # launchctl asuser "$uid" sudo -u "$currentUser" "$@"
    echo "Running as $currentUser"
  else
    echo "no user logged in"
    # uncomment the exit command
    # to make the function exit with an error when no user is logged in
    exit 1
  fi


"$dockutil" –-remove all –no-restart
sleep 1

if [ -d "/Applications/Slack.app" ] ; then
	"$dockutil" --add "/Applications/Slack.app" --no-restart "$homeDict"
else
	echo "Slack not installed, skipping Dock placement"
fi

if [ -d "/Applications/Telavox.app" ] ; then
	"$dockutil" --add "/Applications/Telavox.app" --position 1 --no-restart "$homeDict"
else
	echo "Telavox not installed, skipping Dock placement"
fi


if [ -d "/Applications/Filemaker.app" ] ; then
	"$dockutil" --add "/Applications/Filemaker.app" --position 1 --no-restart "$homeDict"
else
	echo "Filemaker not installed, skipping Dock placement"
fi

if [ -d "/Applications/Google Chrome.app" ] ; then
	"$dockutil" --add "/Applications/Google Chrome.app" --position 1 --no-restart "$homeDict"
else
	echo "Google Chrome not installed, skipping Dock placement"
fi

if [ -d "/Applications/Safari.app" ] ; then
	"$dockutil" --add "/Applications/Safari.app" --position 1 --no-restart "$homeDict"
else
	echo "Safari not installed, skipping Dock placement"
fi

"$dockutil" --add "/Applications/Zensum App Store.app" --restart --position 100 "$homeDict"

exit 0