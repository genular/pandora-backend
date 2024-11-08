# vim:set ft=dockerfile:
# escape=\

FROM "genular/base_image:master"

MAINTAINER LogIN- "atomic.research.lab@gmail.com"

# Set a working directory
WORKDIR /tmp

# If you have custom configuration variables you can pass it like this:
# just add "composer post-install /tmp/configuration.json" as a last in RUN command
COPY ./configuration.example.json /tmp/configuration.json

## This script will check for any custom mount-points and its managed by supervisor
## It will also start mysql and pm2 supervisor tasks
COPY ./prepare_docker_storage.sh /tmp/prepare_docker_storage.sh
RUN chmod +x /tmp/prepare_docker_storage.sh

# Define build arguments
ARG SERVER_FRONTEND_URL="http://localhost:3010"
ARG SERVER_BACKEND_URL="http://localhost:3011"
ARG SERVER_HOMEPAGE_URL="http://localhost:3010"
ARG SERVER_ANALYSIS_URL="http://localhost:3012"
ARG SERVER_PLOTS_URL="http://localhost:3013"

# Transfer ARGs to ENV for persistence throughout the build and runtime phases
ENV SERVER_FRONTEND_URL=${SERVER_FRONTEND_URL} \
    SERVER_BACKEND_URL=${SERVER_BACKEND_URL} \
    SERVER_HOMEPAGE_URL=${SERVER_HOMEPAGE_URL} \
    SERVER_ANALYSIS_URL=${SERVER_ANALYSIS_URL} \
    SERVER_PLOTS_URL=${SERVER_PLOTS_URL}

    
## Lets build and configure PANDORA
RUN sudo -E -u genular bash -c 'cd /var/www/genular/pandora \
    && git checkout . && git fetch && git checkout master && git pull origin master \
    && yarn install --check-files --ignore-engines \
    && yarn run webpack:web:prod \
	    --isDemoServer=false \
	    --SERVER_FRONTEND_URL=$SERVER_FRONTEND_URL \
	    --SERVER_BACKEND_URL=$SERVER_BACKEND_URL \
	    --SERVER_HOMEPAGE_URL=$SERVER_HOMEPAGE_URL \
    && cd /var/www/genular/pandora-backend/server/backend/ \
    && git checkout . && git fetch && git checkout master && git pull origin master \
    && /usr/bin/php8.2 /usr/local/bin/composer install --ignore-platform-reqs \
    && /usr/bin/php8.2 /usr/local/bin/composer post-install /tmp/configuration.json'

COPY ["./supervisord.conf", "/etc/supervisor/conf.d/supervisord.conf"] 

# Expose the necessary ports
EXPOSE 3010
EXPOSE 3011
EXPOSE 3012
EXPOSE 3013

# Run supervisord
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
