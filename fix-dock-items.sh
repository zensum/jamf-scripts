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


dockutil –-remove all –-no-restart --all-homes
sleep 1

dockutil --add "/Applications/Safari.app" --position 1 --no-restart --all-homes

if [ -d "/Applications/Google Chrome.app" ] ; then
	dockutil --add "/Applications/Google Chrome.app" --after Safari --no-restart --all-homes
else
	echo "Google Chrome not installed, skipping Dock placement"
fi

if [ -d "/Applications/Telavox.app" ] ; then
	dockutil --add "/Applications/Telavox.app" --after "Google Chrome" --no-restart --all-homes
else
	echo "Telavox not installed, skipping Dock placement"
fi

if [ -d "/Applications/Slack.app" ] ; then
	dockutil --add "/Applications/Slack.app" --after Telavox --no-restart --all-homes
else
	echo "Slack not installed, skipping Dock placement"
fi

dockutil --add "/System/Applications/Calculator.app" --after Slack --no-restart --all-homes

dockutil --add "/System/Applications/Notes.app" --after Calculator --no-restart --all-homes

dockutil --add "/System/Applications/Calendar.app" --after Notes --no-restart --all-homes

if [ -d "/Applications/Filemaker.app" ] ; then
	dockutil --add "/Applications/Filemaker.app" --after Slack --no-restart --all-homes
else
	echo "Filemaker not installed, skipping Dock placement"
fi

dockutil --add "/Applications/Zensum App Store.app" --no-restart --position 100 --all-homes

killall Dock

exit 0