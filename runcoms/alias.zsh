alias ll='ls -al'
# shellcheck disable=SC2142
alias latest_installed_kernel_version='dpkg --list |grep -E "linux-modules-[0-9]+.*"|grep ii| awk "{print \$2}" | sort -V | tail -1 | cut -f3-5 -d"-"'
alias snap-refresh='sudo snap refresh snap-store && sudo snap refresh'
# linux-modules-extra needed for storagebox utf-8 support
alias apt-upgrade='sudo apt update && sudo apt upgrade && sudo apt autoremove && sudo apt install linux-modules-extra-$(latest_installed_kernel_version)'
alias update-all='apt-upgrade && snap-refresh && flatpak update'
# helper for system services
alias sys='systemctl --user'
# helper for docker updates
alias dc='docker-compose'
alias dc-refresh='git pull && dc down && dc up'

# bluetooth handling
source $HOME/.zprezto/custom/turn_bluetooth_device.sh
alias stanny_up='turn_bt_device $BT_STANNY on'
alias stanny_down='turn_bt_device $BT_STANNY off'
