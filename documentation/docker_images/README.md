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

## 2. Build docker image from Dockerfile

### 2.1 Set configuration variables in Dockerfile
You can get example of configuration JSON by executing following command
	- cd simon-backend/server/backend && composer generate-docker-config
This will create a new file: documentation/docker_images/configuration.json where you can add/remove custom configuration variables

### 2.2 Build docker image
	- sudo docker build --network=host --tag "genular:master" --file ./Dockerfile .

## 3. Run Dockerfile
sudo docker run --rm \
	--detach \
	--network=host \
	--name genular \
	--tty \
	--interactive \
	--env IS_DOCKER \
	--publish 3010:3010 \
	--publish 3011:3011 \
	--publish 3012:3012 \
	--publish 3013:3013 \
	genular:master


## SSH into a running container:

### List all running ones
	- sudo docker ps

sudo docker exec -it genular /bin/bash
sudo docker stop genular