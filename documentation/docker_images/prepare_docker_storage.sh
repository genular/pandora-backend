#!/bin/bash
# @Author: LogIN-
# @Date:   2019-04-08 13:15:08
# @Last Modified by:   LogIN-
# @Last Modified time: 2019-04-15 08:30:26

CUSTOM_MOUNT=n

if mountpoint -q /mnt/usrdata
then
	CUSTOM_MOUNT=y
fi

## If custom mount is detected and its empty initialize database
if [ "$CUSTOM_MOUNT" == y ] ; then

	echo "Custom mount-point requested"

	## MYSQL
	## If directory doesn't exists
	if [ ! -d /mnt/usrdata/mysql ]; then
		echo "/mnt/usrdata/mysql doesn't exists creating new one!"
		# Copy all files in default directory, to new one, retaining perms (-p)
		sudo cp -R -p /var/lib/mysql /mnt/usrdata

		# Set ownership of new directory to match existing one
		sudo chown --reference=/var/lib/mysql /mnt/usrdata/mysql

		# Set permissions on new directory to match existing one
		sudo chmod --reference=/var/lib/mysql /mnt/usrdata/mysql

		# Fix for Debian 12
		sudo chown mysql:mysql -hR /mnt/usrdata/mysql

		## Change mysql configuration
		sed -i '/datadir/c\datadir		= /mnt/usrdata/mysql' /etc/mysql/mariadb.conf.d/50-server.cnf

		## SHOW VARIABLES WHERE Variable_Name = "datadir";
	else
		echo "/mnt/usrdata/mysql already exists skipping!"
		## Just in case change mysql configuration but this should be already changed!
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

			## Change data directory in PANDORA backend configuration file
			cd /var/www/genular/pandora-backend/server/backend/ && composer post-install '{"default":{"storage":{"local":{"data_path":"/mnt/usrdata"}}}}'
		fi
	else
		## Even /mnt/data/users doesn't exists
		## Change data directory in PANDORA backend configuration file
		cd /var/www/genular/pandora-backend/server/backend/ && composer post-install '{"default":{"storage":{"local":{"data_path":"/mnt/usrdata"}}}}'
	fi
else
	echo "Custom mount-point not requested, reseting configuration to default"
	## Just in case change mysql configuration but this should be already changed!
	sed -i '/datadir/c\datadir		= /var/lib/mysql' /etc/mysql/mariadb.conf.d/50-server.cnf

	if [ ! -d /mnt/data/users ]; then
		if [ -d /mnt/usrdata/users ]; then
			echo "Copying old files /mnt/usrdata/users /mnt/data/users"
			# Copy all files from old to new one
			sudo cp -R -p /mnt/usrdata/users /mnt/data/users
		fi
	fi
	## Change data directory in PANDORA backend configuration file
	cd /var/www/genular/pandora-backend/server/backend/ && composer post-install '{"default":{"storage":{"local":{"data_path":"/mnt/data"}}}}'
fi

## Restart dependent services with new configuration
## cron:cron_00      
## nginx:nginx_00    
## php-fpm:php-fpm_00
## prepare_storage
#
## pm2:pm2_00    
## mariadb:mariadb_00
sudo supervisorctl -c /etc/supervisor/conf.d/supervisord.conf start mariadb:mariadb_00 pm2:pm2_00
