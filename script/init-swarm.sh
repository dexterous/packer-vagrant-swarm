#!/bin/bash -eu

if ! docker swarm init --advertise-addr eth1 >/dev/null 2>&1; then
  echo "Warning: Swarm already init'd!"
fi

echo 'Caching worker join-token... '
docker swarm join-token --quiet worker >/vagrant/worker-join-token
echo '... done!'

echo 'Caching master IP address... '
ip -brief -family inet address | grep '^eth1' | \
  tr -s ' ' ' ' | cut -d ' ' -f3 | cut -d '/' -f 1 \
  >/vagrant/master-ip-address
echo '... done!'

docker stack deploy -c ~vagrant/stack/portainer-agent-stack.yml portainer
