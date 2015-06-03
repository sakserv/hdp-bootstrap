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
EPEL_SOURCE_URL="http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
AMBARI_REPO_URL="http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.0.0/ambari.repo"


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
      MASTER_FILE=$OPTARG;;
    w)
      WORKER_FILE=$OPTARG;;
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


#
# Create node lists
#
ALL_HOSTS=$(cat $MASTER_FILE $WORKER_FILE 2>/dev/null | grep -v ^# | tr '\n' ',' | sed 's|,$||g')
ALL_MASTERS=$(cat $MASTER_FILE 2>/dev/null | grep -v ^#  | tr '\n' ',' | sed 's|,$||g')
ALL_WORKERS=$(cat $WORKER_FILE 2>/dev/null | grep -v ^#  | tr '\n' ',' | sed 's|,$||g')


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
pdsh $PDSH_ARGS -w $ALL_HOSTS "yum install pdsh -y"
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


#
# Add the Ambari repo
#
echo -e "\n#### Configuring the Ambari YUM Repo"
pdsh $PDSH_ARGS -w $ALL_HOSTS <<'ENDSSH'
wget -N http://public-repo-1.hortonworks.com/ambari/centos6/2.x/updates/2.0.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
cat /etc/yum.repos.d/ambari.repo
ENDSSH
echo "SUCCESS"


#
# Set the hostname
#
echo -e "\n#### Setting the hostname to match the public hostname"
for node in $(echo $ALL_HOSTS | sed 's|,||g'); do
   echo "Processing $node"
   ssh $SSH_ARGS $node "hostname $node"
   ssh $SSH_ARGS $node "sed -i 's|^HOSTNAME=*|HOSTNAME=$node|g' /etc/syconfig/network"
   echo "Hostname set to: " 
   ssh $SSH_ARGS $node "hostname"
done


#
# Distribute the create filesystem script
#
echo -e "\n####  Distributing the create filesystem script"
create_fs_script=$SCRIPT_DIR/create_hdp_filesystems.sh
dest_dir=/tmp
pdcp $PDSH_ARGS -w $ALL_HOSTS $create_fs_script $dest_dir
echo "SUCCESS"




################
# Master nodes
################
#
# Run the create filesystem script
#
echo -e "\n####  Running the create filesystem script on $ALL_MASTERS"
pdsh $PDSH_ARGS -w $ALL_MASTERS "bash /tmp/create_hdp_filesystems.sh -t master"
echo "SUCCESS"




################
# Worker nodes
################
#
# Run the create filesystem script
#
echo -e "\n####  Running the create filesystem script on $ALL_WORKERS"
pdsh $PDSH_ARGS -w $ALL_WORKERS "bash /tmp/create_hdp_filesystems.sh -t worker"
echo "SUCCESS"


echo -e "\n##"
echo -e "## Finished bootstrap on $ALL_HOSTS"
echo -e "##"

exit 0
