#!/bin/bash

#
# Base Variables
#
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(cd `dirname $0` && pwd)


#
# Variables
#
SSH_PRIVATE_KEY_PATH=/root/.ssh/id_rsa
SSH_PUBLIC_KEY_PATH=/root/.ssh/id_rsa.pub
EPEL_SOURCE_URL="http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
export PDSH_SSH_ARGS_APPEND="-i $SSH_PRIVATE_KEY_PATH"
PDSH_ARGS="-R ssh"


#
# Usage
#
usage() {
  echo "USAGE: $SCRIPT_NAME -m /path -w /path"
  echo -e "\t-m - path to a file containing the list of master hostnames, one per line"
  echo -e "\t-w - path to a file containing the list of worker hostnames, one per line"
  echo "Either or both of the above are accepted, but at least one is required"
}



#
# Parse command line
#
while getopts ":m:w:" opt; do
  case $opt in
    m)
      MASTER_FILE=$OPTARG;break;;
    w)
      WORKER_FILE=$OPTARG;break;;
   \?)
      usage;exit 1;;
  esac
done

# Validate that at least one is set
if [ -z "$MASTER_FILE" -a -z "$WORKER_FILE" ]; then
  usage
  exit 1
fi

# Validate the path provided exists 
if [ -n "$MASTER_FILE" -a ! -e "$MASTER_FILE" ]; then
  echo "ERROR: Could not find the master file at $MASTER_FILE"
  usage
  exit 1
fi

if [ -n "$WORKER_FILE" -a ! -e "$WORKER_FILE" ]; then
  echo "ERROR: Could not find the worker file at $WORKER_FILE"
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




################
# All node types
################
ALL_HOSTS=$(cat $MASTER_FILE $SLAVE_FILE 2>/dev/null)
ALL_HOSTS_PDSH=$(echo $ALL_HOSTS | tr '\n' ',' | sed 's|,$||g')

#
# Install base packages
#
echo -e "\n####  Installing wget on $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS_PDSH "yum install wget -y" || exit 1
echo "SUCCESS"

echo -e "\n####  Installing the EPEL yum repo on $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS_PDSH "rpm -Uvh $EPEL_SOURCE_URL"
echo "SUCCESS"

echo -e "\n####  Installing pdsh $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS_PDSH "yum install pdsh -y" || exit 1
echo "SUCCESS"


#
# Disable SE Linux
#
echo -e "\n####  Disabling SELinux on $ALL_HOSTS"
pdsh $PDSH_ARGS -w $ALL_HOSTS_PDSH <<'ENDSSH'
sed -i "s|^\([^#]\)|#\1|g" /etc/selinux/config
ENDSSH


exit 0


# Disable Transparent Huge Pages (thanks Paul!) 
echo -e "\n#### Disabling Transparent Huge Pages"
scp -o StrictHostKeyChecking=no -i secloud.pem rc.local.append root@$1:
ssh -o StrictHostKeyChecking=no -i secloud.pem root@$1 <<'ENDSSH'
cat /root/rc.local.append >> /etc/rc.local
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo never > /sys/kernel/mm/transparent_hugepage/defrag
ENDSSH

# Disable IPv6
echo -e "\n#### Disabling IPv6"
ssh -o StrictHostKeyChecking=no -i secloud.pem root@$1 <<'ENDSSH'
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
echo "# Added by HDP Bootstrap Script - disable IPv6" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
ENDSSH

echo -e "\n#### Configuring YUM Repos"
ssh -o StrictHostKeyChecking=no -i secloud.pem root@$1 <<'ENDSSH'
yum -y install wget
cd /etc/yum.repos.d
wget http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.0.0/ambari.repo
ENDSSH

echo -e "\n#### Configuring NTP"
ssh -o StrictHostKeyChecking=no -i secloud.pem root@$1 <<'ENDSSH'
yum -y install ntp
ntpdate pool.ntp.org
chkconfig ntpd on
/etc/init.d/ntpd stop
/etc/init.d/ntpd start
ENDSSH

echo -e "\n#### Disabling IPTables"
ssh -o StrictHostKeyChecking=no -i secloud.pem root@$1 <<'ENDSSH'
chkconfig iptables off
/etc/init.d/iptables stop
chkconfig ip6tables off
/etc/init.d/ip6tables stop
ENDSSH

echo -e "\n##"
echo -e "## Finished bootstrap on $1"
echo -e "##"

exit 0
