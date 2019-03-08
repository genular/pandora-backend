# vim:set ft=dockerfile:
# escape=\

FROM "genular/parent:master"

MAINTAINER LogIN- "info@genular.com"

# Set a working directory
WORKDIR /tmp

## Run only if Internet is Enabled!
# RUN apt-get update && apt-get upgrade

ADD ./configuration.json /tmp/configuration.json

## Lets build and configure SIMON
RUN su - genular -c 'cd /var/www/genular/simon-frontend \
	&& git pull origin master \
	&& yarn run webpack:web:dev \
	--isDemoServer=false \
	--server_frontend=http://localhost:3010 \
	--server_backend=http://localhost:3011 \
	--server_homepage=http://localhost:3010 \
	&& cd /var/www/genular/simon-backend/server/backend/ \
	&& git pull origin master \
	&& composer post-install /tmp/configuration.json'

COPY ["./supervisord.conf", "/etc/supervisor/conf.d/supervisord.conf"]

#
# Expose the ports!
#
EXPOSE 3010
EXPOSE 3011
EXPOSE 3012
EXPOSE 3013

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# voila!