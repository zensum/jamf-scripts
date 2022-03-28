#!/bin/bash


###############################################################################
################################## VARIABLES ##################################
###############################################################################


dockutil=$(which dockutil)
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
# uid=$(id -u "$currentUser")

# convenience function to run a command as the current user
# usage:
#   runAsUser command arguments...
# runAsUser() {
#   if [ "$currentUser" != "loginwindow" ]; then
#     # launchctl asuser "$uid" sudo -u "$currentUser" "$@"
#     su "$currentUser" -c "$@"
#   else
#     echo "no user logged in"
#     # uncomment the exit command
#     # to make the function exit with an error when no user is logged in
#     exit 1
#   fi
# }

if [ "$currentUser" != "loginwindow" ]; then
    # launchctl asuser "$uid" sudo -u "$currentUser" "$@"
    echo "Running as $currentUser"
  else
    echo "no user logged in"
    # uncomment the exit command
    # to make the function exit with an error when no user is logged in
    exit 1
  fi


###############################################################################
############################### APPLE DEFAULTS ################################
###############################################################################


su "$currentUser" -c "$dockutil" --remove 'Launchpad' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Messages' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Launchpad' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Maps' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Photos' --no-restart
su "$currentUser" -c "$dockutil" --remove 'FaceTime' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Contacts' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Reminders' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Notes' --no-restart
su "$currentUser" -c "$dockutil" --remove 'TV' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Music' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Podcasts' --no-restart
su "$currentUser" -c "$dockutil" --remove 'News' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Numbers' --no-restart
su "$currentUser" -c "$dockutil" --remove 'Pages' --no-restart


###############################################################################
############################### JAMFY INSTALLS ################################
###############################################################################


if [ -d "/Applications/Slack.app" ] ; then
	su "$currentUser" -c "$dockutil" --add "/Applications/Slack.app" --no-restart
else
	echo "Slack not installed, skipping Dock placement"
fi

if [ -d "/Applications/Telavox.app" ] ; then
	su "$currentUser" -c "$dockutil" --add "/Applications/Telavox.app" --position 1 --no-restart
else
	echo "Telavox not installed, skipping Dock placement"
fi


if [ -d "/Applications/Filemaker.app" ] ; then
	su "$currentUser" -c "$dockutil" --add "/Applications/Filemaker.app" --position 1 --no-restart
else
	echo "Filemaker not installed, skipping Dock placement"
fi

if [ -d "/Applications/Google Chrome.app" ] ; then
	su "$currentUser" -c "$dockutil" --add "/Applications/Google Chrome.app" --position 1 --no-restart
else
	echo "Google Chrome not installed, skipping Dock placement"
fi

if [ -d "/Applications/Safari.app" ] ; then
	su "$currentUser" -c "$dockutil" --add "/Applications/Safari.app" --position 1 --no-restart
else
	echo "Safari not installed, skipping Dock placement"
fi

# su "$currentUser" -c "$dockutil" --add "/Applications/Zensum App Store.app" --before "Safari" --no-restart
su "$currentUser" -c "$dockutil" --add "/Applications/Zensum App Store.app" --restart

exit 0