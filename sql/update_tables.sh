#!/bin/bash

#
# Base Variables
#
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(cd `dirname $0` && pwd)


#
# Variables
#
STAGING_DIR=/data/ACS/HCH/uidata/uidata_staging
RAW_DIR=/data/ACS/HCH/uidata/uidata_raw
ORC_DIR=/data/ACS/HCH/uidata/uidata_orc
USER_ID=hdpadmin

#
# Usage
#
usage() {
  echo "USAGE: $SCRIPT_NAME"
}


#
# Sanity Checks
#
echo -e "\n####  Validate running as root"
if [ $(id -un) != "root" ]; then
   echo "ERROR: Must run as root"
   exit 1
fi
echo "SUCCESS"

#
# Create the necessary directories
#

echo -e "\n####  Checking for staging dir $STAGING_DIR"
if ! su - hdfs -c "hdfs dfs -test -d $STAGING_DIR"; then
  echo "Creating $STAGING_DIR"
  su - hdfs -c "hdfs dfs -mkdir -p $STAGING_DIR"
  su - hdfs -c "hdfs dfs -chown $USER_ID:hadoop $STAGING_DIR"
fi
echo "SUCCESS"

echo -e "\n####  Checking for raw table dir $RAW_DIR"
if ! su - hdfs -c "hdfs dfs -test -d $RAW_DIR"; then
  echo "Creating $RAW_DIR"
  su - hdfs -c "hdfs dfs -mkdir -p $RAW_DIR"
  su - hdfs -c "hdfs dfs -chown $USER_ID:hadoop $RAW_DIR"
fi
echo "SUCCESS"

echo -e "\n####  Checking for orc table dir $ORC_DIR"
if ! su - hdfs -c "hdfs dfs -test -d $ORC_DIR"; then
  echo "Creating $ORC_DIR"
  su - hdfs -c "hdfs dfs -mkdir -p $ORC_DIR"
  su - hdfs -c "hdfs dfs -chown $USER_ID:hadoop $ORC_DIR"
fi
echo "SUCCESS"

#
# Check that staging isn't empty
#
echo -e "\n####  Checking that staging isn't empty"
obj_count=$(su - hdfs -c "hdfs dfs -count $STAGING_DIR" | awk '{print $2}')
if [ "$obj_count" = "0" ]; then
  echo "ERROR: $STAGING_DIR is empty"
  exit 1
fi
echo "SUCCESS"


#
# Main
#

#
# Create the tables
#

# Create the staging table
echo -e "\n####  Creating the staging table, if necessary"
su - $USER_ID -c "hive -S -f $SCRIPT_DIR/sql/staging_table.sql"
echo "SUCCESS"

# Create the raw table
echo -e "\n####  Creating the raw table, if necessary"
su - $USER_ID -c "hive -S -f $SCRIPT_DIR/sql/raw_table.sql"
echo "SUCCESS"

# Create the orc table
echo -e "\n####  Creating the orc table, if necessary"
su - $USER_ID -c "hive -S -f $SCRIPT_DIR/sql/orc_table.sql"
echo "SUCCESS"


#
# Get a list of the files in STAGING_DIR
# Copy the file the same location the RAW_DIR
# 
echo -e "\n####  Adding the staged files to the raw table"
for file in $(su - hdfs -c "hdfs dfs -ls -R $STAGING_DIR" | grep -v -e ^d -e Found | awk '{print $NF}'); do

  echo "Processing $file" 

  RAW_FILE=$(echo $file | sed 's|_staging|_raw|g')
  RAW_DIR=$(dirname $RAW_FILE)
  RAW_FILENAME=$(basename $RAW_FILE)

  # Create the destination dir
  su - $USER_ID -c "hdfs dfs -mkdir -p $RAW_DIR"
  su - $USER_ID -c "hdfs dfs -cp $file $RAW_FILE" || exit 1
  su - $USER_ID -c "hdfs dfs -ls $RAW_DIR | grep $RAW_FILENAME"

done
echo "SUCCESS"

#
# Load the staging data into the ORC table
#

# Load the table
echo -e "\n####  Adding the staged files to the orc table"
su - $USER_ID -c "hive -S -f $SCRIPT_DIR/sql/insert_into_orc.sql" || exit 1
echo "SUCCESS"


#
# Delete the staged data
#
echo -e "\n####  Deleting the staged data"
su - hdfs -c "hdfs dfs -rm -r $STAGING_DIR/*"
echo "SUCCESS"


exit 0
