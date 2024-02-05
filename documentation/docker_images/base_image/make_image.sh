#!/bin/bash

# Script to create a base Docker image for Genular

# Whether to start fresh, set 'y' to clean and start over
FRESH_START='y'

# Define image name and working directory
IMAGE_NAME="genular"
WORKING_DIR=$(pwd)
DATE_TAG=$(date +%Y_%m_%d) # Tag image with current date

# Root filesystem directory for the Docker image
ROOT_FS="${WORKING_DIR}/images/${IMAGE_NAME}"

# GitHub Personal Access Token for private repositories access, passed as first script argument
GITHUB_PAT=$1

# Function to clean up mount points on script exit
function cleanup {
    # Unmount all mounted points to avoid any lock
    sudo mount | grep -qs "${ROOT_FS}/dev" && sudo umount -lf "${ROOT_FS}/dev"
    sudo mount | grep -qs "${ROOT_FS}/dev/pts" && sudo umount -lf "${ROOT_FS}/dev/pts"
    sudo mount | grep -qs "${ROOT_FS}/proc" && sudo umount -lf "${ROOT_FS}/proc"
    sudo mount | grep -qs "${ROOT_FS}/sys" && sudo umount -lf "${ROOT_FS}/sys"
    echo "Cleanup complete: all mount points unmounted."
}
# Trap EXIT signal to ensure cleanup is called on script exit
trap cleanup EXIT

# If starting fresh, clean up any existing image directories
if [ "$FRESH_START" == "y" ]; then
    echo "Starting fresh: Removing and recreating image directory."
    sudo rm -rf "./images/${IMAGE_NAME}" && mkdir -p "./images/${IMAGE_NAME}"
fi

# Remove existing tarball of the same name, if present
if [ -f "./images/${IMAGE_NAME}_$DATE_TAG.tar" ]; then
    echo "Removing existing tarball."
    sudo rm "./images/${IMAGE_NAME}_$DATE_TAG.tar"
fi


## Build stable debian image currently (stretch/Debian 9) - new stable version 11.5
build_command="sudo ./debootstrap $ROOT_FS stable $FRESH_START $GITHUB_PAT"

echo "Building base docker image: "
eval $build_command


echo "File-system size:"
sudo du -h --summarize $ROOT_FS

if [ -d "./images/${IMAGE_NAME}" ]; then
	## Create archive with Debian base system.
	(
		set -x
		sudo tar --numeric-owner --create --auto-compress --file "./images/$IMAGE_NAME_$DATE_TAG.tar" --directory "./images/${IMAGE_NAME}" --transform='s,^./,,' .
	)
	echo "Archive size:"
	sudo du --human-readable ./images/$IMAGE_NAME_$DATE_TAG.tar
fi
# Note: Uncomment the line below to import the image directly into Docker (requires Docker CLI installed)
# sudo cat "./images/${IMAGE_NAME}_$DATE_TAG.tar" | sudo docker import - ${IMAGE_NAME}:$DATE_TAG
