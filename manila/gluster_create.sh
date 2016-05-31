for (( i= 1 ; i <= 5; i++))
do
for(( j= 1; j<=5 ;j++))
do
gluster volume create manila-"$i"-"$j" replica 2 glusterfs-1:/manila/manila-"$i"/manila-"$j"/br glusterfs-2:/manila/manila-"$i"/manila-"$j"/br
gluster volume start manila-"$i"-"$j"
done
done
