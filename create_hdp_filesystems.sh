#!/bin/bash

#
# Base Variables
#
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(cd `dirname $0` && pwd)

#
# Variables
#
MKFS_ARGS="-F -t ext4 -m 0"
MOUNT_ARGS="defaults,data=writeback,noatime,nobarrier"

#
# Usage
#
usage() {
  echo "USAGE: $SCRIPT_NAME -t <master/worker>"
  echo -e "\t-t - the type of server, master or worker"
}

#
# Parse command line
#
while getopts ":t:" opt; do
  case $opt in
    t)
      SERVER_TYPE=$OPTARG;;
   \?)
      usage;exit 1;;
  esac
done

if [ -z "$SERVER_TYPE" ]; then
  usage
  exit 1
fi

# make lower case
SERVER_TYPE=$(echo $SERVER_TYPE | tr [A-Z] [a-z])

#
# Get the list of block devices
#
drives=$(lsblk | grep ^sd | grep -v sd[ab] | awk '{print $1}')

#
# Worker
#
if [ "$SERVER_TYPE" = "worker" ]; then

  drive_num=1
  for drive in $drives; do

    # Get the UUID for the device
    dev_uuid=$(blkid -s UUID -o value /dev/$drive)

    # Make the filesystem
    mkfs $MKFS_ARGS /dev/$drive || exit 1

    # Zero pad the mount point
    if [ "$(echo $drive_num | wc -c)" = "2" ]; then
      mount_point=/data/0$drive_num
    else
      mount_point=/data/$drive_num
    fi

    # Create the mount directory
    mkdir -p $mount_point || exit 1

    # Create the /etc/fstab entry
    echo -e "UUID=${dev_uuid}\t${mount_point}\text4\t${MOUNT_ARGS}\t0 0" >> /etc/fstab

    # Mount the filesystem
    mount $mount_point || exit 1

    # Display the mount
    df -h $mount_point

    drive_num=$(( drive_num + 1 ))

  done


#
# Master
#
elif [ "$SERVER_TYPE" = "master" ]; then

  # Variables
  drive=$drives
  mount_point=/data

  # Get the UUID for the device
  dev_uuid=$(blkid -s UUID -o value /dev/$drive)

  # Make the filesystem
  mkfs $MKFS_ARGS /dev/$drive || exit 1

  # Create the mount directory
  mkdir -p $mount_point || exit 1

  # Create the /etc/fstab entry
  echo -e "UUID=${dev_uuid}\t${mount_point}\text4\t${MOUNT_ARGS}\t0 0" >> /etc/fstab

  # Mount the filesystem
  mount $mount_point || exit 1

  # Display the mount
  df -h $mount_point

fi

exit 0
