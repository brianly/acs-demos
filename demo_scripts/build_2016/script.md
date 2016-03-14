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
curl -X POST -d queue=rgacsbuilddemo -d message="INFO - Hello world!" http://localhost:5000/enqueue
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
docker-compose up
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
docker run rgardler/acs-load http://172.17.0.1:5000/enqueue -t 100 -l 100 -d "queue=rgbuildacsdemo&message=INFO%20-%20Hello%20Build."
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

# Autoscaling Containers

We don't really want to be scaling the application up manually like
this, we want it to happen automatically. So lets create a script to
handle this scaling. This script will query the length of the queue
and will start up a number of analyzer containers proportional to the
queue lentgh. When the queue hits zero the analyzers will start to
shut down.

Results:

```
ANALYZERS=1
MAX_ANALYZERS=75

LENGTH=$(docker run -i --env-file env.conf rgardler/acs-logging-test-cli length)

if [ "$LENGTH" -gt 100 ]; then
    NUM_ANALYZERS=$(expr $LENGTH / 100)
    if [ "$NUM_ANALYZERS" -gt "$MAX_ANALYZERS" ]; then
	NUM_ANALYZERS=$MAX_ANALYZERS
    fi
    docker-compose scale analyzer=$NUM_ANALYZERS
fi
```

To see this in action we will want to generate traffic against our
application and then run the autoscale once there has been a chance
for the queue to grow.

```
docker run rgardler/acs-load http://172.17.0.1:5000/enqueue -t 1000 -l 100 -d "queue=rgbuildacsdemo&message=INFO%20-%20Hello%20Build." &
sleep 10
./autoscale.sh
```

Results:

```
Starting build2016_analyzer_1 ... done
Starting build2016_analyzer_2 ... done
Starting build2016_analyzer_3 ... done
Starting build2016_analyzer_4 ... done
Starting build2016_analyzer_5 ... done
Starting build2016_analyzer_6 ... done
Starting build2016_analyzer_7 ... done
Starting build2016_analyzer_8 ... done
Starting build2016_analyzer_9 ... done
```



