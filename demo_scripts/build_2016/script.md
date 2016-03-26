This demo uses many different containers to provide a complete
end-to-end solution.

# Deploying the application

Because this is a complex application we need to use docker-compose or
Marathon to deploy and manage it in a runtime environment.

Let's start with the Swarm version.

```
docker-compose up -d
```

Results:

```
Creating build2016_web_qna_1
Creating build2016_rest_qna_1
Creating build2016_rest_enque_qna_1
Creating build2016_analyzer_qna_1
```

Here we started multiple containers:

  * a web front end for engaging with our application
  * a rest endpoint for providing data for the web application
  * a rest API for writing messages to a queue 
  * an analyzer which will process messages in that queue

The web front end allows visitors to answer multiple choice
questions. These are provided by the REST QNA container. When the user
submits an answer it is sent to the queue for processing by the
application while the user is given immediate feedback on their
performance.

The Analyzer will examine the queue to see if there is any work for it
to do, if it finds none it will shutdown. Since there is nothing in
the queue (assuming you started with a new queue) the anlyzer will
startup but immediately shut down.

# Working with the Message Queue

Lets have a look at the queue and summary table: which is updated by
the analyzer container. The following command will print out the
current queue length and the summary table contants.

```
docker run --env-file env.conf rgardler/acs-logging-test-cli summary
```

Results:

```
Queue Length is approximately: 0

Processed events:
Errors: 0
Warnings: 0
Infos: 0
Debugs: 0
Others: 0
```

# Writing Messages to the Queue

The "rest_enqueue" container provides a REST API for writing events to
the queue, so lets write one:

```
curl -X POST -d queue=rgbuildacsdemo -d message="Demo - Hello world!" http://localhost:5000/enqueue
```

Results:

```
{
  "message": "INFO - Hello world!",
  "queue": "rgbuildacsdemo",
  "result": "success",
  "storage_account": "acstests"
}
```

Since the queue was empty before this message was sent the analyzer
will already have shut down. This means that the message we just
placed in the queue should still be there. Lets check:

```
docker run --env-file env.conf rgardler/acs-logging-test-cli summary
```

Results:

```
Queue Length is approximately: 1

Processed events:
Errors: 0
Warnings: 0
Infos: 0
Debugs: 0
Others: 0
```

# Starting Analyzers

Our application will have some kind of logic within it that will start
analyzers when necessary. For now lets start an analyzer manually to
see what happens.

```
docker-compose up -d
```

Results:

```
build2016_rest_enqueue_1 is up-to-date
Starting build2016_analyzer_1
```

Notice that most of the containers are already up-to-date, but since
the analyzer was not running, and our compose files specifies that
there should be one, it is re-started. It will process all the
messages in the queue and then shutdown. So lets take a look at the
data summary:

```
docker run --env-file env.conf rgardler/acs-logging-test-cli summary
```

Results:

```
Queue Length is approximately: 0

Processed events:
Errors: 0
Warnings: 0
Infos: 1
Debugs: 0
Others: 0
```

The queue is now empty and the Info count has been increased.

# Creating Load on the Application

Using another container we will create load on the application. This
will use Apache JMeter to simluate one hundred concurrent users with
one thousand total requests. To do this we run:

```
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 100 -d "queue=rgbuildacsdemo&message=CORRECT%20-%20Question_1 - Answer_A" &
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 5 -d "queue=rgbuildacsdemo&message=INCORRECT%20-%20Question_1 - Answer_B" & 
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 7 -d "queue=rgbuildacsdemo&message=INCORRECT%20-%20Question_1 - Answer_C" & 
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 1 -d "queue=rgbuildacsdemo&message=INCORRECT%20-%20Question_1 - Answer_D" &
```

This will take a little while to run, but we can inspect the queue
while it is happening:

```
docker run --env-file env.conf rgardler/acs-logging-test-cli summary
```

# Scaling up in Response to a Growing Queue

Now that the queue is growing a single analyzer is not going to be
enough, so lets scale the analyzers up.

