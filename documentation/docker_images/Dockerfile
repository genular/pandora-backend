# vim:set ft=dockerfile:
# escape=\

FROM "genular/parent:master"
# FROM "genular"

MAINTAINER LogIN- "info@genular.com"

# Set a working directory
WORKDIR /tmp

## Run only if Internet is Enabled!
# RUN apt-get update && apt-get upgrade

# If you have custom configuration variables you can pass it like this:
# just add "composer post-install /tmp/configuration.json" as a last in RUN command
ADD ./configuration.example.json /tmp/configuration.json

## This script will check for any custom mount-points and its managed by supervisor
ADD ./prepare_docker_storage.sh /tmp/prepare_docker_storage.sh

## Lets build and configure SIMON
RUN su - genular -c 'chmod 777 /tmp/prepare_docker_storage.sh \
	&& cd /var/www/genular/simon-frontend \
	&& git checkout . && git pull origin master \
	&& yarn install --check-files \
	&& yarn run webpack:web:dev \
	--isDemoServer=false \
	--server_frontend=http://localhost:3010 \
	--server_backend=http://localhost:3011 \
	--server_homepage=http://localhost:3010 \
	&& cd /var/www/genular/simon-backend/server/backend/ \
	&& git checkout . && git pull origin master \
	&& composer install \
	&& composer post-install /tmp/configuration.json'

COPY ["./supervisord.conf", "/etc/supervisor/conf.d/supervisord.conf"] 

#
# Expose the ports!
#
# EXPOSE 3010
EXPOSE 3011
EXPOSE 3012
EXPOSE 3013

## MySQL for Testing 
#EXPOSE 3306

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# voila!