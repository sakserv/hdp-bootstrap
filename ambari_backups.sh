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
LOG_DIR=/data/backups/ambari
DB_LIST="ambari ambarirca"


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
  echo -e "\n#### Running the Ambari database backup for DB: $db"
  OUTFILE=$LOG_DIR/ambari-db-${db}-backup.${DT}
  su - postgres -c "pg_dump $db >$OUTFILE"
  echo "SUCCESS"
done

exit 0
