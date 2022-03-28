#!/bin/bash


###############################################################################
################################## VARIABLES ##################################
###############################################################################


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


dockutil –-remove all –no-restart
sleep 1

dockutil --add "/Applications/Safari.app" --position 1 --no-restart "$homeDict"

if [ -d "/Applications/Google Chrome.app" ] ; then
	dockutil --add "/Applications/Google Chrome.app" --after Safari --no-restart "$homeDict"
else
	echo "Google Chrome not installed, skipping Dock placement"
fi

if [ -d "/Applications/Telavox.app" ] ; then
	dockutil --add "/Applications/Telavox.app" --after "Google Chrome" --no-restart "$homeDict"
else
	echo "Telavox not installed, skipping Dock placement"
fi

if [ -d "/Applications/Slack.app" ] ; then
	dockutil --add "/Applications/Slack.app" --after Telavox --no-restart "$homeDict"
else
	echo "Slack not installed, skipping Dock placement"
fi

dockutil --add "/Applications/Calculator.app" --after Slack --no-restart "$homeDict"

dockutil --add "/Applications/Notes.app" --after Calculator --no-restart "$homeDict"

dockutil --add "/Applications/Calendar.app" --after Notes --no-restart "$homeDict"

if [ -d "/Applications/Filemaker.app" ] ; then
	dockutil --add "/Applications/Filemaker.app" --after Slack --no-restart "$homeDict"
else
	echo "Filemaker not installed, skipping Dock placement"
fi

dockutil --add "/Applications/Zensum App Store.app" --restart --position 100 "$homeDict"

exit 0