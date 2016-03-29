#!/bin/bash

# Demonstrate the scaling up and down of analysers in response to the
# length of the queue.

PRODUCERS=1
MAX_PRODUCERS=20
ANALYZERS=1
MAX_ANALYZERS=50

STATUS_REPEATS=3
STATUS_DELAY=3

CONTAINER_SCALE_REPEATS=5
CONTAINER_SCALE_DELAY=3

clear
echo "Starting $PRODUCERS producer and $ANALYZERS analyzer"
echo "======================================================================================="
echo ""
docker-compose scale producer=$PRODUCERS
docker-compose scale analyzer=$ANALYZERS
docker-compose up -d 
docker-compose ps

echo ""
read -p "Press [Enter] key to see the effect on the queue"
clear

echo "Output the status of the queue every $STATUS_DELAY seconds"
echo "======================================================================================="
for i in $(seq "$STATUS_REPEATS")
do
    echo "Queue Status"
    echo "============"
    docker run -it --env-file env.conf rgardler/acs-logging-test-cli summary
    echo "Container Status"
    echo "================"
    docker-compose ps
    echo "======================================================================================="
    echo ""
    sleep $STATUS_DELAY
    clear
done

echo "Notice how the queue is growing, we don't have enough analyzers to keep up with the work"
echo "Lets implement a scaling algorithm, this is a simpl shell script we will run periodically"
echo ""
echo << EOF
    NUM_ANALYZERS=$(expr $LENGTH / 10)
    if [ "$NUM_ANALYZERS" -gt "$MAX_ANALYZERS" ]
    then
	NUM_ANALYZERS=$MAX_ANALYZERS
    fi
    docker-compose scale analyzer=$NUM_ANALYZERS
EOF
echo ""
read -p "Press [Enter] key to turn on an auto-scaling algorithm"
clear 

for i in $(seq "$CONTAINER_SCALE_REPEATS")
do
    echo "Queue Status"
    echo "============"

    LENGTH=$(docker run -i --env-file env.conf rgardler/acs-logging-test-cli length)
    echo "Queue is approximately $LENGTH message in length"
    echo ""

    NUM_ANALYZERS=$(expr $LENGTH / 10)
    if [ "$NUM_ANALYZERS" -gt "$MAX_ANALYZERS" ]
    then
	NUM_ANALYZERS=$MAX_ANALYZERS
    fi
    echo "docker-compose scale analyzer=$NUM_ANALYZERS"
    docker-compose scale analyzer=$NUM_ANALYZERS
    echo ""
    echo "Container Status"
    echo "================"
    docker-compose ps
    echo "======================================================================================="
    echo ""
    sleep $CONTAINER_SCALE_DELAY
    clear
done

echo "That's all for our demo just now..."
read -p "Press [Enter] key to shut things down"
clear 

docker-compose stop
