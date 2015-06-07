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
SSH_ARGS="-i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no"


#
# Usage
#
usage() {
  echo "USAGE: $SCRIPT_NAME -u <user id> -a /tmp/allnodes"
  echo -e "\t-u - the user id to create"
  echo -e "\t-a - file containing a list of all nodes, one per line"
}



#
# Parse command line
#
while getopts ":u:a:" opt; do
  case $opt in
    u)
      USER_ID=$OPTARG;;
    a)
      ALL_FILE=$OPTARG;;
   \?)
      usage;exit 1;;
  esac
done

# Validate that the user id is set
if [ -z "$USER_ID" ]; then
  usage
  exit 1
fi

# Validate that the file containing all nodes exists
if [ ! -e "$ALL_FILE" ]; then
  echo "ERROR: Could not find the file containing all nodes at $ALL_FILE"
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
ALL_HOSTS=$(cat $ALL_FILE  2>/dev/null | grep -v ^# | tr '\n' ',' | sed 's|,$||g')


################
# Client node
################

#
# Install base packages
#
if ! rpm -q wget >/dev/null 2>&1; then
  echo -e "\n####  Installing wget on $(hostname -f)"
  yum install wget -y || exit 1
  echo "SUCCESS"
fi

if ! rpm -qa | grep -q epel; then
  echo -e "\n####  Installing the EPEL yum repo on $(hostname -f)"
  rpm -Uvh $EPEL_SOURCE_URL
  echo "SUCCESS"
fi

if ! rpm -q pdsh >/dev/null 2>&1; then
  echo -e "\n####  Installing pdsh on $(hostname -f)"
  yum install pdsh -y || exit 1
  echo "SUCCESS"
fi



################
# All nodes
################
#
# Install wget 
#
echo -e "\n####  Installing wget on $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS "yum install wget -y"
echo "SUCCESS"


#
# Install epel repo
#
echo -e "\n####  Installing the EPEL yum repo on $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS "rpm -Uvh $EPEL_SOURCE_URL"
echo "SUCCESS"


#
# Install pdsh (for pdcp)
#
echo -e "\n####  Installing pdsh on $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS "rpm -q pdsh >/dev/null || yum install pdsh -y"
echo "SUCCESS"

#
# Create the user
#
echo -e "\n##### Creating user $USER_ID on $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS "adduser $USER_ID"
pdsh $PDSH_ARGS -w $ALL_HOSTS "id $USER_ID"


echo -e "\n##"
echo -e "## Finished $SCRIPT_NAME on $ALL_HOSTS"
echo -e "##"

exit 0