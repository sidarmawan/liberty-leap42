#!/bin/bash

##### Repositories #####
rm -rf /etc/zypp/repos.d/repo-debug*
rm -rf /etc/zypp/repos.d/repo-source*
zypper ar http://download.opensuse.org/repositories/Cloud:/OpenStack:/Liberty/openSUSE_Leap_42.1/Cloud:OpenStack:Liberty.repo
zypper mr -R --all
zypper mr -e --all
zypper ref
zypper up --skip-interactive
zypper -n in python-openstackclient

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
