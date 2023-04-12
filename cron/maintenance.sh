#!/bin/bash

LOG_FILE="/var/log/pandora-cron.log"
MAX_SIZE=$((100 * 1024 * 1024))  # 100 MB in bytes


if [ -f "$LOG_FILE" ]; then
	log_size=$(wc -c < "$LOG_FILE")  # Get the current file size in bytes

	if [ "$log_size" -gt "$MAX_SIZE" ]; then
	    echo "Truncating $LOG_FILE"
	    cp /dev/null "$LOG_FILE"
	fi
fi

APP_DIR=/var/www/genular/pandora-backend
if [ -d "$APP_DIR" ]; then
    # Remove hs_err files
    rm /var/www/genular/pandora-backend/hs_err_pid*.log
fi
