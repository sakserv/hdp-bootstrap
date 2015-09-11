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
export PDSH_SSH_ARGS_APPEND="-q -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no"
PDSH_ARGS="-R ssh"
SSH_ARGS="-q -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no"


#
# Usage
#
usage() {
  echo "USAGE: $SCRIPT_NAME -h /path/to/hostlist"
  echo -e "\t-h - path to a file containing the list of master hostnames, one per line"
}



#
# Parse command line
#
while getopts ":h:" opt; do
  case $opt in
    h)
      HOSTLIST_FILE=$OPTARG;;
   \?)
      usage;exit 1;;
  esac
done

# Validate the path provided exists 
if [ -n "$HOSTLIST_FILE" -a ! -e "$HOSTLIST_FILE" ]; then
  echo "ERROR: Could not find the hostlist file at $HOSTLIST_FILE"
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
ALL_HOSTS=$(cat $HOSTLIST_FILE 2>/dev/null | grep -v -e ^# -e ^$ | tr '\n' ',' | sed 's|,$||g')


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
# Install pdsh (for pdcp)
#
echo -e "\n####  Installing pdsh on $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS "rpm -q pdsh >/dev/null || yum install pdsh -y"
echo "SUCCESS"


#
# Add the Ambari repo
#
echo -e "\n#### Configuring the Ambari YUM Repo"
pdsh $PDSH_ARGS -w $ALL_HOSTS <<'ENDSSH'
wget -N http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.1.1/ambari.repo -O /etc/yum.repos.d/ambari.repo
cat /etc/yum.repos.d/ambari.repo
ENDSSH
echo "SUCCESS"

echo -e "\n##"
echo -e "## Finished bootstrap on $ALL_HOSTS"
echo -e "##"

exit 0
