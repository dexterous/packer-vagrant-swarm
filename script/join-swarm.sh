#!/bin/bash -eu


if [[ "$(docker system info --format '{{ .Swarm.LocalNodeState }}')" == "active" ]]; then
  echo "Warning: Worker already part of Swarm!"
  exit 0
fi

if [ ! -f /vagrant/worker-join-token ]; then
  echo >&2 "Error: Join Token not found at /vagrant/worker-join-token !"
  exit 1
fi

if [ ! -f /vagrant/master-ip-address ]; then
  echo >&2 "Error: IP address of master not found at /vagrant/master-ip-address !"
  exit 1
fi

docker swarm join \
  --advertise-addr eth1 \
  --token "$(cat /vagrant/worker-join-token)" \
  "$(cat /vagrant/master-ip-address):2377"
