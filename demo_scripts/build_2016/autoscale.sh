#!/bin/bash

ANALYZERS=1
MAX_ANALYZERS=50

LENGTH=$(docker run -i --env-file env.conf rgardler/acs-logging-test-cli length)

docker run --env-file env.conf rgardler/acs-logging-test-cli summary

echo "Approximate queue length is " $LENGTH
echo ""


NUM_ANALYZERS=$(expr $LENGTH / 10)
if [ "$NUM_ANALYZERS" -gt "$MAX_ANALYZERS" ]; then
    NUM_ANALYZERS=$MAX_ANALYZERS
fi
echo "Setting analyzer scale to $NUM_ANALYZERS"
docker-compose scale analyzer=$NUM_ANALYZERS > /dev/null


docker-compose ps
