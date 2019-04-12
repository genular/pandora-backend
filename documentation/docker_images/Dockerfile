# vim:set ft=dockerfile:
# escape=\

FROM "genular/parent:master"

MAINTAINER LogIN- "info@genular.com"

# Set a working directory
WORKDIR /tmp

# If you have custom configuration variables you can pass it like this:
# just add "composer post-install /tmp/configuration.json" as a last in RUN command
COPY ./configuration.example.json /tmp/configuration.json

## This script will check for any custom mount-points and its managed by supervisor
## It will also start mysql and pm2 supervisor tasks
COPY ./prepare_docker_storage.sh /tmp/prepare_docker_storage.sh
RUN chmod +x /tmp/prepare_docker_storage.sh

## Lets build and configure SIMON
RUN su - genular -c 'cd /var/www/genular/simon-frontend \
	&& git checkout . && git pull origin master \
	&& yarn install --check-files \
	&& yarn run webpack:web:prod \
	--isDemoServer=false \
	--server_frontend=http://localhost:3010 \
	--server_backend=http://localhost:3011 \
	--server_homepage=http://localhost:3010 \
	&& cd /var/www/genular/simon-backend/server/backend/ \
	&& git checkout . && git pull origin master \
	&& composer install \
	&& composer post-install /tmp/configuration.json'

COPY ["./supervisord.conf", "/etc/supervisor/conf.d/supervisord.conf"] 

# Expose the ports!
## frontend
EXPOSE 3010
## backend
EXPOSE 3011
EXPOSE 3012
EXPOSE 3013

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# voila!