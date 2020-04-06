# @Author: LogIN-
# @Date:   2019-02-26 13:27:17
# @Last Modified by:   LogIN-
# @Last Modified time: 2020-04-06 17:33:21

FRESH_START=y

IMAGE_NAME="genular"
WORKING_DIR=$(pwd)
DATE_TAG=$(date +%Y_%m_%d)

ROOT_FS=${WORKING_DIR}/images/${IMAGE_NAME}

function finish {
	sudo mount | grep -qs ${ROOT_FS}/dev 	  && sudo umount -lf ${ROOT_FS}/dev
	sudo mount | grep -qs ${ROOT_FS}/dev/pts  && sudo umount -lf ${ROOT_FS}/dev/pts
	sudo mount | grep -qs ${ROOT_FS}/proc     && sudo umount -lf ${ROOT_FS}/proc
	sudo mount | grep -qs ${ROOT_FS}/sys      && sudo umount -lf ${ROOT_FS}/sys
	echo "==> SCRIPT END: all mount points are now unmounted"
}
trap finish EXIT

if [ "$FRESH_START" == y ] ; then
	# Clear any existing directories
	if [ -d "./images/${IMAGE_NAME}" ]; then
		sudo rm -Rf "./images/${IMAGE_NAME}" && mkdir "./images/${IMAGE_NAME}"
	else
		mkdir "./images/${IMAGE_NAME}"
	fi
fi

if [ -f "./images/${IMAGE_NAME}_$DATE_TAG.tar" ]; then
	sudo rm "./images/${IMAGE_NAME}_$DATE_TAG.tar"
fi

## Build stable debian image currently (stretch/Debian 9) - new stable version (buster/Debian 10)
build_command="sudo ./debootstrap $ROOT_FS stable $FRESH_START"

echo "Building base docker image: "
eval $build_command


echo "File-system size:"
sudo du --human-readable --summarize $ROOT_FS

if [ -d "./images/${IMAGE_NAME}" ]; then
	## Create archive with Debian base system.
	(
		set -x
		sudo tar --numeric-owner --create --auto-compress --file "./images/$IMAGE_NAME_$DATE_TAG.tar" --directory "./images/${IMAGE_NAME}" --transform='s,^./,,' .
	)
	echo "Archive size:"
	sudo du --human-readable ./images/$IMAGE_NAME_$DATE_TAG.tar
fi
### Import image to docker
# cat "./images/$IMAGE_NAME.tar" | sudo docker import - ${IMAGE_NAME}
