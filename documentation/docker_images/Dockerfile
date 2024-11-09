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

COPY ["./supervisord.conf", "/etc/supervisor/conf.d/supervisord.conf"] 

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set default environment variables for URLs
ENV SERVER_FRONTEND_URL="http://localhost:3010" SERVER_HOMEPAGE_URL="http://localhost:3010" \
    SERVER_BACKEND_URL="http://localhost:3011" SERVER_ANALYSIS_URL="http://localhost:3012" \
    SERVER_PLOTS_URL="http://localhost:3013"

USER genular

# Build and configure PANDORA
RUN cd /var/www/genular/pandora \
    && git checkout . && git fetch && git checkout master && git pull origin master \
    && yarn install --check-files --ignore-engines \
    && yarn run webpack:web:prod \
	    --isDemoServer=false \
	    --server_frontend=${SERVER_FRONTEND_URL} \
	    --server_backend=${SERVER_BACKEND_URL} \
	    --server_homepage=${SERVER_HOMEPAGE_URL} \
    && cd /var/www/genular/pandora-backend/server/backend/ \
    && git checkout . && git fetch && git checkout master && git pull origin master \
    && /usr/bin/php8.2 /usr/local/bin/composer install --ignore-platform-reqs \
    && /usr/bin/php8.2 /usr/local/bin/composer post-install /tmp/configuration.json

# Switch back to root for remaining tasks
USER root

ENTRYPOINT ["/entrypoint.sh"]
