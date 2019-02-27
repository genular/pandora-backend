# @Author: LogIN-
# @Date:   2019-02-26 13:27:17
# @Last Modified by:   LogIN-
# @Last Modified time: 2019-02-26 16:35:31
# 
# 
# Example: https://blog.sleeplessbeastie.eu/2018/04/11/how-to-create-base-docker-image/

FRESH_START=n

IMAGE_NAME="genular"
WORKING_DIR=$(pwd)

if [ "$FRESH_START" == y ] ; then
	# Clear any existing directories
	if [ -d "./$IMAGE_NAME" ]; then
		sudo rm -Rf "./$IMAGE_NAME" && mkdir "./$IMAGE_NAME"
	fi
fi

if [ -f "./$IMAGE_NAME.tar" ]; then
	sudo rm "./$IMAGE_NAME.tar"
fi

build_command="sudo ./debootstrap $WORKING_DIR/$IMAGE_NAME stable $FRESH_START"

echo "Building base docker image: "
eval $build_command
exit

echo "File-system size:"
sudo du --human-readable --summarize $IMAGE_NAME

## Create archive with Debian base system.
sudo tar --verbose --create --file $IMAGE_NAME.tar --directory "./$IMAGE_NAME" .

echo "Archive size:"
sudo du --human-readable $IMAGE_NAME.tar

### Import image to docker
# cat file-system.tar | docker import - genular
