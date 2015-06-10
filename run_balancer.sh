#!/bin/bash

#
# Base Variables
#
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(cd `dirname $0` && pwd)


#
# Variables
#
DT=$(date +"%Y-%m-%d")
LOG_DIR=/mnt/resource/hdfs
THRESHOLD=10
STDOUT_LOG=$LOG_DIR/hdfs-balancer.stdout.${DT}.log
STDERR_LOG=$LOG_DIR/hdfs-balancer.stderr.${DT}.log


#
# Usage
#
usage() {
  echo "USAGE: $SCRIPT_NAME"
}


#
# Sanity Checks
#
echo -e "\n####  Performing sanity checks"
if [ $(id -un) != "root" ]; then
   echo "ERROR: Must run as root"
   exit 1
fi


#
# Main
#

# Create the log dir
if [ ! -d $LOG_DIR ]; then
  echo -e "\n#### Creating the logdir $LOG_DIR"
  mkdir -p $LOG_DIR
  chmod 777 $LOG_DIR
  echo "SUCCESS"
fi

# Run the balancer
echo -e "\n#### Running the HDFS Balancer"
su - hdfs -c "hdfs balancer -threshold $THRESHOLD >$STDOUT_LOG 2>$STDERR_LOG"
echo "SUCCESS"

exit 0
