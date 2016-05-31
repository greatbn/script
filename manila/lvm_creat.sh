apt-get install xfsprogs -y
pvcreate /dev/sdb
vgcreate myVG /dev/sdb
lvcreate -L 8G -T myVG/thinpool
for ((i = 1;i<= 5; i++ ))
do
mkdir -p /manila/manila-"$i"
for (( j = 1; j<= 5; j++))
do
lvcreate -V "${i}"Gb -T myVG/thinpool -n vol-"$i"-"$j"
mkfs.xfs /dev/myVG/vol-"$i"-"$j"
mkdir -p /manila/manila-"$i"/manila-"$j"
mount /dev/myVG/vol-"$i"-"$j" /manila/manila-"$i"/manila-"$j"
done
done
