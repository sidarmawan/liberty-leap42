#!/bin/bash

##### IP Address #####
cp etc/sysconfig/network/ifcfg-eth0 /etc/sysconfig/network/ifcfg-eth0
cp etc/sysconfig/network/ifcfg-eth1 /etc/sysconfig/network/ifcfg-eth1

##### Name Resolution #####
echo "10.10.10.20 compute" >> /etc/hosts
echo "10.10.10.30 storage" >> /etc/hosts

##### NTP Service #####
echo "server 0.opensuse.pool.ntp.org iburst" >> /etc/ntp.conf
echo "server 1.opensuse.pool.ntp.org iburst" >> /etc/ntp.conf
echo "server 2.opensuse.pool.ntp.org iburst" >> /etc/ntp.conf
echo "server 3.opensuse.pool.ntp.org iburst" >> /etc/ntp.conf
systemctl enable ntpd.service
systemctl start ntpd.service

##### Repositories #####
zypper rm patterns-openSUSE-minimal_base-conflicts
zypper ar -f obs://Cloud:OpenStack:Liberty/openSUSE_Leap_42.1 Liberty
zypper mr -R --all
zypper mr -e --all
zypper --gpg-auto-import-keys ref
zypper -n up --skip-interactive && zypper -n dist-upgrade
reboot

zypper -n in --no-recommends python-openstackclient
zypper in --no-recommends http://download.opensuse.org/repositories/Cloud:/Eucalyptus/openSUSE_Leap_42.1/noarch/euca2ools-3.0.4-1.2.noarch.rpm

##### Copy controller config directory to /root and change current directory to controller #####
cd /root/controller

##### MySQL Database Service #####
zypper -n in --no-recommends mysql-community-server mysql-community-server-client python-PyMySQL
cp etc/my.cnf.d/mysql_openstack.cnf /etc/my.cnf.d/mysql_openstack.cnf
systemctl enable mysql.service
systemctl start mysql.service
mysql -e "UPDATE mysql.user SET Password=PASSWORD('PASSWORD') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
mysql -e "FLUSH PRIVILEGES;"

##### RabbitMQ Service #####
zypper -n in --no-recommends rabbitmq-server
cp etc/systemd/system/epmd.socket /etc/systemd/system/epmd.socket
systemctl enable epmd.service
systemctl restart epmd.service
sleep 5
systemctl enable rabbitmq-server.service
systemctl start rabbitmq-server.service
rabbitmqctl add_user openstack PASSWORD
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

##### Keystone Identity Service #####
mysql -u root -pPASSWORD -e "CREATE DATABASE keystone; GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'PASSWORD'; GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'PASSWORD';"
zypper -n in --no-recommends openstack-keystone apache2-mod_wsgi memcached python-python-memcached python-dateutil python-pyOpenSSL python-pycrypto python-repoze.who
systemctl enable memcached.service
systemctl start memcached.service
cp etc/keystone/keystone.conf /etc/keystone/keystone.conf
su -s /bin/sh -c "keystone-manage db_sync" keystone
cp etc/sysconfig/apache2 /etc/sysconfig/apache2
cp etc/apache2/conf.d/wsgi-keystone.conf /etc/apache2/conf.d/wsgi-keystone.conf
chown -R keystone:keystone /etc/keystone
a2enmod version
systemctl enable apache2.service
systemctl start apache2.service

##### Service Entity and API Endpoints #####
export OS_TOKEN=989043457bc44d941be4
export OS_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
openstack service create --name keystone --description "OpenStack Identity" identity
openstack endpoint create --region RegionOne identity public http://controller:5000/v2.0
openstack endpoint create --region RegionOne identity internal http://controller:5000/v2.0
openstack endpoint create --region RegionOne identity admin http://controller:35357/v2.0
openstack project create --domain default --description "Admin Project" admin
openstack user create --domain default --password PASSWORD admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --domain default --description "Service Project" service
openstack role create user
cp root/admin-openrc.sh /root/admin-openrc.sh
unset OS_TOKEN OS_URL OS_IDENTITY_API_VERSION
source /root/admin-openrc.sh 
openstack token issue