```
docker-compose scale analyzer=10
```

Results:

```
Creating and starting 3 ...
Creating and starting 4 ...
Creating and starting 5 ...
Creating and starting 6 ...
Creating and starting 7 ...
Creating and starting 8 ...
Creating and starting 9 ...
Creating and starting 10 ...
Creating and starting 2 ... done
Creating and starting 7 ... done
Creating and starting 3 ... done
Creating and starting 6 ... done
Creating and starting 8 ... done
Creating and starting 4 ... done
Creating and starting 10 ... done
Creating and starting 5 ... done
Creating and starting 9 ... done
```

Now we have 10 analyzers, at least until the queue hits zero, then
they will start to shutdown. You can check the status of your
containers with:

```
docker-compose ps
```

Results:

```
              Name                        Command           State            Ports
-------------------------------------------------------------------------------------------
build2016_analyzer_1               python src/analyzer.py   Up
build2016_analyzer_10              python src/analyzer.py   Up
build2016_analyzer_2               python src/analyzer.py   Exit 0
build2016_analyzer_3               python src/analyzer.py   Exit 0
build2016_analyzer_4               python src/analyzer.py   Exit 0
build2016_analyzer_5               python src/analyzer.py   Exit 0
build2016_analyzer_6               python src/analyzer.py   Exit 0
build2016_analyzer_7               python src/analyzer.py   Exit 0
build2016_analyzer_8               python src/analyzer.py   Exit 0
build2016_analyzer_9               python src/analyzer.py   Exit 0
build2016_frontoffice_qna_rest_1   catalina.sh run          Up       0.0.0.0:8080->8080/tcp
build2016_frontoffice_qna_web_1    apache2-foreground       Up       0.0.0.0:80->80/tcp
build2016_rest_enqueue_1           python src/server.py     Up       0.0.0.0:5000->5000/tcp
```

# Deploying to Azure Container Service

In order to deploy these applictions to Swarm on ACS all you need to
do is:

  * Create an ACS cluster using the Swarm Orchestrator
  * Open an SSH Tunnel to the Swarm endpoint
  * Set the value of the `DOCKER_HOST` environment variable

The commands to do this are (assuming Azure CLI is installed):

```
azure login -u rogardle@microsoft.com
azure config mode arm
azure group create acsswarmbuild2016 westus
azure group deployment create acsswarmbuild2016 acsswarmbuild2016 --template-uri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-acs-swarm/azuredeploy.json -e swarmcluster_parameters.json
```

Now we need to open a tunnel to the masters so that we can point our
CLI tools at the cluster. We'll also set the DOCKER_HOST environment
variable so that we don't need to explicitly tell the Docker CLI to
use our cluster on every command.

```
ssh -A -L 2375:localhost:2375 azureuser@acsswarmbuild2016mgmt.westus.cloudapp.azure.com -p 2200
export DOCKER_HOST=:2375
```

We can check that we are not working against our remote cluster with
the following command:

```
docker info
```

Results:

```
Containers: 3
 Running: 3
 Paused: 0
 Stopped: 0
Images: 3
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 3
 swarm-agent-F5E791DE-0: 10.0.0.4:2375
  └ Status: Healthy
  └ Containers: 1
  └ Reserved CPUs: 0 / 2
  └ Reserved Memory: 0 B / 3.528 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-49-generic, operatingsystem=Ubuntu 14.04.4 LTS, storagedriver=aufs
  └ Error: (none)
  └ UpdatedAt: 2016-03-24T05:22:03Z
 swarm-agent-F5E791DE-1: 10.0.0.5:2375
  └ Status: Healthy
  └ Containers: 1
  └ Reserved CPUs: 0 / 2
  └ Reserved Memory: 0 B / 3.528 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-49-generic, operatingsystem=Ubuntu 14.04.4 LTS, storagedriver=aufs
  └ Error: (none)
  └ UpdatedAt: 2016-03-24T05:22:11Z
 swarm-agent-F5E791DE-2: 10.0.0.6:2375
  └ Status: Healthy
  └ Containers: 1
  └ Reserved CPUs: 0 / 2
  └ Reserved Memory: 0 B / 3.528 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=3.19.0-49-generic, operatingsystem=Ubuntu 14.04.4 LTS, storagedriver=aufs
  └ Error: (none)
  └ UpdatedAt: 2016-03-24T05:22:10Z
Plugins:
 Volume:
 Network:
Kernel Version: 3.19.0-49-generic
Operating System: linux
Architecture: amd64
CPUs: 6
Total Memory: 10.58 GiB
Name: 014c3efb84d4
```

