This demo uses two containers, an event producer and an event
consumer. The producer creates messages and puts them into a
queue. The consumer pulls the messages, processes them and writes
summary data to a table.

# One-time setup

`git clone https://github.com/rgardler/acs-demos.git`

`cd acs-demos/demo-scripts/swarm-autoscale-script`

Create a file called `env.conf` and add the following text to it (note
you need to provide values for any of the blank items).

```
# How many actions to simulate (0 means until stopped)
SIMULATION_ACTIONS=0

# How many seconds to delay between simulated actions
SIMULATION_DELAY=1

# Which queue type to use (currently only AzureStorageQueue is supported)
AZURE_LOGGING_QUEUE_TYPE=AzureStorageQueue

# Queue name (if using Azure Queue)
AZURE_STORAGE_QUEUE_NAME=
AZURE_STORAGE_SUMMARY_TABLE_NAME=

# Azure Storage Account Details
AZURE_STORAGE_ACCOUNT_NAME=
AZURE_STORAGE_ACCOUNT_KEY=

SLACK_WEBHOOK=https://hooks.slack.com/services/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$    

# Analyzer behaviour
ANALYZER_KEEP_RUNNING=False
ANALYZER_SLEEP_TIME=0
```

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


