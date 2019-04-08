#!/bin/bash
# @Author: LogIN-
# @Date:   2019-04-08 13:15:08
# @Last Modified by:   LogIN-
# @Last Modified time: 2019-04-08 15:56:08

CUSTOM_MOUNT=n

if mountpoint -q /mnt/usrdata
then
	CUSTOM_MOUNT=y
fi

## If custom mount is detected and its empty initialize database
if [ "$CUSTOM_MOUNT" == y ] ; then

	echo "Custom mount-point requested"

	## MYSQL
	## If directory doesn't exists create it
	if [ ! -d /mnt/usrdata/mysql ]; then
		echo "Creating /mnt/usrdata/mysql directory"
		# Create new directory for MySQL data
		sudo mkdir -p /mnt/usrdata/mysql
	fi

	## If directory is empty re-initialize mysql data
	if [ -z "$(ls -A /mnt/usrdata/mysql)" ]; then
		echo "/mnt/usrdata/mysql is empty:  re-initialize mysql data"
		# Set ownership of new directory to match existing one
		sudo chown --reference=/var/lib/mysql /mnt/usrdata/mysql
		# Set permissions on new directory to match existing one
		sudo chmod --reference=/var/lib/mysql /mnt/usrdata/mysql
		# Copy all files in default directory, to new one, retaining perms (-p)
		sudo cp -R -p /var/lib/mysql /mnt/usrdata/mysql
		## Change mysql configuration
		sed -i '/datadir/c\datadir		= /mnt/usrdata/mysql' /etc/mysql/mariadb.conf.d/50-server.cnf
	fi

	## FILES
	## If old data dir exists (/mnt/data/users) and new one doesn't (/mnt/usrdata/users)
	if [ -d /mnt/data/users ]; then

		echo "/mnt/data/users exists"

		if [ ! -d /mnt/usrdata/users ]; then

			echo "/mnt/data/users doesn't exists, creating one"

			# Create new directory for user data
			sudo mkdir -p /mnt/usrdata/users

			## Check if old directory is empty
			if [ ! -z "$(ls -A /mnt/data/users)" ]; then

				echo "Copying old files /mnt/data/users /mnt/usrdata/users"
				# Copy all files from old to new one
				sudo cp -R -p /mnt/data/users /mnt/usrdata/users
			fi

			# Set ownership of new directory to match existing one
			sudo chown --reference=/mnt/data/users /mnt/usrdata/users
			# Set permissions on new directory to match existing one
			sudo chmod --reference=/mnt/data/users /mnt/usrdata/users

			## Change data directory in SIMON backend configuration file
			cd /var/www/genular/simon-backend/server/backend/ && composer post-install '{"default":{"storage":{"local":{"data_path":"/mnt/usrdata"}}}}'
		fi
	else
		## Even /mnt/data/users doesn't exists
		## Change data directory in SIMON backend configuration file
		cd /var/www/genular/simon-backend/server/backend/ && composer post-install '{"default":{"storage":{"local":{"data_path":"/mnt/usrdata"}}}}'
	fi
fi