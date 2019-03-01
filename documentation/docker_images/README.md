This directory contains scripts necessary to create parent docker image.

Usage:
sudo ./make_image.sh

Script pre-installs basic genular dependencies and compiles custom debian image out of it,
that is than used in Dockerfile.


## 1. Import parent image
1st import docker image - https://docs.docker.com/engine/reference/commandline/import/#import-from-a-remote-location

### Import from remote location
docker import https://genular.ams3.cdn.digitaloceanspaces.com/docker-parent-images/genular.tar

### Import local tar image
	* sudo tar cpf - . | sudo docker import - genular
	* sudo cat ./genular.tar | sudo docker import - genular

### Import from directory
sudo tar -c . | docker import --change "ENV DEBUG true" - ./base_image/images/genular

#### Check if image is properly imported
sudo docker image ls -a

#### Check if networking and DNS inside docker is working properly
sudo docker run -t -i --rm --network host genular /bin/bash

sudo docker run --dns 8.8.8.8 busybox ping -c 10 genular.org
sudo docker run --dns 8.8.8.8 busybox nslookup google.com

##### To delete specific image
	- sudo docker rmi IMAGE_ID
##### Prune all images:
	- sudo docker system prune -a

## 2. Build Dockerfile
	<!-- 
		--network host -->
	- sudo docker build --tag "genular:build" --file ./Dockerfile .

## 3. Run Dockerfile
docker run --rm \
	--add-host=genular.local:127.0.0.1 \
	--add-host=analysis.api.genular.local:127.0.0.1 \
	--add-host=plots.api.genular.local:127.0.0.1 \
	--add-host=backend.api.genular.local:127.0.0.1 \
	--add-host=dashboard.genular.local :127.0.0.1 \
	--detach \
	--name genular \
	--tty --interactive \
	--publish 3005:80 \
	--publish 3010:22 genular:build


## SSH into a running container:

### List all running ones
	- sudo docker ps

sudo docker exec -it genular /bin/bash
sudo docker stop genular