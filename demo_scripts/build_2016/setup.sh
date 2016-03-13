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

# Stop and remove any containers related to this demo
docker-compose stop
docker-compose rm -f

# Delete and recrete the queue and table to ensure they are empty
docker run --env-file env.conf rgardler/acs-logging-test-cli deleteQueue
docker run --env-file env.conf rgardler/acs-logging-test-cli deleteTable
docker run --env-file env.conf rgardler/acs-logging-test-cli createQueue
docker run --env-file env.conf rgardler/acs-logging-test-cli createTable

