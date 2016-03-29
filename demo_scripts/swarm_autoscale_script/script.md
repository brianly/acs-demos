This demo uses two containers, an event producer and an event
consumer. The producer creates messages and puts them into a
queue. The consumer pulls the messages, processes them and writes
summary data to a table.

# One-time setup

`git clone https://github.com/rgardler/acs-demos.git`

`cd acs-demos/demo-scripts/swarm-autoscale-script`

`cp env.conf.tmpl env.conf`

edit `env.conf` and add values for any of the blank parameters.

## Create a Swarm ACS cluster and verify connection

Create the cluster using the 101-swarm Quickstart template

`ssh -L 2375:localhost:2375 azureuser@coreyacsbuildmgmt.westus.cloudapp.azure.com -p 2200`

First time you do this you will need to add the hosts fingerprint to
your known hosts ('ECDSA key fingerprint is
a0:1c:3c:dc:3c:16:19:1d:c4:cd:57:ba:3b:b9:65:29.'), once done exit the
session and then repeat with the following to have it run in the
background.

`ssh -L 2375:localhost:2375 -N azureuser@coreyacsbuildmgmt.westus.cloudapp.azure.com -p 2200 &`

On your client (since the above SSH should be in the background):

`export DOCKER_HOST=:2375`

`docker info`

In the output you should see something like 'Nodes: 2' (depending on how many agent nodes you requested) 
# Pre-Demo Setup

`ssh -L 2375:localhost:2375 -N azureuser@coreyacsbuildmgmt.westus.cloudapp.azure.com -p 2200 &`

`./setup.sh'

# Run Demo

`./autoscale`


