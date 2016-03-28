# Ensure Azure storage confgiuration is completed
if [ ! -f env.conf ]
then
    cp env.conf.tmpl env.conf
    echo "=========================== NOTICE ==============================="
    echo "You will need to set the Azure storage account details in env.conf"
    echo "Once configured rerun setup.sh"
    echo "=================================================================="
    exit 1
fi

echo
echo "Stop and remove any containers related to this demo"
docker-compose stop
docker-compose rm -f

echo
echo "Pre-pull the images to ensure a fast startup in the demo"
docker-compose pull

echo
echo "Delete and recreate the queue and table to ensure they are empty"
docker run --env-file env.conf rgardler/acs-logging-test-cli:build2016 deleteQueue
docker run --env-file env.conf rgardler/acs-logging-test-cli:build2016 deleteTable
docker run --env-file env.conf rgardler/acs-logging-test-cli:build2016 createQueue
docker run --env-file env.conf rgardler/acs-logging-test-cli:build2016 createTable

echo
echo "Sleep long enough to ensure the table and queue have been created (15 seconds)"
sleep 15

echo
echo "Deploy the application on the Mesos cluster"
curl -X PUT http://localhost/marathon/v2/groups -d @marathon.json -H "Content-type: application/json"


