# Pandora Docker Images Documentation

This README provides instructions for building, publishing, and running Docker images for the PANDORA project.

## Base Image Creation

The `./base_image` directory contains scripts necessary to create the parent Docker image.

### Usage

To build the base image, execute the following command:

```bash
LANG=en_US.UTF-8 sudo ./make_image.sh
```

This command pre-installs basic Genular dependencies from a Debian distribution and compiles a custom image, which is then used in Dockerfiles.

## Publishing the PANDORA Base Image

After the build is completed with `./make_image.sh`, the image will be compressed inside the `./base_image/images` directory.

### Importing the Local TAR Image

First, replace `FILE_NAME` with the actual filename:

```bash
sudo cat ./FILE_NAME.tar | sudo docker import - genular/base_image:master
```

Verify the image is properly imported:

```bash
# List all Docker images
docker image ls -a
```

#### Logging into the Docker Repository

If not already logged in:

```bash
cat ~/my_password.txt | docker login --username foo --password-stdin
```

### Pushing Your Image to an Online Repository

To push the image:

```bash
docker push genular/base_image:master
```

#### Alternatively, Upload to a CDN

For uploading to a CDN:

```bash
rclone copy ./genular.tar genular-spaces:genular/docker-parent-images
```

## Publishing Child Genular PANDORA Image

Auto-build is configured on [Docker Hub](https://hub.docker.com/?namespace=genular). A new `genular/pandora:latest` container will be built automatically upon detecting changes in the pandora-backend github repository.

To build manually:

### Adjusting Configuration Variables

Generate a configuration JSON template:

```bash
cd pandora-backend/server/backend && composer generate-docker-config
```

This creates a new file: `documentation/docker_images/configuration.json`. Modify this file as needed and save it as `./configuration.example.json`.

### Building the Docker Image

Build the image (remove `--network=host` if unnecessary):

```bash
docker build --no-cache --network=host --tag "genular/pandora:latest" --file ./Dockerfile .
```

Run the image to verify it works:

```bash
docker run --rm --detach --name genular --tty --interactive --env IS_DOCKER='true' --env TZ=Europe/London --oom-kill-disable --volume genular_frontend_latest:/var/www/genular/pandora --volume genular_backend_latest:/var/www/genular/pandora-backend --volume genular_data_latest:/mnt/usrdata --publish 3010:3010 --publish 3011:3011 --publish 3012:3012 --publish 3013:3013 genular/pandora:latest
```

#### Publishing the New Image

Push the new image to Docker Hub:

```bash
docker push genular/pandora:latest
```

## Running the PANDORA Container

Prepare the environment and pull the [genular/pandora](https://cloud.docker.com/u/genular/repository/docker/genular/pandora) image from Docker Hub. Run a container with mounted volumes and port mapping:

```bash
# Note for Windows users: replace "\" with "`" for newline separators
docker run --rm --network=host \
    --detach \
    --name genular \
    --tty \
    --interactive \
    --env IS_DOCKER='true' \
    --env TZ=America/Los_Angeles \
    --env SERVER_FRONTEND_URL="http://localhost:3010" \
    --env SERVER_BACKEND_URL="http://localhost:3011" \
    --env SERVER_HOMEPAGE_URL="http://localhost:3010" \
    --env SERVER_ANALYSIS_URL="http://localhost:3012" \
    --env SERVER_PLOTS_URL="http://localhost:3013" \
    --volume genular_data:/mnt/usrdata \
    --publish 3010:3010 \
    --publish 3011:3011 \
    --publish 3012:3012 \
    --publish 3013:3013 \
    genular/pandora:latest
```

After starting the container, access PANDORA at `http://localhost:3010` to create your account.

## Helper Commands

- SSH into a running container:
  `docker exec -it genular /bin/bash`
- List all running containers:
  `docker ps`
- Stop a container:
  `docker stop genular`
- Delete a specific image:
  `docker rmi IMAGE_ID`
- Prune all images:
  `docker system prune -a`
- Delete a Docker volume:
  `docker volume rm genular_data`


# chroot
```bash
# Navigate to your debootstrap directory
cd ./documentation/docker_images/base_image/images/genular

sudo mount --bind /dev dev/
sudo mount --bind /dev/pts dev/pts/
sudo mount -t proc /proc proc/
sudo mount -t sysfs /sys sys/
sudo mount -t tmpfs tmpfs tmp/

sudo chroot .

## TO EXIT
exit

cd ..

# Unmount the filesystems
sudo umount -l ./genular/tmp/
sudo umount -l ./genular/sys/
sudo umount -l ./genular/proc/
sudo umount -l ./genular/dev/pts/
sudo umount -l ./genular/dev/

```
