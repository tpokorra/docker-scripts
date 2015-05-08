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

# inject public key
if [ -f /root/.ssh/id_rsa.pub ]
then
  key=`cat /root/.ssh/id_rsa.pub`
  cat $Dockerfile | sed -e "s~#__INSERTPUBLICKEY__~RUN echo '$key'  > /root/.ssh/authorized_keys~g" > $Dockerfile.withkey
  origDockerfile=$Dockerfile
  Dockerfile=$Dockerfile.withkey
fi

cat $Dockerfile | docker build -t $myimage -
if [ $? -ne 0 ]
then
  echo
  echo
  echo "error building the container"
  echo
  echo
  exit -1
fi

echo "sudo docker run --name $mycontainer --privileged=true -p $sshport:22 -h $name -d -t -i $myimage"
MYAPP=$(sudo docker run --name $mycontainer --privileged=true -p $sshport:22 -h $name -d -t -i $myimage)
docker port $mycontainer 22
if [ -f /root/.ssh/known_hosts ]
then
  ssh-keygen -f "/root/.ssh/known_hosts" -R [localhost]:$sshport
fi

echo
echo
echo connect to the container with: ssh -p $sshport root@localhost
echo
echo

if [[ $Dockerfile == $origDockerfile.withkey ]]
then
  rm -f $Dockerfile
fi
