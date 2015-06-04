#!/bin/bash

#
# Base Variables
#
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(cd `dirname $0` && pwd)


#
# Variables
#
SSH_PRIVATE_KEY_PATH=/root/.ssh/id_hdp
export PDSH_SSH_ARGS_APPEND="-i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no"
PDSH_ARGS="-R ssh"
ETC_HOSTS=/etc/hosts
ETC_HOSTS_TMP=/tmp/hosts.tmp
SSH_ARGS="-i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no"


#
# Usage
#
usage() {
  echo "USAGE: $SCRIPT_NAME -a /path"
  echo -e "\t-a - path to a file containing the list of ALL servers in the cluster, one per line"
}



#
# Parse command line
#
while getopts ":a:" opt; do
  case $opt in
    a)
      ALL_FILE=$OPTARG;;
   \?)
      usage;exit 1;;
  esac
done

# Validate that ALL FILE has been set
if [ -z "$ALL_FILE" ]; then
  usage
  exit 1
fi

# Validate the path provided exists 
if [ -n "$ALL_FILE" -a ! -e "$ALL_FILE" ]; then
  echo "ERROR: Could not find the file containing all servers at $ALL_FILE"
  usage
  exit 1
fi



#
# Sanity Checks
#
echo -e "\n####  Performing sanity checks"
if [ $(id -un) != "root" ]; then
   echo "ERROR: Must run as root"
   exit 1
fi


if [ ! -e "$SSH_PRIVATE_KEY_PATH" ]; then
   echo "ERROR: Unable to find SSH private key at $SSH_PRIVATE_KEY_PATH"
   echo "SSH must be configured prior to running $SCRIPT_NAME"
   exit 1
fi
echo -e "SUCCESS"


#
# Create node lists
#
ALL_HOSTS=$(cat $ALL_FILE $WORKER_FILE 2>/dev/null | grep -v ^# | tr '\n' ',' | sed 's|,$||g')


################
# Main
################

#
# Build up the /etc/hosts file
#
echo -e "\n####  Building /etc/hosts for all nodes"
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" >$ETC_HOSTS_TMP
echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >>$ETC_HOSTS_TMP
for node in $(cat $ALL_FILE); do 
  ip=$(ssh $SSH_ARGS $node "/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'")
  echo -e "$ip\t$node $(echo $node | cut -d. -f1)"
done
echo "SUCCESS"


#
# Distribute the updated /etc/hosts
#
echo -e "\n####  Distributing /etc/hosts to all nodes"
pdcp $PDSH_ARGS -w $ALL_HOSTS $ETC_HOSTS_TMP $ETC_HOSTS
echo "SUCCESS"


echo -e "\n##"
echo -e "## Finished bootstrap on $ALL_HOSTS"
echo -e "##"

exit 0
