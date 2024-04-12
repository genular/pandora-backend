#!/bin/bash

LOG_FILE="/var/log/pandora-cron.log"
MAX_SIZE=$((100 * 1024 * 1024))  # 100 MB in bytes

# Check if log file exists and truncate if necessary
if [ -f "$LOG_FILE" ]; then
    log_size=$(wc -c < "$LOG_FILE")  # Get the current file size in bytes

    if [ "$log_size" -gt "$MAX_SIZE" ]; then
        echo "Truncating $LOG_FILE"
        cp /dev/null "$LOG_FILE"
    fi
fi

APP_DIR_BACKEND="/var/www/genular/pandora-backend"
APP_DIR_FRONTEND="/var/www/genular/pandora"

# Remove hs_err files from backend directory if it exists
if [ -d "$APP_DIR_BACKEND" ]; then
    rm "$APP_DIR_BACKEND"/hs_err_pid*.log
fi

# Update git repositories if update.txt exists
UPDATE_FILE="$APP_DIR_BACKEND/server/backend/public/assets/update.txt"
if [ -f "$UPDATE_FILE" ]; then
    echo "Update required, updating git repositories..."

    # Update Frontend repository
    cd "$APP_DIR_FRONTEND" \
        && git checkout . && git fetch && git checkout master && git pull origin master \
        && yarn install --check-files \
        && yarn run webpack:web:prod \
        --isDemoServer=false \
        --server_frontend=http://localhost:3010 \
        --server_backend=http://localhost:3011 \
        --server_homepage=http://localhost:3010

    # Update Backend repository
    cd "$APP_DIR_BACKEND/server/backend" \
        && git checkout . && git fetch && git checkout master && git pull origin master \
        && /usr/bin/php8.2 /usr/local/bin/composer install --ignore-platform-reqs \
        && /usr/bin/php8.2 /usr/local/bin/composer post-install /tmp/configuration.json
    
    # Delete the update.txt file after updates
    rm "$UPDATE_FILE"
fi
