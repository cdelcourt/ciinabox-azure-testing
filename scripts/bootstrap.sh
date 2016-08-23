#!/bin/bash

export REGION=$1
export AZURE_TAG_ROLE=$2
export ENVIRONMENT_TYPE=$3
export DOMAIN_NAME=$4

export HOME=/root

# Likely not required, but if access is needed to pull from storage accounts fill in the following
export AZURE_STORAGE_ACCOUNT=
export AZURE_STORAGE_ACCESS_KEY=

#If npm doesn't exist, install npm and Azure CLI
rpm -qa | grep -qw "epel-release" || yum install -y epel-releas
rpm -qa | grep -qw nodejs || curl --silent --location https://rpm.nodesource.com/setup_4.x | bash - && yum install -y nodejs && npm install -g azure-cli
rpm -qa | grep -qw python-pip || yum install -y python-pip

if [ -f /etc/profile.d/env.sh ]; then
  source /etc/profile.d/env.sh
fi

# Configure and start the docker service
#yum update -y ### REMEMBER TO EXCLUDE WAAGENT WHEN RE-ENABLING THIS
curl -fsSL https://get.docker.com/ | sh
service docker start

# Configure and run the Ciinabox containers in screen
screen -S jwilder -d -m docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro jwilder/nginx-proxy
screen -S ciinabox-jenkins -d -m docker run -e VIRTUAL_HOST=$DOMAIN_NAME -e VIRTUAL_PORT=8080  base2/ciinabox-jenkins
screen -S ciinabox-slave-jenkins -d -m docker run --name jenkins-docker-slave --privileged=true -d -e PORT=4444 -p 4444:4444 -p 2223:22 -v /data/dind/:/var/lib/docker ciinabox-jenkins-slave:testing start-dind
