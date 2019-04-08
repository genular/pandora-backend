#!/bin/bash
# @Author: LogIN-
# @Date:   2019-04-08 13:15:08
# @Last Modified by:   LogIN-
# @Last Modified time: 2019-04-08 14:00:25

## Check if user mounted custom mount point!
CUSTOM_MOUNT=n

if mountpoint -q /mnt/usrdata
then
	CUSTOM_MOUNT=y
fi

## If custom mount is detected and its empty initialize database
if [ "$CUSTOM_MOUNT" == y ] ; then
	## MYSQL
	## If directory doesn't exists create it
	if [ ! -d /mnt/usrdata/mysql ]; then
		# Create new directory for MySQL data
		sudo mkdir -p /mnt/usrdata/mysql
	fi

	## If directory is empty re-initialize mysql data
	if [ -z "$(ls -A /mnt/usrdata/mysql)" ]; then
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
	## If old data dir exsist and new one doesnt
	if [ -d /mnt/data/users ]; then
		if [ ! -d /mnt/usrdata/users ]; then
			# Create new directory for user data
			sudo mkdir -p /mnt/usrdata/users
			## Check if old directory is empty
			if [ ! -z "$(ls -A /mnt/data/users)" ]; then
				# Copy all files from old to new one
				sudo cp -R -p /mnt/data/users /mnt/usrdata/users
			fi
			# Set ownership of new directory to match existing one
			sudo chown --reference=/mnt/data/users /mnt/usrdata/users
			# Set permissions on new directory to match existing one
			sudo chmod --reference=/mnt/data/users /mnt/usrdata/users
		fi
	fi
fi