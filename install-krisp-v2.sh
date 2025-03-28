#!/bin/bash

APP_LOCATION=/Applications/Krisp.app
case "$(arch)" in
  arm64)
    KRISP_URL='https://api.krisp.ai/v2/download/mac/enterprise/latest?arm=1'
    ;;

  i386)
    KRISP_URL='https://api.krisp.ai/v2/download/mac/enterprise/latest'
    ;;
esac

echo "`date` | Running Krisp installer with args $@"

FORCE=0

if [[ "$4" == "--force" ]]; then
    echo "`date` | Forcing install"
    FORCE=1
fi

echo "`date` | Fetching Krisp version from $KRISP_URL"
DOWNLOAD_URL=$(curl $KRISP_URL -i)
FILE_NAME=$(echo $DOWNLOAD_URL | sed -r 's/.*\///')
# echo "`date` | DOWNLOAD_URL is $DOWNLOAD_URL from Krisp"
# echo "`date` | FILE_NAME is $FILE_NAME from Krisp"
LATEST_VERSION=$(echo $FILE_NAME | sed -E 's/.*_([0-9]+\.[0-9]+\.[0-9]+)_.*\.pkg/\1/')
LATEST_VERSION="$LATEST_VERSION"
echo "`date` | Latest version is $LATEST_VERSION from Krisp"
if [ -e $APP_LOCATION ]; then
	CURRENT_VERSION=$(defaults read "$APP_LOCATION/Contents/info" CFBundleShortVersionString)
    echo "`date` | Installed version is $CURRENT_VERSION at $APP_LOCATION"
    if [[ "$LATEST_VERSION" == "$CURRENT_VERSION" ]]; then
        echo "`date` | Already on the latest version"
        if [[ $FORCE == 0 ]]; then
            echo "`date` | Not forcing install, exiting"
            exit 0
        fi
        echo "`date` | Forcing install"
    fi
else
    echo "`date` | No installation found"
fi

TMP_LOCATION=/private/var/tmp/krisp.pkg
echo "`date` | Downloading installer disk image from $DOWNLOAD_URL"
curl $KRISP_URL -L -o $TMP_LOCATION

if [ -e $TMP_LOCATION ]; then
    echo "`date` | Downloaded to $TMP_LOCATION"
else
    echo "`date` | Could not find any downloads on $TMP_LOCATION"
    exit 1
fi

PACKAGE_NAME=$TMP_LOCATION
echo "`date` | Installing Krisp from $PACKAGE_NAME"

# from Krisp
sudo installer -pkg "$PACKAGE_NAME" -target /

pkill -x "krisp"

# From Krisp Z Enable Krisp transcripts

# Define the JSON content
json_content='{
  "voiceInterpreter": {
    "saveTranslationInfo": true
  }
}'

# Write the JSON content to a temporary file
echo "$json_content" > /tmp/generic.json

# Directory under Library where the file will be placed
target_subdirectory="Library/Application Support/krisp-ent"

# Get the list of all users on the system (excluding system users)
users=$(ls /Users | grep -v '^_')

# Iterate through each user
for user in $users; do
  # Get the home directory of the user
  user_home=$(eval echo "~$user")

  # Define the full target directory path
  target_directory="$user_home/$target_subdirectory"

  # Check if the directory exists; if not, create it with the right permissions
  if [ ! -d "$target_directory" ]; then
    mkdir -p "$target_directory"
    chmod 755 "$target_directory"  # Set permissions to allow all users to read and execute
    chown "$user" "$target_directory"  # Change ownership to the user
  fi

  # Copy the JSON file to the user's target directory
  cp /tmp/generic.json "$target_directory/generic.json"
  chown "$user" "$target_directory/generic.json"  # Change ownership to the user
  echo "Copied JSON file to $target_directory for user $user"
done

# Clean up the temporary file
rm /tmp/generic.json

echo "JSON file distributed to all users' Library directories."