From this point forwards all of our Docker commands will be run
against the Swarm cluster. If you use `docker ps` you will be able to
see which agent node they are deployed to.

# Deploying to Production

Make your containers available in the Docker Hub (or a private Docker
Registry). First we want to tag the images, ready for our production
environment.

```
docker tag adtd/rest_qna adtd/rest_qna:build2016
docker tag adtd/web_qna adtd/web_qna:build2016
docker tag rgardler/acs-logging-test-analyze rgardler/acs-logging-test-analyze:build2016
docker tag rgardler/acs-logging-test-rest-enqueue rgardler/acs-logging-test-rest-enqueue:build2016
```

Once tagged we an push them to our Docker Registry:

```
docker push adtd/rest_qna:build2016
docker push adtd/web_qna:build2016
docker push rgardler/acs-logging-test-analyze:build2016
docker push rgardler/acs-logging-test-rest-enqueue:build2016[
```

# Autoscaling Containers

We don't really want to be scaling the application up manually like
this, we want it to happen automatically. So lets create a script to
handle this scaling. This script will query the length of the queue
and will start up a number of analyzer containers proportional to the
queue lentgh. When the queue hits zero the analyzers will start to
shut down.

Results:

```
#!/bin/bash

ANALYZERS=1
MAX_ANALYZERS=50

LENGTH=$(docker run -i --env-file env.conf rgardler/acs-logging-test-cli length)

docker run --env-file env.conf rgardler/acs-logging-test-cli summary

echo ""


NUM_ANALYZERS=$(expr $LENGTH / 10)
if [ "$NUM_ANALYZERS" -gt "$MAX_ANALYZERS" ]; then
    NUM_ANALYZERS=$MAX_ANALYZERS
fi
echo "Setting analyzer scale to $NUM_ANALYZERS"
docker-compose scale analyzer=$NUM_ANALYZERS > /dev/null


docker-compose ps
```

To see this in action we will want to generate traffic against our
application and then run the autoscale once there has been a chance
for the queue to grow.

```
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 100 -d "queue=rgbuildacsde\
mo&message=CORRECT%20-%20Question_1 - Answer_A" &
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 5 -d "queue=rgbuildacsdemo\
&message=INCORRECT%20-%20Question_1 - Answer_B" &
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 7 -d "queue=rgbuildacsdemo\
&message=INCORRECT%20-%20Question_1 - Answer_C" &
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 1 -d "queue=rgbuildacsdemo\
&message=INCORRECT%20-%20Question_1 - Answer_D" &
watch ./autoscale.sh
```

Results:

```
Every 2.0s: ./autoscale.sh                                                Tue Mar 22 00:59:33 2016

Queue Length: 4
              Name                        Command           State            Ports
-------------------------------------------------------------------------------------------
build2016_analyzer_1               python src/analyzer.py   Exit 0
build2016_analyzer_2               python src/analyzer.py   Exit 0
build2016_analyzer_3               python src/analyzer.py   Exit 0
build2016_frontoffice_qna_rest_1   catalina.sh run          Up       0.0.0.0:8080->8080/tcp
build2016_frontoffice_qna_web_1    apache2-foreground       Up       0.0.0.0:80->80/tcp
build2016_rest_enqueue_1           python src/server.py     Up       0.0.0.0:5000->5000/tcpStartin```

# Deploying to Production

