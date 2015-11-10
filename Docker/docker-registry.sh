echo "Install dependence package"
sleep 3
apt-get -y install build-essential python-dev libevent-dev python-pip liblzma-dev swig libssl-dev

echo "Install docker-registry"
sleep 3
pip install docker-registry


echo "Config docker-registry"
sleep 3
cp /usr/local/lib/python2.7/dist-packages/config/config_sample.yml /usr/local/lib/python2.7/dist-packages/config/config.yml

sed -i "s/\/tmp\/docker-registry.db/\/var\/docker-registry\/docker-registry.db/g" /usr/local/lib/python2.7/dist-packages/config/config.yml 

sed -i 's/\/tmp\/registry/\/var\/docker-registry/g' /usr/local/lib/python2.7/dist-packages/config/config.yml
mkdir /var/docker-registry
mkdir /var/log/docker-registry

config=/etc/init/docker-registry.conf
cat << EOF > $config

description "Docker Registry"
start on runlevel [2345]
stop on runlevel [016]
respawn
respawn limit 10 5 
script
exec gunicorn --access-logfile /var/log/docker-registry/access.log --error-logfile /var/log/docker-registry/server.log -k gevent --max-requests 100 --graceful-timeout 3600 -t 3600 -b localhost:5000 -w 8 docker_registry.wsgi:application
end script
EOF

echo "start docker-registry"
sleep 2

service docker-registry start

echo "test docker-registry"
sleep 2
curl localhost:5000


echo "Install nginx"
sleep 2

apt-get install -y nginx apache2-utils
touch /etc/nginx/sites-available/docker-registry
http_host='$http_host'
remote_addr='$remote_addr'
nginx_config=/etc/nginx/sites-available/docker-registry
cat <<EOF >$nginx_config
# For versions of Nginx > 1.3.9 that include chunked transfer encoding support
# Replace with appropriate values where necessary

upstream docker-registry {
 server localhost:5000;
}

server {
 listen 8080;
 server_name saphi-docker.com;

 ssl on;
 ssl_certificate /etc/ssl/certs/docker-registry;
 ssl_certificate_key /etc/ssl/private/docker-registry;

 proxy_set_header Host       $http_host;   # required for Docker client sake
 proxy_set_header X-Real-IP  $remote_addr; # pass on real client IP

 client_max_body_size 0; # disable any limits to avoid HTTP 413 for large image uploads

 # required to avoid HTTP 411: see Issue #1486 (https://github.com/dotcloud/docker/issues/1486)
 chunked_transfer_encoding on;

 location / {
     # let Nginx know about our auth file
     auth_basic              "Restricted";
     auth_basic_user_file    docker-registry.htpasswd;

     proxy_pass http://docker-registry;
 }
 location /_ping {
     auth_basic off;
     proxy_pass http://docker-registry;
 }  
 location /v1/_ping {
     auth_basic off;
     proxy_pass http://docker-registry;
 }

}
EOF
unset http_host
unset remote_addr
service nginx restart
#run if you use your key create by openssl
#openssl genrsa -out devdockerCA.key 2048

#openssl req -x509 -new -nodes -key devdockerCA.key -days 10000 -out devdockerCA.crt

#openssl genrsa -out saphi-docker.com.key 2048

#openssl req -new -key saphi-docker.com.key -out saphi-docker.com.csr


#openssl x509 -req -in saphi-docker.com.csr -CA devdockerCA.crt -CAkey devdockerCA.key -CAcreateserial -out saphi-docker.com.crt -days 10000


#cp saphi-docker.com.crt /etc/ssl/certs/docker-registry

#chmod 777 /etc/ssl/certs/docker-registry

#cp saphi-docker.com.key /etc/ssl/private/docker-registry

#chmod 777 /etc/ssl/private/docker-registry

#mkdir /usr/local/share/ca-certificates/docker-dev-cert

#cp devdockerCA.crt /usr/local/share/ca-certificates/docker-dev-cert

#update-ca-certificates

