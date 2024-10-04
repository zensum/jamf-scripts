#!/bin/sh

## Script Name:				Active Network Interface
## Script Type:				Extension Attribute
## Script Purpose:			Returns the active network interface(s), such as "Wi-Fi", "Ethernet" etc. of the Mac at the time of inventory collection

## Get the list of active devices from scutil
active_devices=$(/usr/sbin/scutil --nwi | awk -F': ' '/Network interfaces:/{print $NF}')
port_names=()

## Loop over the list of active devices
for device in $(printf '%s\n' "$active_devices"); do
	if [[ ! "$device" =~ "utun" ]]; then
		## Get the name of the port associated with the device id, such as "Wi-Fi"
		port_name=$(/usr/sbin/networksetup -listallhardwareports | grep -B1 "$device" | awk -F': ' '/Hardware Port:/{print $NF}')
		## Add that name into an array
		port_names+=("$port_name")
	fi
done

## Print back the array as the returned value
echo "<result>$(printf '%s\n' "${port_names[@]}")</result>"