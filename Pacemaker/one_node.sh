export VIP=10.10.10.30
#on one node
drbdadm primary --force drbd0
#config cluster
#Thuc hien tren 1 node
crm configure property no-quorum-policy="ignore" stonith-enabled="false"
crm configure primitive IP ocf:heartbeat:IPaddr2 params ip="$VIP" cidr_netmask="24" nic="eth0" op monitor interval="30s"
crm configure primitve apache ocf:heartbeat:apache params configfile="/etc/apache2/apache2.conf" port="80" op monitor interval="30s" op start interval="0s" timeout="40s" op stop interval="0s" timeout="40s"
crm configure primitive drbd ocf:linbit:drbd params drbd_resource="drbd0" op monitor interval="3s"
crm configure primitive fs_web ocf:heartbeat:FileSystem params device="/dev/drbd0" directory="/var/www/html/" fstype="ext4" op start interval="0s" timeout="40s" op stop interval="0s" timeout="40s" op monitor interval="3s"
crm configure ms drbd_ms drbd meta master-max="1"  master-node-max="1" clone-max="2" clone-node-max="1" notify="true"
crm configure colocation fs-on-drbd inf: fs_web drbd_ms:Master
crm configure order fs-after-drbd inf: drbd_ms:promote fs_web:start
crm configure group web fs_web IP_ apache
crm configure commit
