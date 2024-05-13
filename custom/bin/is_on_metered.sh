#!/bin/zsh

# Get the SSID of the currently connected Wi-Fi network
SSID=$(iwgetid -r)

# Check if the SSID was obtained
if [ -z "$SSID" ]; then
    echo "No Wi-Fi connection detected."
    exit 2
fi

# Get the metered status of the current connection
METERED_STATUS=$(nmcli -f connection.metered connection show "$SSID" | awk -F ': *' '{print $2}')

# Check if the connection is metered and print the result
if [ "$METERED_STATUS" = "no" ]; then
    echo "The current connection ($SSID) is not metered."
    exit 0
else
    echo "The current connection ($SSID) is metered."
    exit 1
fi
