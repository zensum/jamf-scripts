#!/bin/bash


###############################################################################
################################## VARIABLES ##################################
###############################################################################


dockutil=$(which dockutil)
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
uid=$(id -u "$currentUser")

# convenience function to run a command as the current user
# usage:
#   runAsUser command arguments...
runAsUser() {
  if [ "$currentUser" != "loginwindow" ]; then
    # launchctl asuser "$uid" sudo -u "$currentUser" "$@"
    su "$currentUser" -c "$@"
  else
    echo "no user logged in"
    # uncomment the exit command
    # to make the function exit with an error when no user is logged in
    exit 1
  fi
}


###############################################################################
############################### APPLE DEFAULTS ################################
###############################################################################


runAsUser "$dockutil" --remove 'Launchpad' --no-restart
runAsUser "$dockutil" --remove 'Messages' --no-restart
runAsUser "$dockutil" --remove 'Launchpad' --no-restart
runAsUser "$dockutil" --remove 'Maps' --no-restart
runAsUser "$dockutil" --remove 'Photos' --no-restart
runAsUser "$dockutil" --remove 'FaceTime' --no-restart
runAsUser "$dockutil" --remove 'Contacts' --no-restart
runAsUser "$dockutil" --remove 'Reminders' --no-restart
runAsUser "$dockutil" --remove 'Notes' --no-restart
runAsUser "$dockutil" --remove 'TV' --no-restart
runAsUser "$dockutil" --remove 'Music' --no-restart
runAsUser "$dockutil" --remove 'Podcasts' --no-restart
runAsUser "$dockutil" --remove 'News' --no-restart
runAsUser "$dockutil" --remove 'Numbers' --no-restart
runAsUser "$dockutil" --remove 'Pages' --no-restart


###############################################################################
############################### JAMFY INSTALLS ################################
###############################################################################


if [ -d "/Applications/Slack.app" ] ; then
	runAsUser "$dockutil" --add "/Applications/Slack.app" --no-restart
else
	echo "Slack not installed, skipping Dock placement"
fi

if [ -d "/Applications/Telavox.app" ] ; then
	runAsUser "$dockutil" --add "/Applications/Telavox.app" --position 1 --no-restart
else
	echo "Telavox not installed, skipping Dock placement"
fi


if [ -d "/Applications/Filemaker.app" ] ; then
	runAsUser "$dockutil" --add "/Applications/Filemaker.app" --position 1 --no-restart
else
	echo "Filemaker not installed, skipping Dock placement"
fi

if [ -d "/Applications/Google Chrome.app" ] ; then
	runAsUser "$dockutil" --add "/Applications/Google Chrome.app" --position 1 --no-restart
else
	echo "Google Chrome not installed, skipping Dock placement"
fi

if [ -d "/Applications/Safari.app" ] ; then
	runAsUser "$dockutil" --add "/Applications/Safari.app" --position 1 --no-restart
else
	echo "Safari not installed, skipping Dock placement"
fi

# runAsUser "$dockutil" --add "/Applications/Zensum App Store.app" --before "Safari" --no-restart
runAsUser "$dockutil" --add "/Applications/Zensum App Store.app" --restart

exit 0