#!/bin/bash

##
## 1. Installs docker on all cloudlab machines in the manifest
## 2. Initializes a docker swarm in all of them
## 3. Installs docker-hadoop on the manager
##
## Invoke this script like this:
## `./prepare-cloudlab-nodes.sh manifest.xml cloudlab_username ~/.ssh/rsa_key_for_cloulab`
##
## where:
##  the first argument `manifest.xml` is a file that contains the manifest downloaded from Cloudlab
##  the second argument is the cloudlab username
##  the third argument is the cloudlab key optionally (if you pass that manually to ssh)

manifest=${1?"ERROR: No cloudlab manifest file given"}
user=${2?"ERROR: No cloudlab user given"}

pip install --user ClusterShell -q

## Optionally the caller can give us a private key for the ssh
key=$3
if [ -z "$key" ]; then
    key_flag=""
else
    key_flag="-i ${key}"
fi

grep -o 'hostname="[^\"]*"' "$manifest" | sed -E 's/^.*hostname="([^\]+)".*$/\1/g' | sort -u > hostnames.txt
echo "Hosts:"
cat hostnames.txt

##
## Install docker on all cluster machines
##
clush --hostfile hostnames.txt -O ssh_options="-oStrictHostKeyChecking=no ${key_flag}" -l $user \
    -b "curl -fsSL https://get.docker.com -o get-docker.sh && \
        sudo sh get-docker.sh && \
        sudo groupadd docker && \
        sudo usermod -aG docker $user && \
        newgrp docker"

##
## Setup docker location
##
dockerd_config='echo -e "{\n\t\"data-root\": \"/mydata\"\n}"'
clush --hostfile hostnames.txt -l $user -b "sudo bash -c '$dockerd_config > /etc/docker/daemon.json' && sudo service docker restart"
##
## Initialize a swarm from the manager
##
manager_hostname=$(head -n 1 hostnames.txt)
echo "Manager is: $manager_hostname"
{
ssh ${key_flag} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 22 ${user}@${manager_hostname} 'bash -s' <<'ENDSSH'
sudo docker swarm init --advertise-addr $(hostname -i)
# sudo docker swarm join-token worker
ENDSSH
} | tee swarm_advertise_output.txt

join_command=$(cat swarm_advertise_output.txt | grep "docker swarm join --token" | sed 's/^/sudo/g')

##
## Run join command on all swarm workers (execluding manager)
##
echo "join command is: " $join_command
clush --hostfile hostnames.txt -x "$manager_hostname" -O ssh_options="${key_flag}" -l "$user" -b $join_command

##
## Install our Hadoop infrastructure
##
ssh ${key_flag} -p 22 ${user}@${manager_hostname} 'bash -s' <<'ENDSSH'
## Just checking that the workers have joined
sudo docker node ls
git clone https://github.com/binpash/docker-hadoop.git
cd docker-hadoop

## Execute the setup with `nohup` so that it doesn't fail if the ssh connection fails
nohup sudo ./setup-swarm.sh --eval
ENDSSH