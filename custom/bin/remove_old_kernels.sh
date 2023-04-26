#!/bin/zsh
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

echo "${GREEN}current kernel version: ${YELLOW}$(uname -r )${NOCOLOR}"
extra_modules=$(dpkg --list | grep -E "linux-modules-extra-[0-9]+.*" | grep ii | awk '{print $2}' | sort -V | sed -n '/'$(uname -r | cut -f1,2 -d"-")'/q;p'|xargs)
echo "${RED}removing old extra modules:${YELLOW}${extra_modules}${NOCOLOR}"
kernel_modules=$(dpkg --list | grep -E "linux-modules-[0-9]+.*" | grep ii | awk '{print $2}' | sort -V | sed -n '/'$(uname -r | cut -f1,2 -d"-")'/q;p'|xargs)
echo "${RED}removing old modules:${YELLOW} ${kernel_modules}${NOCOLOR}"
sudo apt remove $extra_modules $kernel_modules
echo "${RED}autoremoving old kernels${NOCOLOR}"
sudo apt autoremove
