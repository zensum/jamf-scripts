#!/bin/bash


###############################################################################
################################## VARIABLES ##################################
###############################################################################


currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
homeDict="/Users/$currentUser/"
if [ "$currentUser" != "loginwindow" ]; then
    # launchctl asuser "$uid" sudo -u "$currentUser" "$@"
    echo "Running as $currentUser"
  else
    echo "no user logged in"
    # uncomment the exit command
    # to make the function exit with an error when no user is logged in
    exit 1
  fi


dockutil --remove all --no-restart $homeDict
# dock_items_str="$(dockutil --list $homeDict | awk -F '\t' '{print $1}')"
# IFS='
# '
# #Read the split lines an array based on comma delimiter
# read -a strarr <<< "$dock_items_Str"
# for item in $dock_items;
# do
#   echo "Removing $item"
#   dockutil_command="dockutil –-remove '$item' $homeDict --no-restart"
#   echo "Running command: $dockutil_command"
#   /bin/bash -c "$($dockutil_command)"
#   sleep 15
# done
sleep 1

dockutil --add "/Applications/Safari.app" --position 1 --no-restart --allhomes

if [ -d "/Applications/Google Chrome.app" ] ; then
	dockutil --add "/Applications/Google Chrome.app" --after Safari --no-restart --allhomes
else
	echo "Google Chrome not installed, skipping Dock placement"
fi

if [ -d "/Applications/Telavox.app" ] ; then
	dockutil --add "/Applications/Telavox.app" --after "Google Chrome" --no-restart --allhomes
else
	echo "Telavox not installed, skipping Dock placement"
fi

if [ -d "/Applications/Slack.app" ] ; then
	dockutil --add "/Applications/Slack.app" --after Telavox --no-restart --allhomes
else
	echo "Slack not installed, skipping Dock placement"
fi

dockutil --add "/System/Applications/Calculator.app" --after Slack --no-restart --allhomes

dockutil --add "/System/Applications/Notes.app" --after Calculator --no-restart --allhomes

dockutil --add "/System/Applications/Calendar.app" --after Notes --no-restart --allhomes

if [ -d "/Applications/Filemaker Pro 16/Filemaker Pro.app" ] ; then
	dockutil --add "/Applications/Filemaker Pro 16/Filemaker Pro.app" --after Slack --no-restart --allhomes
else
	echo "Filemaker not installed, skipping Dock placement"
fi

dockutil --add "/Applications/Zensum App Store.app" --no-restart --position 100 --allhomes

killall Dock

exit 0