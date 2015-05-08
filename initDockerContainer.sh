#!/bin/bash

if [ -z $3 ]
then
  echo "please call $0 <name of new container> <cid> <Dockerfile>"
  echo "eg. $0 50-centos7-mymachine 50 Dockerfiles/Dockerfile.centos7"
  exit -1
fi

name=$1
cid=$2
Dockerfile=$3

myimage=$name/$cid
mycontainer=$name
sshport=20$cid

cat $Dockerfile | docker build -t $myimage -
MYAPP=$(sudo docker run --name $mycontainer --privileged=true -p $sshport:22 -h $name -d -t -i $myimage)
docker port $mycontainer 22
ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:$sshport

echo connect to the container with: ssh -p $sshport root@localhost