So far we have been using the Docker native stack to host our Docker
containers. However, because of the protability of Docker images we
are not limited to using Docker Swarm, we can use any other
orchestrator that supports Docker images. In this demo we will use the
Apache Mesos version of Azure Container Service as our "production"
environment.

In order to deploy these applications using Mesos on ACS all you need
to do is:

  * Create an ACS cluster using the Mesos Orchestrator
  * Open an SSH Tunnel to the Mesos admin router
  * Use the Marathon REST API to deploy the application

The commands to do this are (assuming Azure CLI is installed):

```
azure login -u rogardle@microsoft.com
azure config mode arm
azure group create acsmesosbuild2016 westus
azure group deployment create acsmesosbuild2016 acsbuild2016 --template-uri https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-acs-mesos/azuredeploy.json -e mesoscluster_parameters.json
```

Now we need to open a tunnel to the admin router on the master
availability set so that we can point our CLI tools, web browser or
REST applicaiton at the cluster. 

```
sudo -E ssh -A -L 80:localhost:80 azureuser@acsmesosbuild2016mgmt.westus.cloudapp.azure.com -p 2200
```

Using this tunnel you can connect to the admin router at
http://localhost, this router will direct your requests to the
appropriate service in your ACS cluster.

# Deploying to a Mesos Cluster

To deploy to a Mesos cluster we need a marthon.json file. So here it
is:

```
FIXME: Insert working marathon.json file
```

Notice how we configure the environment for the containers, this
allows us to use a different queue and table in production to that in
test.

We can use this file to deploy the application using the Marathon REST
API:

```
curl -X PUT http://localhost/marathon/v2/groups -d @marathon.json -H "Content-type: application/json"
```

Note, the analyzer will start up but will stop immediately as there
are no items in the queue to process. However, Marathon will restart
the container regularly, so when we do have content in the queue it
will continue to run until empty.

You can configure how often the containers are restarted and what the
maximum delay is between restarting with the following settings in
your marathon.json file. The `backoffSeconds` and `backoffFactor` set
the amount of time between restarts (`backoffseconds` is multiplied by
`backoffSeconds` for each restart). `maxLaunchDelaySeconds` is the
maximum number of seconds to wait before attempting a restart.

`
	  "backoffSeconds": 1,
	  "backoffFactor": 1.15,
	  "maxLaunchDelaySeconds": 10
`

Let's add some content to the queue, just as we did earlier, but this
time we will point to our prodcution cluster.

FIXME: location of the rest endpoint should be production cluster

```
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 100 -d "queue=rgbuildacsdemo&message=CORRECT%20-%20Question_1 - Answer_A" &
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 5 -d "queue=rgbuildacsdemo&message=INCORRECT%20-%20Question_1 - Answer_B" &
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 7 -d "queue=rgbuildacsdemo&message=INCORRECT%20-%20Question_1 - Answer_C" &
docker run -d rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 1 -d "queue=rgbuildacsdemo&message=INCORRECT%20-%20Question_1 - Answer_D" &
```

Lets check that there are items in the queue:

```
docker run --env-file env.conf rgardler/acs-logging-test-cli summary
```

## Scaling on the Mesos Cluster

Our application can be scaled through the REST API or through the
Marathon UI. We'll do it through the UI. Visit the UI at
http://localhost/marathon (reember you need your SSH tunnel to the
admin master router for this to work).

Click through to the analyzer service "acs" -> "build2016" ->
"analyzer" and then click the "Scale Application" button. in the
dialog add the desire number of analyzers, e.g. 50 and click "Scale
Application".

You can see the status of the scaling action in the UI.

We should now see the queue shrinking much more quickly, we verify
this with our CLI tool:

```
docker run --env-file env.conf rgardler/acs-logging-test-cli summary
```

Once again, whn the queue reaches zero unprocessed messages the
analyzers will start to shut down. However, with the current setup
Marathon will continue to try to restart them. This is OK, since they
start and stop very quickly.

We could use a script like the autoscale script used earlier to
prevent unnecessary start/stop events.


