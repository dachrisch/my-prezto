#!/bin/zsh

if [ -z "$1" ];then
  dry_run="--dry-run"
  echo "running $0 in dry mode"
else
  dry_run=""
  echo "running $0 in action mode"
fi

# https://askubuntu.com/questions/2793/how-do-i-remove-old-kernel-versions-to-clean-up-the-boot-menu
dpkg --list | grep linux-image | awk '{ print $2 }' | sort -V | sed -n '/'`uname -r`'/q;p' | xargs sudo apt -y purge $dry_run

if [ -z "$1" ];then
  if read -q "choice?Really perform purge? (y/N): "; then
    echo
    $SHELL $0 -y
  fi
fi
