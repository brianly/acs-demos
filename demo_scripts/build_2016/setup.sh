# Ensure Azure storage confgiuration is completed

function cleanDocker {
    echo
    echo "Stop and remove any containers related to this demo"
    docker-compose stop
    docker-compose rm -f
    docker rmi tutum/hello-world

    echo
    echo "Stop and remove any containers currently running"
    docker stop $(docker ps -q)

    echo
    echo "Pre-pull the images to ensure a fast startup in the demo"
    docker-compose pull
}

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
echo "Delete and recreate the queue and table to ensure they are empty"
docker run --env-file env.conf rgardler/acs-logging-test-cli:build2016 deleteQueue
docker run --env-file env.conf rgardler/acs-logging-test-cli:build2016 deleteTable
docker run --env-file env.conf rgardler/acs-logging-test-cli:build2016 createQueue
docker run --env-file env.conf rgardler/acs-logging-test-cli:build2016 createTable

cleanDocker

export DOCKER_HOST=:2375

echo
echo "Open SSH tunnel to swarm cluster"
ssh -A -L 2375:localhost:2375 -N azureuser@acsswarmbuild2016mgmt.westus.cloudapp.azure.com -p 2200 &

cleanDocker

export DOCKER_HOST=:2375

echo
echo "Sleep long enough to ensure the table and queue have been created (15 seconds)"
sleep 15

echo
echo "Open SSH tunnel to Mesos cluster"
sudo -E ssh -L 80:localhost:80 -N -A azureuser@acsmesosbuild2016mgmt.westus.cloudapp.azure.com -p 2200 &

echo
echo "Deploy the application on the Mesos cluster"
curl -X DELETE http://localhost/marathon/v2/groups/acs


