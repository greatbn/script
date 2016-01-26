#install package

export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mariadb-server-5.5 mysql-server/root_password password saphi'
debconf-set-selections <<< 'mariadb-server-5.5 mysql-server/root_password_again password saphi'

apt-get update && apt-get upgrade -y && apt-get dist-upgrade -y

apt-get install -y apache2 mariadb-server libapache2-mod-php5  --force-yes


apt-get install -y php5-gd php5-json php5-mysql php5-curl --force-yes

apt-get install -y php5-intl php5-mcrypt php5-imagick --force-yes


wget https://download.owncloud.org/community/owncloud-8.2.2.tar.bz2

wget https://download.owncloud.org/community/owncloud-8.2.2.tar.bz2.asc

wget https://owncloud.org/owncloud.asc

gpg --import owncloud.asc

gpg --verify  owncloud-8.2.2.tar.bz2.asc owncloud-8.2.2.tar.bz2

tar -xvf owncloud-8.2.2.tar.bz2

cp -r owncloud /var/www/html

cat << EOF > /etc/apache2/sites-available/owncloud.conf
<Directory /var/www/html/owncloud/>
  Options +FollowSymlinks
  AllowOverride All

 <IfModule mod_dav.c>
  Dav off
 </IfModule>

 SetEnv HOME /var/www/html/owncloud
 SetEnv HTTP_HOME /var/www/html/owncloud

</Directory>

EOF

ln -s /etc/apache2/sites-available/owncloud.conf /etc/apache2/sites-enabled/owncloud.conf

a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime

service apache2 restart

mysql -uroot -psaphi -e "create database owncloud"

mysql -uroot -psaphi -e "grant all privileges on owncloud.* to 'owncloud'@'%' identified by 'saphi'"
chown -R www-data:www-data /var/www/html/owncloud/