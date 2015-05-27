hdp-bootstrap
-------------
Collection of scripts to prepare nodes for installing the Hortonworks Data Platform

Presteps
--------
* Requires wget to be installed
* Requires passphareless ssh keys for root

Usage
-----

* Grab the bootstrap and filesystem create script
```
wget -N https://raw.githubusercontent.com/sakserv/hdp-bootstrap/master/bootstrap_hdp.sh -O /tmp/bootstrap_hdp.sh
wget -N https://raw.githubusercontent.com/sakserv/hdp-bootstrap/master/create_hdp_filesystems.sh -O /tmp/create_hdp_filesystems.sh
```

* Create files containing a list of master and worker nodes, one hostname per line
```
vi /tmp/masters
vi /tmp/workers
```

* Run the script
```
bash /tmp/bootstrap_hdp.sh -m /tmp/masters -w /tmp/workers
```
