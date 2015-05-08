This repository contains some useful scripts and Dockerfiles to create Docker containers.

My need is for containers where I can do builds inside, and connect via SSH from the outside.

Please setup a public/private key pair which will be used to login to the containers via SSH:

    ssh-keygen -t rsa -C "yourname@example.org"


Some useful commands:

Installation on Fedora:

    yum install docker
    sudo systemctl start docker
    sudo systemctl enable docker

Initialize and start a container:

    ./initDockerContainer.sh 50-centos7-mymachine 50 Dockerfiles/Dockerfile.centos7
 
Show some information:

    # show all running containers
    docker ps
    # show all existing containers
    docker ps -a
    # show the docker images
    docker images
    # show overall docker info
    docker info

Stop and delete a single container:

    docker stop test9
    docker rm test9

Delete a docker image:

    docker rmi myimage

Total clean up:

    # stop all containers
    docker stop $(docker ps -q)
    # delete all containers
    docker rm $(docker ps -aq)
    # delete all images
    docker rmi $(docker images -q)

