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
# Disable SE Linux
#
echo -e "\n####  Disabling SELinux on $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS <<'ENDSSH'
echo "SELINUX=disabled" >/etc/selinux/config
echo "SELINUXTYPE=targeted" >>/etc/selinux/config
setenforce 0
cat /etc/selinux/config
ENDSSH
echo "SUCCESS"


#
# Disable Transparent Huge Pages
#
echo -e "\n#### Disabling Transparent Huge Pages"
pdsh $PDSH_ARGS -w $ALL_HOSTS <<'ENDSSH'
echo "if test -f /sys/kernel/mm/transparent_hugepage/enabled; then echo never > /sys/kernel/mm/transparent_hugepage/enabled; fi" >> /etc/rc.local
echo "if test -f /sys/kernel/mm/transparent_hugepage/defrag; then echo never > /sys/kernel/mm/transparent_hugepage/defrag; fi" >> /etc/rc.local
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo "/sys/kernel/mm/transparent_hugepage/enabled: $(cat /sys/kernel/mm/transparent_hugepage/enabled)"
echo "/sys/kernel/mm/transparent_hugepage/defrag: $(cat /sys/kernel/mm/transparent_hugepage/defrag)"
ENDSSH
echo "SUCCESS"


#
# Disable IPv6
#
echo -e "\n#### Disabling IPv6"
pdsh $PDSH_ARGS -w $ALL_HOSTS <<'ENDSSH'
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
echo "# Added by HDP Bootstrap Script - disable IPv6" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
tail /etc/sysctl.conf
ENDSSH
echo "SUCCESS"


#
# Configure NTPD
#
echo -e "\n#### Configuring NTP"
pdsh $PDSH_ARGS -w $ALL_HOSTS <<'ENDSSH'
yum -y install ntp
ntpdate pool.ntp.org
chkconfig ntpd on
/etc/init.d/ntpd stop
/etc/init.d/ntpd start
/etc/init.d/ntpd status
ENDSSH
echo "SUCCESS"


#
# Disabling IPTables
#
echo -e "\n#### Disabling IPTables"
pdsh $PDSH_ARGS -w $ALL_HOSTS <<'ENDSSH'
chkconfig iptables off
/etc/init.d/iptables stop
/etc/init.d/iptables status
chkconfig ip6tables off
/etc/init.d/ip6tables stop
/etc/init.d/ip6tables status
ENDSSH
echo "SUCCESS"


echo -e "\n##"
echo -e "## Finished bootstrap on $ALL_HOSTS"
echo -e "##"

exit 0
