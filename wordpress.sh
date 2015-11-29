export ROOT_PASSWORD='saphi'
export DB_NAME='wordpress'
export DB_USER='saphi'
export DB_PASS='saphi'

echo "Script cai dat wordpress "
sleep 3
echo "nameserver 8.8.8.8" > /etc/resolve.conf
echo mysql-server mysql-server/root_password password $ROOT_PASSWORD | debconf-set-selections
echo mysql-server mysql-server/root_password_again password $ROOT_PASSWORD | debconf-set-selections
echo " Update Repo"
sleep 3
apt-get update
echo "Cai dat cac thanh phan"
sleep 3
apt-get install wget apache2 mysql-server php5-mysql php5 libapache2-mod-php5 php5-mcrypt  mysql-server -y
echo "Tao database"
mysql -uroot -p$ROOT_PASSWORD -e "create database $DB_NAME"
mysql -uroot -p$ROOT_PASSWORD -e "grant all privileges on $DB_NAME.* to $DB_USER@localhost identified by $DB_PASS"
echo "Cai dat wordpress"
sleep 3
wget https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz -C /var/www/html/
rm latest.tar.gz
mv /var/www/html/wordpress/* /var/www/html/
rm -r /var/www/html/wordpress
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
chown -R www-data:www-data /var/www/html/*
mkdir /var/www/html/wp-content/uploads
chown -R :www-data /var/www/html/wp-content/uploads
chmod 775 -R /var/www/html/*
sed -i 's/index.html/index.php index.html/g' /etc/apache2/mods-enabled/dir.conf
sed -i 's/database_name_here/'$DB_NAME'/g' /var/www/html/wp-config.php
sed -i 's/username_here/'$DB_USER'/g' /var/www/html/wp-config.php
sed -i 's/password_here/'$DB_PASS'/g' /var/www/html/wp-config.php
rm /var/www/html/index.html
echo "Restart dich vu"
sleep 3
service apache2 start
service mysql restart 
