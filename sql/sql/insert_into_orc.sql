set hive.enforce.bucketing=true;
set hive.exec.dynamic.partition.mode=nonstrict;
set hive.tez.container.size=16384;
set hive.tez.java.opts=-server -Xmx14336m -Djava.net.preferIPv4Stack=true -XX:NewRatio=8 -XX:+UseNUMA -XX:+UseParallelGC -XX:+PrintGCDetails -verbose:gc -XX:+PrintGCTimeStamps;
use honeywell_acs_hch_poc;
INSERT INTO TABLE uidata_orc PARTITION(dt)
SELECT *,to_date(from_unixtime(unix_timestamp(timestamp,'MM/dd/yyyy h:mm:ss aa'))) AS dt FROM uidata_staging
WHERE deviceid != 'DeviceID';
