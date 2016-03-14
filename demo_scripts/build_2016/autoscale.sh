#!/bin/bash

ANALYZERS=1
MAX_ANALYZERS=75

LENGTH=$(docker run -i --env-file env.conf rgardler/acs-logging-test-cli length)

if [ "$LENGTH" -gt 50 ]; then
    NUM_ANALYZERS=$(expr $LENGTH / 100)
    if [ "$NUM_ANALYZERS" -gt "$MAX_ANALYZERS" ]; then
	NUM_ANALYZERS=$MAX_ANALYZERS
    fi
    docker-compose scale analyzer=$NUM_ANALYZERS
fi
