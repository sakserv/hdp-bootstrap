set hive.enforce.bucketing=true;
set hive.exec.dynamic.partition.mode=nonstrict;
INSERT INTO TABLE uidata_orc PARTITION(dt) 
SELECT *,to_date(from_unixtime(unix_timestamp(timestamp,'MM/dd/yyyy h:mm:ss aa'))) AS dt FROM uidata_staging
WHERE deviceid != 'DeviceID';
