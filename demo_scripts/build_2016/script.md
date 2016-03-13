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
Creating acsloggingtest_rest_enqueue_1
Creating acsloggingtest_analyzer_1
```

Here we started two containers, a rest API for writing messages to the
queue and an analyzer which will process messages in that queue. The
Analyzer will examine the queue to see if there is any work for it to
do, if it finds none it will shutdown. Since there is nothing in the
queue (assuming you started with a new queue) the anlyzer will startup
but immediately shut down.

Lets have a look at the queue and summary table:

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

The "rest_enqueue" container provides a REST API for writing events to
the queue, so lets write one.

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

Since the queue was empty before the analyzer will have shut
down. This means that the message we just placed in the queue will
still be there. Lets check:

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

Looks good. Lets restart the analyser:

```
docker-compose up
```

Results:

```
build2016_rest_enqueue_1 is up-to-date
Starting build2016_analyzer_1
```

Notice that the REST API is up-to-date so nothing is done, but since
the analyzer was not running it is re-started. It will process all the
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










