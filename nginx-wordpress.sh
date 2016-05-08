
export DOMAIN=xxx.com
export DB_ROOT_PASSWD='saphi'
export DB_USER='saphi'
export DB_NAME='wordpress'
export DB_PASS='saphi'

echo "add repo"
sleep 3

cat << EOF > /etc/apt/sources.list.d/nginx.list
deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx
EOF
wget http://nginx.org/keys/nginx_signing.key -P /etc/apt
apt-key add /etc/apt/nginx_signing.key

echo "Update packages"
sleep 3

apt-get update && apt-get upgrade -y && apt-get dist-upgrade

echo "install nginx 1.9.x php5-fpm mysql-server"
sleep 3
echo mysql-server mysql-server/root_password password $DB_ROOT_PASSWD | debconf-set-selections
echo mysql-server mysql-server/root_password_again password $DB_ROOT_PASSWD | debconf-set-selections
apt-get install -y nginx php5-fpm php5-mysql mysql-server  php5-mcrypt

echo "Config nginx"
sleep 3

mkdir /home/web
document_root="\$document_root"
uri="\$uri"
fastcgi_script_name="\$fastcgi_script_name"
args="\$args"
cp /etc/nginx/conf.d/default /etc/nginx/conf.d/default.conf
file_config='/etc/nginx/conf.d/default.conf'

cat << EOF > $file_config
server {
    listen 80;
    listen [::]:80 default_server ipv6only=on;

    root /home/web;
    index index.php index.html index.htm;

    server_name $DOMAIN;

    location / {
        #try_files $uri $uri/ =404;
        try_files $uri $uri/ /index.php?$args;

    }

    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }

    location ~ \.php$ {

        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}

EOF


sed -i 's/;cgi.fix_pathinfo=1/;cgi.fix_pathinfo=0/g' /etc/php5/fpm/php.ini
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g'  /etc/php5/fpm/pool.d/www.conf

echo "Create database wordpress"
sleep 3
mysql -uroot -p$DB_ROOT_PASSWD -e "create database $DB_NAME"
mysql -uroot -p$DB_ROOT_PASSWD -e "grant all privileges on $DB_NAME.* to $DB_USER@localhost identified by '$DB_PASS'"

echo "Download wordpress latest version"
sleep 3

wget https://wordpress.org/latest.tar.gz
tar -xvf latest.tar.gz
mv wordpress/* /home/web
rm latest.tar.gz
rm -r wordpress

cp /home/web/wp-config-sample.php /home/web/wp-config.php
sed -i 's/database_name_here/'$DB_NAME'/g' /home/web/wp-config.php
sed -i 's/username_here/'$DB_USER'/g' /home/web/wp-config.php
sed -i 's/password_here/'$DB_PASS'/g' /home/web/wp-config.php
chown -R www-data:www-data /home/web
chmod 775 /home/web/*

echo "Restart service"
sleep 3
service nginx restart
service mysql restart
service php5-fpm restat
reboot
