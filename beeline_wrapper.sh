#!/bin/bash

if [ -z "$1" ]; then
  echo "ERROR: must supply database name"
  exit 1
fi
database=$1
shift $@

beeline -u jdbc:hive2://localhost:10000/$database -d org.apache.hive.jdbc.HiveDriver -n $(id -un) $@
