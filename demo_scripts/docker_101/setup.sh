docker stop $( docker ps -q )
docker rm $( docker ps -qa )
docker rmi -f tutum/hello-world
docker rmi -f tutum/hello-world
clear


