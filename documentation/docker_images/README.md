## Explanation
Directory `./base_image` contains scripts necessary to create parent docker image.
Usage:
```bash
sudo ./make_image.sh
```
Command pre-installs basic genular dependencies from a Debian distribution and compile custom image out of it, that is than used latter on in Dockerfile.

## Steps needed to publish parent genular image
After build is finished using `./make_image.sh` image will be compressed inside `./base_image/images` directory.

### 1. Import local tar image
Command:
Replace FILE_NAME with actual filename.
```bash
sudo cat ./FILE_NAME.tar | sudo docker import - genular/parent:master
```

Check if image is properly imported
```bash
sudo docker image ls -a
```

### 1.1 Login to repository if not already logged-in
```bash
cat ~/my_password.txt | docker login --username foo --password-stdin
```
### 2. Push your image to repository
```bash
sudo docker push genular/parent:master
```
### 2.1 or upload to CDN
```bash
rclone copy ./genular.tar genular-spaces:genular/docker-parent-images
```

## Steps needed to publish child genular SIMON image
Auto-build is configure on [Docker Hub](https://hub.docker.com/?namespace=genular). Whenever new change is detected in repository container  `genular/simon:latest` will be build-ed *automatically*.

To do it *manually* first build docker image from Dockerfile:

### 1. Check/Adjust configuration variables in Dockerfile 
You can get example of configuration JSON by executing following command
`cd simon-backend/server/backend && composer generate-docker-config`
This will create a new file: `documentation/docker_images/configuration.json` where you can add/remove custom configuration variables and place it in `./configuration.example.json`

### 2. Build docker image
Remove `--network=host` if needed.
`sudo docker build --network=host --tag "genular/simon:latest" --file ./Dockerfile .`

## 3. Running SIMON Container
In order to run a test instance of `SIMON` we first need to prepare the environment.
If you finished installing docker please continue.

Lets pull the [genular/simon](https://cloud.docker.com/u/genular/repository/docker/genular/simon) image from [Docker Hub](https://hub.docker.com/?namespace=genular). 
Then we will run a docker container with appropriately mounted volumes and port mapping. By default the container would run with a local file-system inside of it.

After you installed docker and its running, please open your favorite Terminal and run the command below.
If on Windows - open `Windows Power Shell`

> If you wish to get correct time, replace TZ=<timzone> with your timezone. You can find list of supported timezones [here](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
```bash
# Important: if you are using Windows replace newline separators in the command: "\" with "`"
docker run --rm \
    --detach \
    --name genular \
    --tty \
    --interactive \
    --env IS_DOCKER='true' \
    --env TZ=America/Los_Angeles \
    --volume /mnt/genular/simon-backend/SHARED_DATA:/mnt/usrdata \
    --publish 3010:3010 \
    --publish 3011:3011 \
    --publish 3012:3012 \
    --publish 3013:3013 \
    genular/simon:latest
```
Once command is executed and the container is started you can open SIMON on `http://localhost:3010` and create your account.
- If you get asked please allow connections through your Windows Firewall.

To publish it on [Docker Hub](https://hub.docker.com/?namespace=genular) use same steps as above.

## Helpers
* SSH into a running container
    `sudo docker exec -it genular /bin/bash`
* List all running ones
    `sudo docker ps`
* Stop image
    `sudo docker stop genular`
* To delete specific image
    `sudo docker rmi IMAGE_ID`
* Prune all images:
    `sudo docker system prune -a`