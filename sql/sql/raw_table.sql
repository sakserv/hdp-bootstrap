CREATE EXTERNAL TABLE IF NOT EXISTS uidata_raw (
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
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
STORED AS TEXTFILE
LOCATION '/data/ACS/HCH/uidata/uidata_raw';
