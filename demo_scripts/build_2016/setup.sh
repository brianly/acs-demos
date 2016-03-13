# Stop and remove any containers related to this demo
docker-compose stop
docker-compose rm -f

# Delete and recrete the queue and table to ensure they are empty
docker run --env-file env.conf rgardler/acs-logging-test-cli deleteQueue
docker run --env-file env.conf rgardler/acs-logging-test-cli deleteTable
docker run --env-file env.conf rgardler/acs-logging-test-cli createQueue
docker run --env-file env.conf rgardler/acs-logging-test-cli createTable
