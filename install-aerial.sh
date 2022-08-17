#!/bin/bash

URL='https://github.com/JohnCoates/Aerial/releases/latest/download'
FILE='Aerial.saver.zip'
APP_NAME='Aerial' # assuming it's a pretty name for jamf ui
CURRENT_USER=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
SCREENSAVER_FILENAME="Aerial.saver"
SCREENSAVERS_PATH="/Users/$CURRENT_USER/Library/Screen Savers"
SCREENSAVER_LOCATION="$SCREENSAVERS_PATH/$SCREENSAVER_FILENAME"

REINSTALL=""
ARGS=$@
if [[ " ${ARGS[*]} " =~ " -r " ]]; then
    echo "`date` | Reinstall requested with -r"
    REINSTALL=1
fi

### Check if installed or not
INSTALLED_VERSION=""
if [ -d "$SCREENSAVER_LOCATION" ]; then
    INSTALLED_VERSION=$(defaults read "$SCREENSAVER_LOCATION/Contents/info" CFBundleShortVersionString)
    if [ $? -ne 0 ]; then
        echo "`date` | Could not read installed version of $SCREENSAVER_LOCATION"
        echo "`date` | Deleting current installation at $SCREENSAVER_LOCATION"
        rm -rf $SCREENSAVER_LOCATION
        INSTALLED_VERSION=""
    else
        echo "`date` | Installed version of $APP_NAME is $INSTALLED_VERSION at $SCREENSAVER_LOCATION"
    fi
else
    echo "`date` | No current installation of $APP_NAME found as $SCREENSAVER_LOCATION"
fi

# Grab latest version
echo "`date` | Downloading zip from $URL/$FILE"
TMP_SAVER=/tmp/Aerial.saver # this is the unzipped file
TMP_LOCATION="$TMP_SAVER.zip"
/usr/bin/curl -Ls "${URL}/${FILE}" -o "$TMP_LOCATION"

if [ -e $TMP_LOCATION ]; then
    echo "`date` | Downloaded $APP_NAME to $TMP_LOCATION"
else
    echo "`date` | Could not find any downloads for $APP_NAME on $TMP_LOCATION"
    exit 1
fi

if [ -d $TMP_SAVER ]; then
    echo "`date` | Found old screensaver removing $TMP_SAVER"
    rm -rf $TMP_SAVER
fi

# unzip the screensaver
unzip -q -o "$TMP_LOCATION" -d /tmp # you can remove -v to remove the debug stuff, or "tar xop " instead of unzip if your script runs very very early

if [ $? -ne 0 ]; then
    echo "`date` | Unzip failed for $APP_NAME on $TMP_LOCATION to $TMP_SAVER"
    exit 1
fi

if [ -d "$SCREENSAVER_LOCATION" ]; then
    LATEST_VERSION=$(plutil -p "$TMP_SAVER/Contents/Info.plist" | grep CFBundleShortVersionString | awk '{print $3}' | sed 's/[^0-9\.]*//g')
    if [ $? -ne 0 ]; then
        echo "`date` | Could not read latest version of $SCREENSAVER_LOCATION"
        echo "`date` | Deleting current installation at $SCREENSAVER_LOCATION"
        rm -rf "$SCREENSAVER_LOCATION"
        LATEST_VERSION="x"
    else
        echo "`date` | Latest version of $APP_NAME is $LATEST_VERSION at $SCREENSAVER_LOCATION"
        if [ $INSTALLED_VERSION == $LATEST_VERSION ] && [ ! $REINSTALL ]; then
            echo "`date` | Already on the latest version $LATEST_VERSION"
            exit 0
        else
            echo "`date` | Downloaded the latest version $LATEST_VERSION"
        fi
        echo "`date` | Removing old version of $APP_NAME at $SCREENSAVER_LOCATION"
        rm -rf "$SCREENSAVER_LOCATION"
    fi
fi


echo "`date` | Moving $TMP_SAVER/$FILE_NAME to $SCREENSAVERS_PATH"
mkdir -p "$SCREENSAVERS_PATH"
mv -f "$TMP_SAVER" "$SCREENSAVERS_PATH"
chown -R $CURRENT_USER "$SCREENSAVER_LOCATION"

echo "`date` | Deleting zip file at $TMP_LOCATION for $APP_NAME"
rm $TMP_LOCATION

