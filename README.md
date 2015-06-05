hdp-bootstrap
-------------
Collection of scripts to prepare nodes for installing the Hortonworks Data Platform

Presteps
--------
* Requires wget to be installed
* Requires passphareless ssh keys for root

Usage
-----

* Install the ssh public key on all nodes in the cluster.
```
ssh <hostname>
wget https://raw.githubusercontent.com/sakserv/hdp-bootstrap/master/add_ssh_pub_key.sh && bash add_ssh_pub_key.sh
```

* On the Ambari node, grab the bootstrap and filesystem create script
```
wget https://raw.githubusercontent.com/sakserv/hdp-bootstrap/master/bootstrap_hdp.sh -O /tmp/bootstrap_hdp.sh
wget https://raw.githubusercontent.com/sakserv/hdp-bootstrap/master/create_hdp_filesystems.sh -O /tmp/create_hdp_filesystems.sh
wget https://raw.githubusercontent.com/sakserv/hdp-bootstrap/master/generate_etc_hosts.sh -O /tmp/generate_etc_hosts.sh
```

* On the Ambari node, create files containing a list of master and worker nodes you want to bootstrap, one hostname per line
```
vi /tmp/masters
vi /tmp/workers
```

* On the Ambari node, Run the script
```
bash /tmp/bootstrap_hdp.sh -m /tmp/masters -w /tmp/workers
```

* On the Ambari node, Create a file containing a list of all nodes in the cluster, one hostname per line (needed for /etc/hosts generation)
```
vi /tmp/allnodes
```

* On the Ambari node, Generate and deploy /etc/hosts
```
bash /tmp/generate_etc_hosts.sh -a /tmp/allnodes
```

