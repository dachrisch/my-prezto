#!/bin/zsh

# Get the interface name of the connected Wi-Fi (first one found)
IFACE=$(iw dev | awk '$1=="Interface"{print $2; exit}')

# Check if an interface was found
if [ -z "$IFACE" ]; then
    echo "No wireless interface detected."
    exit 2
fi

# Get the SSID of the currently connected Wi-Fi network
SSID=$(iw dev "$IFACE" link | awk -F': ' '/SSID/ {print $2}')

# Check if the SSID was obtained
if [ -z "$SSID" ] || [ "$SSID" = "off/any" ]; then
    echo "No Wi-Fi connection detected."
    exit 2
fi

# Get the metered status of the current connection via NetworkManager
METERED_STATUS=$(nmcli -f connection.metered connection show "$SSID" 2>/dev/null | awk -F ': *' '{print $2}')

# Check if the connection is metered and print the result
if [ "$METERED_STATUS" = "no" ]; then
    echo "The current connection ($SSID) is not metered."
    exit 0
else
    echo "The current connection ($SSID) is metered."
    exit 1
fi
