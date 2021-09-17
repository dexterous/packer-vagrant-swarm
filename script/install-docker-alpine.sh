#!/bin/bash -eu

# package manager cleanup
apk update
apk upgrade

# install docker package
apk add docker

# set docker service to run on startup
rc-update add docker boot
