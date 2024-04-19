#!/bin/bash

echo "===> MAINTENANCE $(date) - Docker Check: $IS_DOCKER"

LOG_FILE="/var/log/pandora-cron.log"
MAX_SIZE=$((100 * 1024 * 1024))  # 100 MB in bytes

# Check if log file exists and truncate if necessary
if [ -f "$LOG_FILE" ]; then
    log_size=$(wc -c < "$LOG_FILE")  # Get the current file size in bytes

    if [ "$log_size" -gt "$MAX_SIZE" ]; then
        cp /dev/null "$LOG_FILE" 2>/dev/null
        echo "===> MAINTENANCE $(date) - Truncating $LOG_FILE because it exceeded $MAX_SIZE bytes"
    fi
fi

# Set default directories and check existence, set to alternate if they don't exist
APP_DIR_BACKEND="/var/www/genular/pandora-backend"
if [ ! -d "$APP_DIR_BACKEND" ]; then
    APP_DIR_BACKEND="/mnt/genular/pandora-backend"
    echo "===> MAINTENANCE $(date) - Default backend directory not found. Using $APP_DIR_BACKEND instead."
fi

APP_DIR_FRONTEND="/var/www/genular/pandora"
if [ ! -d "$APP_DIR_FRONTEND" ]; then
    APP_DIR_FRONTEND="/mnt/genular/pandora"
    echo "===> MAINTENANCE $(date) - Default frontend directory not found. Using $APP_DIR_FRONTEND instead."
fi

# Remove hs_err files from backend directory if it exists
if [ -d "$APP_DIR_BACKEND" ]; then
    find "$APP_DIR_BACKEND" -maxdepth 1 -name 'hs_err_pid*.log' -exec rm {} \;
    echo "===> MAINTENANCE $(date) - Removed Java error logs from backend directory"
fi

# Update git repositories if update.txt exists
UPDATE_FILE="$APP_DIR_BACKEND/server/backend/public/assets/update.txt"
if [ -f "$UPDATE_FILE" ]; then
    echo "===> MAINTENANCE $(date) - Update required, updating git repositories..."

    source $UPDATE_FILE

    if [ "$IS_DOCKER" = "true" ]; then
        echo "===> MAINTENANCE $(date) - Update Docker image START"
        # Update Frontend repository
        if cd "$APP_DIR_FRONTEND"; then
            echo "===> MAINTENANCE $(date) - Update frontend start"
            current_branch=$(git rev-parse --abbrev-ref HEAD)
            sudo -u genular git checkout . && sudo -u genular git fetch && sudo -u genular git checkout "$current_branch" && sudo -u genular git pull origin "$current_branch" && \
            sudo -u genular yarn install --check-files && \
            sudo -u genular yarn run webpack:web:prod --isDemoServer=false --server_frontend=$FRONTEND_URL --server_backend=$BACKEND_URL --server_homepage=$FRONTEND_URL

            echo "===> MAINTENANCE $(date) - Updated Frontend repository successfully."
        else
            echo "===> MAINTENANCE $(date) - Failed to change directory to $APP_DIR_FRONTEND"
        fi

        # Update Backend repository
        if cd "$APP_DIR_BACKEND/server/backend"; then
            echo "===> MAINTENANCE $(date) - Update backend start"
            current_branch=$(git rev-parse --abbrev-ref HEAD)
            sudo -u genular git checkout . && sudo -u genular git fetch && sudo -u genular git checkout "$current_branch" && sudo -u genular git pull origin "$current_branch" && \
            sudo -u genular /usr/bin/php8.2 /usr/local/bin/composer install --ignore-platform-reqs && \
            sudo -u genular /usr/bin/php8.2 /usr/local/bin/composer post-install /tmp/configuration.json
            echo "===> MAINTENANCE $(date) - Updated Backend repository successfully."
        else
            echo "===> MAINTENANCE $(date) - Failed to change directory to $APP_DIR_BACKEND/server/backend"
        fi

        ## Restart pm2 processes
        pm2 restart all
    fi
    
    # Delete the update.txt file after updates
    rm -f "$UPDATE_FILE"
    echo "===> MAINTENANCE $(date) - Deleted the update.txt file"
fi
