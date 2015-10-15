#!/bin/bash -ex
#
source config.cfg
 
echo "manual" > /etc/init/keystone.override
 
echo "##### Install keystone #####"
apt-get install keystone python-openstackclient apache2 libapache2-mod-wsgi memcached python-memcache -y
 
#/* Back-up file nova.conf
filekeystone=/etc/keystone/keystone.conf
test -f $filekeystone.orig || cp $filekeystone $filekeystone.orig
 
#Config file /etc/keystone/keystone.conf
cat << EOF > $filekeystone
[DEFAULT]
admin_token = $TOKEN_PASS
verbose = true
log_dir = /var/log/keystone
[assignment]
[auth]
[cache]
[catalog]
[credential]
[database]
connection = mysql://keystone:$KEYSTONE_DBPASS@$CON_MGNT_IP/keystone
[domain_config]
[endpoint_filter]
[endpoint_policy]
[eventlet_server]
admin_port= 35358
public_port= 5005
[eventlet_server_ssl]
[federation]
[fernet_tokens]
[identity]
[identity_mapping]
[kvs]
[ldap]
[matchmaker_redis]
[matchmaker_ring]
[memcache]
servers = localhost:11211
[oauth1]
[os_inherit]
[oslo_messaging_amqp]
[oslo_messaging_qpid]
[oslo_messaging_rabbit]
[oslo_middleware]
[oslo_policy]
[paste_deploy]
[policy]
[resource]
[revoke]
driver = keystone.contrib.revoke.backends.sql.Revoke
[role]
[saml]
[signing]
[ssl]
[token]
provider = keystone.token.providers.uuid.Provider
driver = keystone.token.persistence.backends.memcache.Token
[trust]
[extra_headers]
Distribution = Ubuntu
EOF
 
#
su -s /bin/sh -c "keystone-manage db_sync" keystone
 
echo "ServerName $CON_MGNT_IP" > /etc/apache2/conf-available/servername.conf
sudo a2enconf servername
 
cat << EOF > /etc/apache2/sites-available/wsgi-keystone.conf
Listen 5005
Listen 35358
 
<VirtualHost *:5005>
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIScriptAlias / /var/www/cgi-bin/keystone/main
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    LogLevel info
    ErrorLog /var/log/apache2/keystone-error.log
    CustomLog /var/log/apache2/keystone-access.log combined
</VirtualHost>
 
<VirtualHost *:35358>
    WSGIDaemonProcess keystone-admin processes=5 threads=1 user=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-admin
    WSGIScriptAlias / /var/www/cgi-bin/keystone/admin
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    LogLevel info
    ErrorLog /var/log/apache2/keystone-error.log
    CustomLog /var/log/apache2/keystone-access.log combined
</VirtualHost>
 
EOF
 
ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
 
mkdir -p /var/www/cgi-bin/keystone
 
curl http://git.openstack.org/cgit/openstack/keystone/plain/httpd/keystone.py?h=stable/kilo \
  | tee /var/www/cgi-bin/keystone/main /var/www/cgi-bin/keystone/admin
 
chown -R keystone:keystone /var/www/cgi-bin/keystone
 
chmod 755 /var/www/cgi-bin/keystone/*
 
service apache2 restart
 
rm -f /var/lib/keystone/keystone.db