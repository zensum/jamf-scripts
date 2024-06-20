#!/usr/bin/env bash

# Initialize an empty array
interfaces=()

# Read the list of interfaces line by line and append to the interfaces array
while IFS= read -r line; do
    interfaces+=("$line")
done <<< "$(networksetup -listallnetworkservices | tail -n +2)"

declare -a ordered_interfaces=()

# Find the ethernet interface and add them first
for i in "${interfaces[@]}"; do
    # Skip interfaces containing "iPhone"
    if [[ $i == *"iPhone"* ]]; then
        continue
    fi

    # Add interfaces that contain the word "Ethernet" first
    if [[ $i == *"Ethernet"* ]]; then
        ordered_interfaces+=("$i")
    # Add interfaces containing the word USB
    elif [[ $i == *"USB"* ]]; then
        ordered_interfaces+=("$i")
    # Add interfaces containing or starting with Thunderbolt
    elif [[ $i == *"Thunderbolt"* ]]; then
        ordered_interfaces+=("$i")
    fi
done

# Find the interfaces not added before and add them to the ordered_interfaces array
for i in "${interfaces[@]}"; do
    if [[ ! " ${ordered_interfaces[@]} " =~ " $i " ]]; then
        ordered_interfaces+=("$i")
    fi
done

# If you want to use the ordered interfaces in networksetup, you can join them into a single string
interface_string=$(printf '"%s" ' "${ordered_interfaces[@]}")

echo "The interface string: $interface_string"

eval networksetup -ordernetworkservices $interface_string
