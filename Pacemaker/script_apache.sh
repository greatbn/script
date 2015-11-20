#Script cai dat Apache Cluster 2 node
export multicast=10.10.10.0
export node1=10.10.10.11
export node2=10.10.10.12
export VIP=10.10.10.30
hostname=`cat /etc/hostname`
#Thuc hien tren ca 2 node
#Cai dat package
apt-get install python-software-properties -y
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
add-apt-repository 'deb http://mirrors.syringanetworks.net/mariadb/repo/5.5/ubuntu precise main'
apt-get update
apt-get install mariadb-galera-server galera -y 
apt-get install drbd8-utils -y
apt-get install pacemaker crmsh corosync cluster-glue resource-agents apache2 mariadb-y
fileconfig=/etc/mysql/conf.d/cluster.cnf
cat << EOF > $fileconfig
print "[mysqld]
query_cache_size=0
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
query_cache_type=0
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_provider=/usr/lib/galera/libgalera_smm.so
#wsrep_provider_options="gcache.size=32G"

# Galera Cluster Configuration
wsrep_cluster_name="test_cluster"
wsrep_cluster_address="gcomm://$node1,$node2"

# Galera Synchronization Congifuration
wsrep_sst_method=rsync
#wsrep_sst_auth=user:pass

# Galera Node Configuration
wsrep_node_address="$node"
wsrep_node_name="$hostname1" "
EOF
#pacemaker va corosync khoi dong cung he thong
update-rc.d pacemaker defaults
update-rc.d corosync defaults
sed -i "s/START=no/START=yes/g" /etc/default/corosync

#Cau hinh corosync
sed -i.bak "s/.*bindnetaddr:.*/bindnetaddr:\ $netaddr/g" /etc/corosync/corosync.conf

#Start service 
service corosync restart
service pacemaker restart
service apache2 restart
#Config DRBD to sync web data
drbdconfig=/etc/drbd.d/drbd0.res
echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
cat << EOF > $drbdconfig
resource drbd0 {
        disk /dev/sdb;
        device /dev/drbd0;
        meta-disk internal;
        on node01 {
                address $node1:7789;
        }
        on node02 {
                address $node2:7789;
        }
}

EOF
drbdadm create-md drbd0
drbdadm up drbd0



#on one node
#drbdadm primary --force drbd0
#config cluster
#Thuc hien tren 1 node
#crm configure property no-quorum-policy="ignore" stonith-enabled="false"
#crm configure primitive IP ocf:heartbeat:IPaddr2 params ip="$VIP" cidr_netmask="24" nic="eth0" op monitor interval="30s"
#crm configure primitve apache ocf:heartbeat:apache params configfile="/etc/apache2/apache2.conf" port="80" op monitor interval="30s" op start interval="0s" timeout="40s" op stop interval="0s" timeout="40s"
#crm configure primitive drbd ocf:linbit:drbd params drbd_resource="drbd0" op monitor interval="3s"
#crm configure primitive fs_web ocf:heartbeat:FileSystem params device="/dev/drbd0" directory="/var/www/html/" fstype="ext4" op start interval="0s" timeout="40s" op stop interval="0s" timeout="40s" op monitor interval="3s"
#crm configure ms drbd_ms drbd meta master-max="1"  master-node-max="1" clone-max="2" clone-node-max="1" notify="true"
#crm configure colocation fs-on-drbd inf: fs_web drbd_ms:Master
#crm configure order fs-after-drbd inf: drbd_ms:promote fs_web:start
#crm configure group web fs_web IP_ apache
#crm configure commit
