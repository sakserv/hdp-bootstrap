CREATE EXTERNAL TABLE IF NOT EXISTS uidata_orc (
deviceid            	string,
timestamp           	string,
uidataid            	string,
userid              	string,
outdoortemp         	decimal(10,0),
disptemperature     	decimal(10,0),
heatsetpoint        	decimal(10,0),
coolsetpoint        	decimal(10,0),
displayedunits      	decimal(10,0),
statusheat          	string,
statuscool          	string
)
PARTITIONED BY (dt string)
CLUSTERED BY(deviceid) INTO 16 BUCKETS
STORED AS ORC
LOCATION '/data/ACS/HCH/uidata/uidata_orc';
