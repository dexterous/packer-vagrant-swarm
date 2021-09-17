# Docker Swarm in a Box(ish)

This configuration uses a combination of [Packer](https://packer.io) and [Vagrant](https://vagrantup.com) to setup a
[Docker Swarm](https://docs.docker.com/engine/swarm/) cluster and deploys the [Portainer](https://www.portainer.io/)
stack to it.


## Prequisites

* [Packer](https://packer.io/downloads)
* [Vagrant](https://vagrantup.com/downloads)
* [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
* [Docker](https://www.docker.com/get-started)


## Create base image (Fedora + Docker)

```sh
$ packer build packer/swarm-box.pkr.hcl
vagrant.fedora: output will be in this color.

==> vagrant.fedora: Creating a Vagrantfile in the build directory...
==> vagrant.fedora: Adding box using vagrant box add ...
    vagrant.fedora: (this can take some time if we need to download the box)
==> vagrant.fedora: Calling Vagrant Up (this can take some time)...
==> vagrant.fedora: Using SSH communicator to connect: 127.0.0.1
==> vagrant.fedora: Waiting for SSH to become available...
==> vagrant.fedora: Connected to SSH!
==> vagrant.fedora: Provisioning with shell script: ./script/install-docker.sh
...
```

This will pull down the `generic/fedoraXX` box and perform the following modifications to it:

(Refer [script/install-docker.sh](script/install-docker.sh) for specifc commands.)

* Remove any legacy `docker` packges
* Install `docker-ce` from [official Docker YUM repo](https://download.docker.com/linux/fedora/docker-ce.repo)
* Set `docker` to run as a `SystemD` service and start on boot
* Enable `docker-swarm` service in `firewalld` so that Swarm workers can talk to Swarm master
* Add `vagrant` uer to `docker` group so that you don't have to `sudo` every time you want to run `docker` commands

A successful `packer` build will generate a ready-tuo use Vagrant setup in `output-*` directory

```sh
$ ls output-*
.rw-r--r-- 1.6G ysxm180 16 Sep 22:09 package.box
.rw-r--r-- 1.2k ysxm180 16 Sep 22:11 Vagrantfile
```


## Fire up the Swarm

```sh
$ cd output-*

$ vagrant status
Current machine states:

source                    not created (virtualbox)
master                    not created (virtualbox)
worker0                   not created (virtualbox)
worker1                   not created (virtualbox)
worker2                   not created (virtualbox)
worker3                   not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.

$ vagrant up
Bringing machine 'master' up with 'virtualbox' provider...
Bringing machine 'worker0' up with 'virtualbox' provider...
Bringing machine 'worker1' up with 'virtualbox' provider...
...
```

This will bring up the `master` box along with 2 of the 4 `workers`

```sh
$ vagrant status
Current machine states:

source                    not created (virtualbox)
master                    running (virtualbox)
worker0                   running (virtualbox)
worker1                   running (virtualbox)
worker2                   not created (virtualbox)
worker3                   not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
```


## Initialize Swarm (automated)

The Swarm initialization, both `master` and `worker`, are automated using Vagrant provisioning scripts.

The [`master` provisioning script](script/init-swarm.sh) does the following:

* Initialize a Swarm master (if not already setup)
* Write `worker` join token to `worker-join-token` file
* Write IP that Swarm `master` is listening on to `master-ip-address` file

The [`worker` provisioning script](script/join-swarm.sh) does the following:

* Check if the node is already part of a Swarm; if so, just exit
* Join the Swarm using the `master` IP and `worker` join token published by the `master` above


## Initialize Portainer

Once the `master` box is up and proivisioned it will have a running Protainer containers awaiting setup of it `admin`
user. Navigate to [http://localhost:9000/](http://localhost:9000/) and setup a password for the `admin` user to complete
this setup.

Following that, Portainer should show you the `primary` cluster. You can then navigate to the [Cluster
Visualizer](http://localhost:9000/#!/1/docker/swarm/visualizer) to watch the `worker` nodes come up and register
themselves one by one.


## Interact with the Swarm `master`

Since the `master` box is marked `primary`, `vagrant` commands without a box name/id will be directed to it and we can
run `docker` commands on the `master` to interact with the Swarm.

```sh
$ vagrant ssh -- docker node ls
ID                            HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS   ENGINE VERSION
t6ibmznksnxbyvprgo53o03fv *   master     Ready     Active         Leader           20.10.8
rr2egvfpw4kbo0msbjmmh22vm     worker0    Ready     Active                          20.10.8
k6lv9ut0nrk4vq6k1sx6fx5f0     worker1    Down      Active                          20.10.8
```


## Scale Swarm

You can scale the Swarm up or down by bringing `up` or `halt`ing `worker` boxes.

```sh
$ vagrant up /worker[23]/
Bringing machine 'worker2' up with 'virtualbox' provider...
Bringing machine 'worker3' up with 'virtualbox' provider...
...

$ vagrant halt /worker[12]/
==> worker2: Attempting graceful shutdown of VM...
==> worker1: Attempting graceful shutdown of VM...
```

The [Cluster Visualizer](http://localhost:9000/#!/1/docker/swarm/visualizer) should update to show the new nodes as they
come up and register with the master.


## Deploy services to Swarm

Use `docker service` or `docker stack` commands to deploy to the Swarm.

```sh
$ vagrant ssh -- docker service create --name web -p 8080:80 --replicas 3 nginx:stable-alpine
67flc565ip4h2cb88x25m4hp6
overall progress: 0 out of 3 tasks
1/3:
2/3:
3/3:
overall progress: 0 out of 3 tasks
overall progress: 0 out of 3 tasks
overall progress: 3 out of 3 tasks
verify: Waiting 5 seconds to verify that tasks are stable...
verify: Waiting 5 seconds to verify that tasks are stable...
verify: Waiting 5 seconds to verify that tasks are stable...
...
verify: Waiting 2 seconds to verify that tasks are stable...
verify: Waiting 1 seconds to verify that tasks are stable...
verify: Waiting 1 seconds to verify that tasks are stable...
verify: Waiting 1 seconds to verify that tasks are stable...
verify: Service converged

$ vagrant ssh -- docker service ls
ID             NAME                  MODE         REPLICAS   IMAGE                           PORTS
3jnb4awsw9pa   portainer_agent       global       5/3        portainer/agent:latest
rn0mi93om5tn   portainer_portainer   replicated   1/1        portainer/portainer-ce:latest   *:8000->8000/tcp, *:9000->9000/tcp
67flc565ip4h   web                   replicated   3/3        nginx:stable-alpine             *:8080->80/tcp

$ vagrant ssh -- docker service ps web
ID             NAME      IMAGE                 NODE      DESIRED STATE   CURRENT STATE                ERROR     PORTS
urvgwc33toai   web.1     nginx:stable-alpine   worker1   Running         Running about a minute ago
c4w0jj3hu3zw   web.2     nginx:stable-alpine   worker0   Running         Running about a minute ago
4odncmllspxx   web.3     nginx:stable-alpine   master    Running         Running about a minute ago
```

To access the service, you will have to add a port forwarding for port 8080 of the `master` box. You can either use the
`VBoxManage` command or add the forward in the VirtualBox UI by navigating to the `master` box's Settings > Network >
Adapter 1 > Advanced > Port Forwarding.
