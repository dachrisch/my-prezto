#!/bin/sh
# https://confluence.tdservice.cloud/display/TDDashboard/Ubuntu
WIFI_INTERFACE=$(find /sys/class/net -follow -maxdepth 2 -name wireless 2>/dev/null | cut -d / -f 5)

echo "connecting to $WIFI_INTERFACE..."
sudo nmcli connection add type wifi con-name "TechDivision" ifname $WIFI_INTERFACE ssid "TechDivision-5G" -- wifi-sec.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.phase2-auth pap 802-1x.identity "$USERNAME" 802-1x.anonymous-identity "" 802-1x.ca-cert "/etc/ssl/certs/ISRG_Root_X1.pem" 802-1x.password-flags 1
