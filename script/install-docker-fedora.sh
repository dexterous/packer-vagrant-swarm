#!/bin/bash -eu

# package manager cleanup
dnf -qy upgrade
dnf -qy remove docker-*
dnf -qy autoremove
dnf -qy clean all

# install docker-ce repo
dnf -qy install dnf-plugins-core
dnf -qy config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# install docker-ce package
dnf -qy install docker-ce

# set docker service to run on startup
systemctl -q enable docker

# enable docker-swarm service in firewall
firewall-cmd --zone=public --add-service=docker-swarm --permanent

# add vagrant user to docker group so that we don't have to sudo all the time
usermod -aG docker vagrant
