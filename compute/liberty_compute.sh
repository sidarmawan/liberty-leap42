#!/bin/bash

##### Repositories #####
rm -rf /etc/zypp/repos.d/repo-debug*
rm -rf /etc/zypp/repos.d/repo-source*
zypper ar http://download.opensuse.org/repositories/Cloud:/OpenStack:/Liberty/openSUSE_Leap_42.1/Cloud:OpenStack:Liberty.repo
zypper mr -R --all
zypper mr -e --all
zypper ref
zypper up --skip-interactive
zypper -n in --no-recommends python-openstackclient

##### Name Resolution #####
echo "10.10.10.10 controller" >> /etc/hosts
echo "10.10.10.30 storage" >> /etc/hosts

##### NTP Service #####
echo "server 0.opensuse.pool.ntp.org iburst" >> /etc/ntp.conf
echo "server 1.opensuse.pool.ntp.org iburst" >> /etc/ntp.conf
echo "server 2.opensuse.pool.ntp.org iburst" >> /etc/ntp.conf
echo "server 3.opensuse.pool.ntp.org iburst" >> /etc/ntp.conf
systemctl enable ntpd.service
systemctl start ntpd.service

##### Compute #####
zypper in --no-recommends http://download.opensuse.org/repositories/Cloud:/Eucalyptus/openSUSE_Leap_42.1/noarch/euca2ools-3.0.4-1.2.noarch.rpm
zypper -n in --no-recommends openstack-nova-compute genisoimage qemu-kvm libvirt
cp etc/nova/nova.conf /etc/nova/nova.conf
chown root:nova /etc/nova/nova.conf
modprobe nbd
cp etc/modules-load.d/nbd.conf /etc/modules-load.d/nbd.conf
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service

##### Neutron #####
zypper -n in --no-recommends openstack-neutron-linuxbridge-agent ipset
cp etc/neutron/neutron.conf /etc/neutron/neutron.conf
chown root:neutron /etc/neutron/neutron.conf
cp etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
systemctl enable openstack-neutron-linuxbridge-agent.service
systemctl start openstack-neutron-linuxbridge-agent.service

