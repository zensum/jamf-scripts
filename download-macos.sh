#!/bin/bash
install_macos_app=$(find /Applications -type d -name 'Install macOS *')
if [ -e "$install_macos_app" ]; then
	echo "`date` | Installer already downloaded as $install_macos_app"
else
	echo "`date` | Downlaoding updates with \"softwareupdate --force --fetch-full-installer $4\""
	softwareupdate --force --fetch-full-installer $4
fi

install_macos_app=$(find /Applications -type d -name 'Install macOS *')

if [ ! -e "$install_macos_app" ]; then
    echo "`date` | No installer found, download failed"
    exit 1
else
	echo "`date` | Installer downloaded as $install_macos_app"
	exit 0
fi
