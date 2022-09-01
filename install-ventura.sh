#!/bin/bash
install_macos_app=$(find /Applications -type d -name 'Install macOS Ventura*')
if [ -e "$install_macos_app" ]; then
	echo "`date` | Installer already downloaded"
else
	echo "`date` | Downlaoding updates with \"softwareupdate -d -a --product-types macOS --force --fetch-full-installer\""
	softwareupdate --force --fetch-full-installer 13
fi

install_macos_app=$(find /Applications -type d -name 'Install macOS Ventura*')

if [ ! -e "$install_macos_app" ]; then
    echo "`date` | No installer found"
    exit 1
fi

heading="Du kommer nu påböja installationen av macOS Ventura..."
description="

Denna proceess tar vanligtvis 20-30 minuter

När processen är färdig kommer din dator starta om och behöva ytterligare 15-20 minuter för installation."
icon="$install_macos_app/Contents/Resources/InstallAssistant.icns"

##Launch jamfHelper
"/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper" -windowType fs -title "" -icon "$icon" -heading "$heading" -description "$description" &
jamfHelperPID=$!
sleep 20
kill $jamfHelperPID


##Start macOS Upgrade
# Pulls the current logged in user and their UID
currUser=$(ls -l /dev/console | awk '{print $3}')
currUserUID=$(id -u "$currUser")

## making current user admin so that they can run the installer
sudo dseditgroup -o edit -a $currUser -t user admin

/bin/launchctl asuser "$currUserUID" sudo -iu "root" "$install_macos_app/Contents/MacOS/InstallAssistant" &
installationPID=$!

exit 0