##### Glance Image Service #####
mysql -u root -pPASSWORD -e "CREATE DATABASE glance; GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'PASSWORD'; GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'PASSWORD';"
source /root/admin-openrc.sh
openstack user create --domain default --password PASSWORD glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image
openstack endpoint create --region RegionOne image public http://controller:9292
openstack endpoint create --region RegionOne image internal http://controller:9292
openstack endpoint create --region RegionOne image admin http://controller:9292
zypper -n in --no-recommends openstack-glance python-glanceclient
cp etc/glance/glance-api.conf /etc/glance/glance-api.conf
cp etc/glance/glance-registry.conf /etc/glance/glance-registry.conf
chown root:glance /etc/glance/glance-api.conf /etc/glance/glance-registry.conf
systemctl enable openstack-glance-api.service openstack-glance-registry.service
systemctl start openstack-glance-api.service openstack-glance-registry.service
glance image-list

##### Nova Compute Service #####
mysql -u root -pPASSWORD -e "CREATE DATABASE nova; GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'PASSWORD'; GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'PASSWORD';"
source /root/admin-openrc.sh
openstack user create --domain default --password PASSWORD nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://controller:8774/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://controller:8774/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://controller:8774/v2/%\(tenant_id\)s
zypper -n in --no-recommends openstack-nova-api openstack-nova-scheduler openstack-nova-cert openstack-nova-conductor openstack-nova-consoleauth openstack-nova-novncproxy python-novaclient iptables
cp etc/nova/nova.conf /etc/nova/nova.conf
chown root:nova /etc/nova/nova.conf
systemctl enable openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
systemctl start openstack-nova-api.service openstack-nova-cert.service openstack-nova-consoleauth.service openstack-nova-scheduler.service openstack-nova-conductor.service openstack-nova-novncproxy.service
nova service-list
nova endpoints
nova image-list

##### Neutron Networking Service #####
mysql -u root -pPASSWORD -e "CREATE DATABASE neutron; GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'PASSWORD'; GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'PASSWORD';"
source /root/admin-openrc.sh
openstack user create --domain default --password PASSWORD neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://controller:9696
openstack endpoint create --region RegionOne network internal http://controller:9696
openstack endpoint create --region RegionOne network admin http://controller:9696
zypper -n in --no-recommends openstack-neutron openstack-neutron-server openstack-neutron-linuxbridge-agent openstack-neutron-l3-agent openstack-neutron-dhcp-agent openstack-neutron-metadata-agent ipset bridge-utils
cp etc/neutron/neutron.conf /etc/neutron/neutron.conf
chown root:neutron /etc/neutron/neutron.conf
cp etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
cp etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
cp etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
cp etc/neutron/dnsmasq-neutron.conf /etc/neutron/dnsmasq-neutron.conf
cp etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini
systemctl enable openstack-neutron.service openstack-neutron-linuxbridge-agent.service openstack-neutron-dhcp-agent.service openstack-neutron-metadata-agent.service openstack-neutron-l3-agent.service
systemctl start openstack-neutron.service openstack-neutron-linuxbridge-agent.service openstack-neutron-dhcp-agent.service openstack-neutron-metadata-agent.service openstack-neutron-l3-agent.service

##### Horizon Dashboard #####
zypper -n in --no-recommends openstack-dashboard
cp etc/apache2/conf.d/openstack-dashboard.conf /etc/apache2/conf.d/openstack-dashboard.conf
a2enmod rewrite;a2enmod ssl;a2enmod wsgi
cp srv/www/openstack-dashboard/openstack_dashboard/local/local_settings.py /srv/www/openstack-dashboard/openstack_dashboard/local/local_settings.py
chown wwwrun:www /srv/www/openstack-dashboard/openstack_dashboard/local/local_settings.py
systemctl enable apache2.service memcached.service
systemctl restart apache2.service memcached.service