# Display the screensaver version installed, this works too for .saver ;)
NEWLY_INSTALLED_VERSION=$(defaults read "$SCREENSAVER_LOCATION/Contents/info" CFBundleShortVersionString)
echo "`date` | Successfully installed $APP_NAME with version $NEWLY_INSTALLED_VERSION"

if [ $INSTALLED_VERSION ] && [ ! $REINSTALL ]; then
    echo "`date` | Update completed for $APP_NAME from $INSTALLED_VERSION to $NEWLY_INSTALLED_VERSION"
    killall cfprefsd
    exit 0
fi

# macOS sometimes does not create this folder
echo "`date` | Creating empty folder /Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application\ Support/Aerial/ for cache"
mkdir -p /Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Application\ Support/Aerial

echo "`date` | Added settings for $APP_NAME"

# adapted from https://support.carouselsignage.com/hc/en-us/articles/360047317971-Jamf-Setup-macOS-Screen-Saver-for-Carousel-Cloud
HUUID=$(system_profiler SPHardwareDataType | awk '/Hardware UUID/ {print $3}')
ssPlist="/Users/$CURRENT_USER/Library/Preferences/ByHost/com.apple.screensaver.$HUUID.plist"

mkdir -p "/Users/$CURRENT_USER/Library/Preferences/ByHost"

# set the screen saver for the current user to the one $SCd
echo "`date` | Adding settings for $CURRENT_USER"

/usr/libexec/PlistBuddy -c "Print moduleDict" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add :moduleDict dict" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print moduleDict:moduleName" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add :moduleDict:moduleName string Aerial" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set :moduleDict:moduleName Aerial" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print moduleDict:path" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add :moduleDict:path string $SCREENSAVER_LOCATION" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set :moduleDict:path $SCREENSAVER_LOCATION" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print showClock" $ssPlist
if [ $? -eq 1 ]; then
    /usr/libexec/PlistBuddy -c "Add showClock string NO" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set showClock NO" $ssPlist
fi

/usr/libexec/PlistBuddy -c "Print idleTime" $ssPlist
if [ $? -eq 1 ]; then
    # 300 seconds = 5 minutes
    /usr/libexec/PlistBuddy -c "Add idleTime int 300" $ssPlist
else
    /usr/libexec/PlistBuddy -c "Set idleTime 300" $ssPlist
fi

chown -R $CURRENT_USER "$ssPlist"

SETTINGS_FOLDER="/Users/$CURRENT_USER/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost"
PROPERTY_LIST="$SETTINGS_FOLDER/com.JohnCoates.aerial.$HUUID.plist"

if [ ! -f "$PROPERTY_LIST" ]; then
    echo "`date` | Creating empty property list at $PROPERTY_LIST"
    mkdir -p "$SETTINGS_FOLDER"
    touch "$PROPERTY_LIST"
else
    if [ ! $REINSTALL ]; then
        echo "`date` | Property list already exists at $PROPERTY_LIST"
        exit 0
    else
        echo "`date` | Removing old settings at $PROPERTY_LIST"
        rm $PROPERTY_LIST
    fi
fi


