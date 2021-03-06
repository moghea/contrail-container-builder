#!/bin/bash

# these next folders must be mounted to compile vrouter.ko in ubuntu: /usr/src /lib/modules

source /common.sh
# copy ifup-vhost and vif util
if [[ ! -f /etc/sysconfig/network-scripts/ifup-vhost && -d /etc/sysconfig/network-scripts ]]; then
  /bin/cp -f /ifup-vhost /etc/sysconfig/network-scripts
  chmod +x /etc/sysconfig/network-scripts/ifup-vhost
fi
if [[ ! -f /host/bin/vif ]]; then
  /bin/cp -f /bin/vif /host/bin/vif
fi

# Load kernel module
if lsmod | grep -q vrouter; then
  echo "INFO: vrouter.ko already loaded in the system"
  # TODO: handle upgrade
else
  kver=`uname -r | awk -F "-" '{print $1}'`
  echo "INFO: Load kernel module for kver=$kver"
  modfile=`ls -1rt /opt/contrail/vrouter-kernel-modules/$kver-*/vrouter.ko | tail -1`
  for k_dir in `ls -d /lib/modules/*`
  do
    mkdir -p ${k_dir}/kernel/net/vrouter
    cp ${modfile} ${k_dir}/kernel/net/vrouter
  done
  depmod -a
  echo "INFO: Modprobing vrouter $modfile"
  free -h && sync && echo 2 >/proc/sys/vm/drop_caches && free -h
  if ! insmod $modfile ; then
    echo "ERROR: Failed to insert vrouter kernel module"
    exit 1
  fi
fi

exec $@
