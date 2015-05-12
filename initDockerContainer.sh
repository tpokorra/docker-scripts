#!/bin/bash

if [ -z $3 ]
then
  echo "please call $0 <name of new container> <cid> <Dockerfile>"
  echo "eg. $0 50-centos7.example.org 50 Dockerfiles/Dockerfile.centos7"
  exit -1
fi

name=$1
cid=$2
Dockerfile=$3

myimage=$name/$cid
mycontainer=$name
sshport=$((2000+cid))

# create public key
if [ ! -f /root/.ssh/id_rsa.pub ]
then
  ssh-keygen -t rsa -C "`whoami`@`hostname -f`"
fi

# inject public key
if [ -f /root/.ssh/id_rsa.pub ]
then
  rm $Dockerfile.withkey
  key=`cat /root/.ssh/id_rsa.pub`
  authorized_keys=`cat /root/.ssh/authorized_keys`
  OLDIFS=$IFS
  IFS=$'\n'
  for line in $(cat $Dockerfile); do
    if [ $line == "__INSERTPUBLICKEY__" ]; then
      echo "RUN echo '$key' > /root/.ssh/authorized_keys" >> $Dockerfile.withkey
      echo "RUN echo '$authorized_keys' >> /root/.ssh/authorized_keys" >> $Dockerfile.withkey
    else
      echo $line
      echo $line >> $Dockerfile.withkey
    fi
  done
  IFS=$OLDIFS
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

MYAPP=$(docker run --name $mycontainer --privileged=true -p $sshport:22 -h $name -d -t -i $myimage)
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
