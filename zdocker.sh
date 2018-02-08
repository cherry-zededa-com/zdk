# This script fragment is to be included from other shell script.
# It normalises docker host related variables to "defaults"

KERNELNAME=$(uname -s)

case $KERNELNAME in
    Darwin)
	export DOCKER_GROUP=authedusers
	;;
    *)
	;;
esac
