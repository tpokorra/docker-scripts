#!/bin/bash

if [ -z $3 ]
then
  echo "please call $0 <name of new container> <cid> <Dockerfile>"
  echo "eg. $0 50-centos7.example.org 50 Dockerfiles/Dockerfile.centos7"
  exit -1
fi

name=$1
shift
cid=$1
shift
Dockerfile=$1
shift
mount=$*

myimage=$name/$cid
mycontainer=$name
sshport=$((2000+cid))

if [ ! -f $Dockerfile ]
then
  echo "Missing Dockerfile: " $Dockerfile
  exit -1
fi

# create public key
if [ ! -f /root/.ssh/id_rsa.pub ]
then
  ssh-keygen -t rsa -C "`whoami`@`hostname -f`"
fi

# inject public key
if [ -f /root/.ssh/id_rsa.pub ]
then
  rm -f $Dockerfile.withkey
  key=`cat /root/.ssh/id_rsa.pub`
  authorized_keys=`cat /root/.ssh/authorized_keys`
  OLDIFS=$IFS
  IFS=$'\n'
  for line in $(cat $Dockerfile); do
    if [ $line == "#__INSERTPUBLICKEY__" ]; then
      echo "RUN echo '$key' >> /root/.ssh/authorized_keys" >> $Dockerfile.withkey
      for authline in $(cat /root/.ssh/authorized_keys); do
        echo "RUN echo '$authline' >> /root/.ssh/authorized_keys" >> $Dockerfile.withkey
      done
    else
      echo $line >> $Dockerfile.withkey
    fi
  done
  IFS=$OLDIFS
  origDockerfile=$Dockerfile
  Dockerfile=$Dockerfile.withkey
fi

if [[ "$http_proxy" != "" ]]
then
  if [ ! -f /etc/systemd/system/docker.service.d/http-proxy.conf ]
  then
    mkdir -p /etc/systemd/system/docker.service.d
    cat > /etc/systemd/system/docker.service.d/http-proxy.conf << FINISH
[Service]
Environment="HTTP_PROXY=$http_proxy"
Environment="HTTPS_PROXY=$https_proxy"
FINISH
    systemctl daemon-reload
    systemctl restart docker
  fi
fi

cat $Dockerfile | docker build \
  --build-arg https_proxy=$https_proxy --build-arg http_proxy=$http_proxy \
  -t $myimage -
if [ $? -ne 0 ]
then
  echo
  echo
  echo "error building the container"
  echo
  echo
  exit -1
fi

echo "starting the container"
#echo "docker run -e https_proxy=$https_proxy -e http_proxy=$http_proxy --name $mycontainer --privileged=true $mount -p $sshport:22 -h $name -d -t -i $myimage"
MYAPP=$(docker run -e https_proxy=$https_proxy -e http_proxy=$http_proxy --name $mycontainer --privileged=true $mount -p $sshport:22 -h $name -d -t -i $myimage)
if [ $? -ne 0 ]
then
  echo "problem starting the container"
  echo "command line was: "
  echo "docker run --name $mycontainer --privileged=true $mount -p $sshport:22 -h $name -d -t -i $myimage"
  echo
  exit -1
fi

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
