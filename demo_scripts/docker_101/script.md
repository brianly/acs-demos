# Demo
# Run the hello-world container

```
docker run hello-world
```

Notice how the container was downloaded then run in just a few seconds.

# Run a hello-world web application

```
docker run -d -p 80:80 tutum/hello-world
curl localhost
```

# Run 20 web servers using docker-compose

```
less docker-compose.yml
docker-compose up -d
docker-compose scale web=20
docker ps
```