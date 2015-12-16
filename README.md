# liberty_leap42.1

This repo contains commands and configurations for manually install core services of OpenStack Liberty by using packages on openSUSE Leap 42.1 through the Open Build Service Cloud repository. The core services in this installation only include Keystone Identity, Glance Image, Nova Compute, Neutron Networking, Horizon Dashboard and Cinder Block Storage. The architecture in this installation intended to assist new users of OpenStack to understand basic installation, configuration and operation of OpenStack core services. The architecture is not recommended for production environment. The architecture is using 3 VirtualBox nodes for controller, compute and storage.

__Main Reference:__
- OpenStack Installation Guide for openSUSE 13.2 and SUSE Linux Enterprise Server 12 through the Open Build Service Cloud repository (http://docs.openstack.org/liberty/install-guide-obs/)

__Minimum requirements:__
- Desktop/laptop with 2 cores 64bit processor and 8 GB RAM.
- 3 VirtualBox guests of openSUSE Leap 42.1 minimal installation. Node controller: 2 core CPU, 2 GB RAM, 8 GB HDD. Node compute: 2 core CPU, 2 GB RAM, 8 GB HDD. Node storage: 1 core CPU, 1 GB RAM, 2 x 8 GB HDD.

__Topology:__
![alt tag](https://github.com/utianayuba/liberty_leap42.1/raw/master/topology/topology.png)

__Installation:__

1. Create new virtual openSUSE Leap 42.1 minimal installation. No network adapter, disable firewall and enable SSH service.
2. Clone the virtual into 3 nodes. Add network adapter(s) to each of node and arrange the topology as shown above.
3. Copy directory of node commands and configurations to each node into /root directory.
4. SSH to each node as root and change the shell working directory to the node config directory.
5. Copy commands from liberty_*_commands.txt file and paste it into the SSH terminal of each node. Do the copy and paste command(s) per line or per section so you can see the command(s) executed successfully or not.

__Notes:__

1. There is a problem with neutron-l3-agent service when use iproute2-v4 package from openSUSE Leap 42.1 repo. This installation use [iproute2-3.16-2.7.1.x86_64.rpm](http://download.opensuse.org/update/13.2/x86_64/iproute2-3.16-2.7.1.x86_64.rpm) package from openSUSE 13.2 update repo.
2. openstack-nova package need euca2ools package to be installed. The euca2ools package can be installed from Eucalyptus OBS cloud repository.
