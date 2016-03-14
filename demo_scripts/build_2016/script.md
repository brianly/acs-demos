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










