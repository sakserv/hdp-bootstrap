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
SSH_ARGS="-q -i $SSH_PRIVATE_KEY_PATH -o StrictHostKeyChecking=no"
DT=$(date +"%Y-%m-%d")
LOG_DIR=/data/backups/hive
DB_LIST="hive"
SVR_COPY_LIST="hdpclustermstr1.cloudapp.net hdpclustermstr2.cloudapp.net"


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

# Run the backup
for db in $DB_LIST; do 
  echo -e "\n#### Running the Hive database backup on $DT for DB: $db"
  OUTFILE=$LOG_DIR/hive-db-${db}-backup.${DT}
  mysqldump $db >$OUTFILE
  echo "SUCCESS"
done

for server in $SVR_COPY_LIST; do
  echo -e "\n#### Copying backup to $server"
  ssh $SSH_ARGS $server "mkdir -p $LOG_DIR"
  scp $SSH_ARGS $LOG_DIR/hive-db-*-backup.${DT} $server:$LOG_DIR/
  echo "SUCCESS"
done

exit 0
