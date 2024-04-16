#!/bin/bash

LOG_FILE="/var/log/pandora-cron.log"
MAX_SIZE=$((100 * 1024 * 1024))  # 100 MB in bytes

# Check if log file exists and truncate if necessary
if [ -f "$LOG_FILE" ]; then
    log_size=$(wc -c < "$LOG_FILE")  # Get the current file size in bytes

    if [ "$log_size" -gt "$MAX_SIZE" ]; then
        cp /dev/null "$LOG_FILE"
        echo "===> MAINTENANCE $(date) - Truncating $LOG_FILE because it exceeded $MAX_SIZE bytes" >> "$LOG_FILE"
    fi
fi

APP_DIR_BACKEND="/var/www/genular/pandora-backend"
APP_DIR_FRONTEND="/var/www/genular/pandora"

# Remove hs_err files from backend directory if it exists
if [ -d "$APP_DIR_BACKEND" ]; then
    find "$APP_DIR_BACKEND" -name 'hs_err_pid*.log' -exec rm {} \;
    echo "===> MAINTENANCE $(date) - Removed Java error logs from backend directory" >> "$LOG_FILE"
fi


# Update git repositories if update.txt exists
UPDATE_FILE="$APP_DIR_BACKEND/server/backend/public/assets/update.txt"
if [ -f "$UPDATE_FILE" ]; then
    echo "===> MAINTENANCE $(date) - Update required, updating git repositories..." >> "$LOG_FILE"

    source $UPDATE_FILE

    # Update Frontend repository
    if cd "$APP_DIR_FRONTEND"; then
        git checkout . && git fetch && git checkout master && git pull origin master && \
        yarn install --check-files && \
        yarn run webpack:web:prod --isDemoServer=false --server_frontend=$FRONTEND_URL --server_backend=$BACKEND_URL --server_homepage=$FRONTEND_URL
        echo "===> MAINTENANCE $(date) - Updated Frontend repository successfully." >> "$LOG_FILE"
    else
        echo "===> MAINTENANCE $(date) - Failed to change directory to $APP_DIR_FRONTEND" >> "$LOG_FILE"
    fi

    # Update Backend repository
    if cd "$APP_DIR_BACKEND/server/backend"; then
        git checkout . && git fetch && git checkout master && git pull origin master && \
        /usr/bin/php8.2 /usr/local/bin/composer install --ignore-platform-reqs && \
        /usr/bin/php8.2 /usr/local/bin/composer post-install /tmp/configuration.json
        echo "===> MAINTENANCE $(date) - Updated Backend repository successfully." >> "$LOG_FILE"
    else
        echo "===> MAINTENANCE $(date) - Failed to change directory to $APP_DIR_BACKEND/server/backend" >> "$LOG_FILE"
    fi
    
    # Delete the update.txt file after updates
    rm "$UPDATE_FILE"
    echo "===> MAINTENANCE $(date) - Deleted the update.txt file." >> "$LOG_FILE"
fi
