#!/bin/bash

# Check if environment variables are set and run yarn if they are
if [ -n "$SERVER_FRONTEND_URL" ] && [ -n "$SERVER_BACKEND_URL" ] && [ -n "$SERVER_HOMEPAGE_URL" ]; then
    echo "Running yarn with specified environment variables..."
    cd /var/www/genular/pandora
    yarn run webpack:web:prod \
        --isDemoServer=false \
        --server_frontend="$SERVER_FRONTEND_URL" \
        --server_backend="$SERVER_BACKEND_URL" \
        --server_homepage="$SERVER_HOMEPAGE_URL"
else
    echo "Environment variables for yarn not specified. Skipping yarn run."
fi

# Check if configuration file exists for composer post-install
if [ -f /tmp/configuration.json ]; then
    echo "Running composer post-install with configuration.json..."
    cd /var/www/genular/pandora-backend/server/backend/
    /usr/bin/php8.2 /usr/local/bin/composer post-install /tmp/configuration.json
else
    echo "/tmp/configuration.json not found. Skipping composer post-install."
fi

# Start Supervisor
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