echo "`date` | Writing new $APP_NAME settings"
BASE64_CONFIG='YnBsaXN0MDDfEBMBAgMEBQYHCAkKCwwNDg8QERITFBUWFxgZGhoaHR4fLBYXjo8aql1MYXllckxv
Y2F0aW9uWmNhY2hlTGltaXRYdGltZU1vZGVZZGVidWdNb2RlXxAUYXBwbGVNdXNpY1N0b3JlRnJv
bnRWbGF5ZXJzXxAYaGlnaFF1YWxpdHlUZXh0UmVuZGVyaW5nXxAQZW5hYmxlTWFuYWdlbWVudF5m
aXJzdFRpbWVTZXR1cF8QE2ludENhY2hlUGVyaW9kaWNpdHleaW50VmlkZW9Gb3JtYXRec291cmNl
c0VuYWJsZWRdZHVyYXRpb25DYWNoZV8QFWludFJlZnJlc2hQZXJpb2RpY2l0eV1kaW1CcmlnaHRu
ZXNzXmxhc3RWaWRlb0NoZWNrXxATbmV3U2hvdWxkUGxheVN0cmluZ18QFWRhcmtNb2RlTmlnaHRP
dmVycmlkZVpMYXllckNsb2NrXxCCewogICJjb3JuZXIiIDogMywKICAiZGlzcGxheXMiIDogMCwK
ICAiZm9udE5hbWUiIDogIkhlbHZldGljYU5ldWUtTWVkaXVtIiwKICAiZm9udFNpemUiIDogMTgs
CiAgImlzRW5hYmxlZCIgOiB0cnVlLAogICJ0aW1lIiA6IDAKfRAKEAAIVlN3ZWRlbl8QcVsKICAi
bWVzc2FnZSIsCiAgImNsb2NrIiwKICAiZGF0ZSIsCiAgImxvY2F0aW9uIiwKICAiYmF0dGVyeSIs
CiAgIndlYXRoZXIiLAogICJjb3VudGRvd24iLAogICJ0aW1lciIsCiAgIm11c2ljIgpdCQkJEAEQ
BNYgISIjJCUXFxcXGhdXdHZPUyAxMld0dk9TIDExV3R2T1MgMTBfECJGcm9tIEpvc2h1YSBNaWNo
YWVscyAmIEhhbCBCZXJnbWFuV3R2T1MgMTVXdHZPUyAxMwgICAgJCN8QMC0uLzAxMjM0NTY3ODk6
Ozw9Pj9AQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVpbXF1eX2BhYmNkZWZnaGlqa2xtbm9wcXJz
dHV2d3h5ent8fX5/gIGCg4SFhoeIiYqLjF8QJEM4NTU5ODgzLTZGM0UtNEFGMi04OTYwLTkwMzcx
MENENDdCN18QJDU4MUE0RjFBLTJCNkQtNDY4Qy1BMUJFLTZGNDczRjA2RDEwQl8QJEFFMDExNUFF
LUM1M0ItNERCOS1CMTJGLUNBNEI3QjYzMENDOV8QJEFGQTIyQzA4LUE0ODYtNENFOC05QTEzLUUz
NTVCNkMzODU1OV8QJDg1Q0U3N0JGLTM0MTMtNEE3Qi05QjBGLTczMkU5NjIyOUE3M18QJDgyMTc1
QzFGLTE1M0MtNEVDOC1BRTM3LTI4NjBFQTgyODAwNF8QJDhDMzFCMDZGLTkxQTQtNEY3Qy05M0VE
LTU2MTQ2RDdGNDhCOV8QJDc3MTlCNDhBLTIwMDUtNDAxMS05MjgwLTJGNjRFRUM2RkQ5MV8QJDEw
ODgyMTdDLTE0MTAtNENGNy1CREU5LThGNTczQTREQkNEOV8QJERBRDgyRENFLUYzQUUtNEFFQy04
QTc5LTE2OTRENDEyRkMwQV8QJDc4OTExQjdFLTNDNjktNDdBRC1CNjM1LTlDMjQ4NkY2MzAxRF8Q
JDdGNEMyNkMyLTY3QzItNEMzQS04RjA3LThBN0JGNjE0OEM5N18QJEJBNEVDQTExLTU5MkYtNDcy
Ny05MjIxLUQyQTMyQTE2RUIyOF8QJEVDNjc3MjZBLTgyMTItNEM1RS04M0NGLTg0MTI5MzI3NDBE
Ml8QJDRBRDk5OTA3LTlFNzYtNDA4RC1BN0ZDLTg0MjlGRjAxNDIwMV8QJEVFNTMzRkJELTkwQUUt
NDE5QS1BRDEzLUQ3QTYwRTIwMTVENl8QJDIyMTYyQTlCLURCOTAtNDUxNy04NjdDLUM2NzZCQzNF
OEU5NV8QJDgzQzY1QzkwLTI3MEMtNDQ5MC05QzY5LUY1MUZFMDNEN0YwNl8QJDI3QTM3QjBGLTcz
OEQtNDY0NC1BN0E0LUUzM0U3QTZDMTE3NV8QJEU0ODdDNkVGLUIzRkItNDI3Qi1BMkJFLThDQkE2
MEY5MDJGMF8QJDNGRkEyQTk3LTdEMjgtNDlFQS1BQTM5LTVCQzkwNTFCMjc0NV8QJEUzMzRBNkQy
LTcxNDUtNDdDOC05QjAwLUMyMERFRDA4QjJENV8QJDQxMDlENDJBLUQ3MTctNDZBNy1BOUEyLUZF
NTNBODJCMjVDMF8QJEREMjY2RTFGLTVERjItNENEQi1BMkVCLTI2Q0UzNTY2NDY1N18QJDQ5OTk5
NUZBLUU1MUEtNEFDRS04REZELUJERjhBRkY2Qzk0M18QJDAyNDg5MURFLUI3RjYtNDE4Ny1CRkUw
LUU2RDIzNzcwMkVGMF8QJDlDQ0I4Mjk3LUU5RjUtNDY5OS1BRTFGLTg5MENGQkQ1RTI5Q18QJDgx
Q0E1QUNELUU2ODItNEQ4Qi1BOTQ4LTBGMTQ3RUI2RUQ0Rl8QJDdDNjQzQTM5LUMwQjItNEJBMC04
QkMyLTJFQUE0N0NDNTgwRV8QJDNCQTBDRkM3LUU0NjAtNEI1OS1BODE3LUI5N0Y5RUJCOUI4OV8Q
JDY0RDExREFCLTNCNTctNEYxNC1BRDJGLUU1OUE5MjgyRkE0NF8QJDJCMzBFMzI0LUU0RkYtNEND
MS1CQTQ1LUE5NThDMkQyQjJFQ18QJEE1QUFGRjVELTg4ODctNDJCQi04QUZELTg2N0VGNTU3RUQ4
NV8QJDJGNTJFMzRDLTM5RDQtNEFCMS05MDI1LThGNzE0MUZBQTcyMF8QJDA0NEFENTZDLUExMDct
NDFCMi05MENDLUU2MENDQUNGQkNGNV8QJDE0OUU3Nzk1LURCREEtNEY1RC1CMzlBLTE0NzEyRjg0
MTExOF8QJDg5QjE2NDNCLTA2REQtNERFQy1CMUIwLTc3NDQ5M0IwRjdCN18QJDQ0MTY2QzM5LTg1
NjYtNEVDQS1CRDE2LTQzMTU5NDI5QjUyRl8QJERERTUwQzc3LUI3Q0ItNDQ4OC05RUIxLUQxQjEz
QkYyMUZGRV8QJEU5OTFBQzBDLUYyNzItNDREOC04OEYzLTA1RjQ0RURGRTNBRV8QJEYwMjM2RUM1
LUVFNzItNDA1OC1BNkNFLTFGN0QyRTgyNTNCRl8QJEM2REM0RTU0LTExMzAtNDRGOC1BRjZGLUE1
NTFEOEU4QTE4MV8QJDhEMDRENzBGLTczOEItNDQxRC04RDQzLUFGNDZCMkJGODA2Ml8QJEI4NzZC
NjQ1LTM5NTUtNDIwRS05OURGLTYwMTM5RTQ1MUNGM18QJEVDM0RDOTU3LUQ0QzItNDczMi1BQUNF
LTdEMEMwRjM5MEVDOF8QJDBDNzQ3QzI5LTRCRjgtNDNGNi1BNUNDLTJFMDEyRTU1NTM0MV8QJDM1
NjkzQUVBLUY4QzQtNEE4MC1CNzdELUM5NEIyMEE2ODk1Nl8QJDUzN0E0REFCLTgzQjAtNEI2Ni1C
Q0QxLTA1RTVEQkI0QTI2OCNAeka4UeuFHyNAagrtS4DAPSNAgORR64UeuCNAZoXCj1wo9iNAciUs
goafMyNAbiFOO801qCNAVRZ1sRVvjCNAcrmWu5jH4yNAakfJqORIoyNAgYGLMhuUaSNAaka4UeuF
HyNAdQXo7QWZDiNAessecmo5EiNAcT+cd5prUSNAZ8cl0doLMiNAdQVgQYk3TCNAcgUkUV+1uiNA
bPutzpMu1SNAbM3EMspXqCNAcsTMzMzMzSNAfCczMzMzMyNAfVosX5LF+SNAhAa4uscQyyNAZ+Yc
rAgxJyNAdQVgQYk3TCNAhKVHrhR64SNAadrhAcZiCCNAdBjfgUwMkCNAakfJqORIoyNAfgg2v/dD
CiNAaxohllK9PCNAYQifeI8WQSNAdoZLOtiKuCNAgsTMzMzMzSNAbgi/a3OkzCNAWD2qh7bRcSNA
a7k5NRyJFCNAZcnWxFW+MSNAdAnsv7FbVyNAfgeuFHrhSCNAdQXo7QWZDiNAZ7HLBmrE4iNAgGNk
Ja7mMiNAfg8ndUg55CNAap001qFh5SNAfWIua9yAVyNAaka4UeuFHyNAXPIRv9RPMAhaMjAyMi0w
OC0xN68QGZCRkpOUlZaXmJmam5ydnp+goaKjpKWmp6hfEBBsb2NhdGlvbjpBbGFiYW1hXxATbG9j
YXRpb246Q2FsaWZvcm5pYV5sb2NhdGlvbjpDaGluYV5sb2NhdGlvbjpEdWJhaV8QEGxvY2F0aW9u
OkVuZ2xhbmRfEBBsb2NhdGlvbjpGbG9yaWRhXxAVbG9jYXRpb246R3JhbmQgQ2FueW9uXxASbG9j
YXRpb246R3JlZW5sYW5kXxAPbG9jYXRpb246SGF3YWlpXxASbG9jYXRpb246SG9uZyBLb25nXxAQ
bG9jYXRpb246SWNlbGFuZF5sb2NhdGlvbjpJdGFseV1sb2NhdGlvbjpMaXdhXxAPbG9jYXRpb246
TG9uZG9uXxAUbG9jYXRpb246TG9zIEFuZ2VsZXNfEA9sb2NhdGlvbjpOZXZhZGFfEBFsb2NhdGlv
bjpOZXcgWW9ya18QD2xvY2F0aW9uOk9yZWdvbl8QEmxvY2F0aW9uOlBhdGFnb25pYV8QFmxvY2F0
aW9uOlNhbiBGcmFuY2lzY29fEBFsb2NhdGlvbjpTY290bGFuZFxsb2NhdGlvbjpTZWFebG9jYXRp
b246U3BhY2VebG9jYXRpb246VGV4YXNfEBFsb2NhdGlvbjpZb3NlbWl0ZQlfELl7CiAgImNsb2Nr
Rm9ybWF0IiA6IDAsCiAgImNvcm5lciIgOiAzLAogICJkaXNwbGF5cyIgOiAwLAogICJmb250TmFt
ZSIgOiAiSGVsdmV0aWNhIE5ldWUgTWVkaXVtIiwKICAiZm9udFNpemUiIDogNTAsCiAgImhpZGVB
bVBtIiA6IGZhbHNlLAogICJpc0VuYWJsZWQiIDogZmFsc2UsCiAgInNob3dTZWNvbmRzIiA6IHRy
dWUKfQAIADEAPwBKAFMAXQB0AHsAlgCpALgAzgDdAOwA+gESASABLwFFAV0BaAHtAe8B8QHyAfkC
bQJuAm8CcAJyAnQCgQKJApECmQK+AsYCzgLPAtAC0QLSAtMC1AM3A14DhQOsA9MD+gQhBEgEbwSW
BL0E5AULBTIFWQWABacFzgX1BhwGQwZqBpEGuAbfBwYHLQdUB3sHogfJB/AIFwg+CGUIjAizCNoJ
AQkoCU8JdgmdCcQJ6woSCjkKYAqHCpAKmQqiCqsKtAq9CsYKzwrYCuEK6grzCvwLBQsOCxcLIAsp
CzILOwtEC00LVgtfC2gLcQt6C4MLjAuVC54LpwuwC7kLwgvLC9QL3QvmC+8L+AwBDAoMEwwcDCUM
Lgw3DDgMQwxfDHIMiAyXDKYMuQzMDOQM+Q0LDSANMw1CDVANYg15DYsNnw2xDcYN3w3zDgAODw4e
DjIOMwAAAAAAAAIBAAAAAAAAAKsAAAAAAAAAAAAAAAAAAA7v'

echo -n $BASE64_CONFIG | base64 --decode > "$PROPERTY_LIST"

chown -R "$CURRENT_USER" "$SETTINGS_FOLDER"
chown $CURRENT_USER "$PROPERTY_LIST"

echo "`date` | Adding settings for $CURRENT_USER"
SET_SETTINGS=$(/usr/libexec/PlistBuddy -c "Print" "$PROPERTY_LIST")
echo "`date` | Settings are now $SET_SETTINGS"

# restart settings
killall cfprefsd

echo "`date` | $APP_NAME installation complete"

exit 0
