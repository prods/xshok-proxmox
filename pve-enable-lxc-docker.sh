#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
#
# Script updates can be found at: https://github.com/extremeshok/xshok-proxmox
#
# Configures an LXC container to correctly support/run docker
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
# Note:
# There can be security implications as the LXC container is running in a higher privileged mode.
#
# Usage:
# curl https://raw.githubusercontent.com/extremeshok/xshok-proxmox/master/pve-enable-lxc-docker.sh --output /usr/sbin/pve-enable-lxc-docker && chmod +x /usr/sbin/pve-enable-lxc-docker
# pve-enable-lxc-docker container_id
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#
##############################################################

container_id="$1"

container_config="/etc/pve/lxc/$container_id.conf"

function addlineifnotfound { #$file #$line
  if [ "$1" == "" ] || [ "$2" == "" ] ; then
    echo "Error missing parameters"
    exit 1
  else
    filename="$1"
    linecontent="$2"
  fi
  if [ ! -f "$filename" ] ; then
    echo "Error $filename not found"
    exit 1
  fi
  if ! grep -Fxq "$linecontent" "$filename" ; then
    #echo "\"$linecontent\" ---> $filename"
    echo "$linecontent" >> "$filename"
  fi
}

#add cgroups support
if [ "$(which cgroupfs-mount)" == "" ] ; then
  apt-get install -y cgroupfs-mount
fi

if [ -f "$container_config" ]; then

  addlineifnotfound "$container_config" "lxc.aa_profile: unconfined"
  addlineifnotfound "$container_config" "lxc.apparmor.profile: unconfined"
  addlineifnotfound "$container_config" "lxc.cgroup.devices.allow: a"
  addlineifnotfound "$container_config" "lxc.cap.drop:"
  addlineifnotfound "$container_config" "linux.kernel_modules: aufs ip_tables"
  addlineifnotfound "$container_config" "lxc.mount.auto: proc:rw sys:rw"

  #pve is missing the lxc binary
  #lxc config set "$container_id" security.nesting true
  #lxc config set "$container_id" security.privileged true
  #lxc restart "$container_id"

  #pve lxc container restart
  lxc-stop --name "$container_id"
  lxc-start --name "$container_id"

  echo "Docker support added to $container_id"

else
  echo "Error: Config $container_config could not be found"
  exit 1
fi
