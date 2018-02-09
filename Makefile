# Copyright 2017, Zededa Inc.
# Written by Cherry G. Mathew <cherry@zededa.com> 

# Defaults for all tweakables go below
# XXX: Only a subset of these are substituted in the Dockerfile template
#      See the Dockerfile BNF below

# CPU ARCH
BUILDARCH ?= $(shell uname -m) # The target CPU architecture == host arch if unspecified.

# Template base distro
SDK_REPO_BASE ?= multiarch/alpine

# Base OS details XXX: Make distro agnostic
ALPINE_VER ?= v3.7
ALPINE_MULTIARCH_VER ?= $(strip ${BUILDARCH})-$(strip ${ALPINE_VER})
ALPINE_SDK_SHELL ?= /bin/sh
ALPINE_SDK_SHELL_ARGS ?= # arguments
ALPINE_SDK_WORKDIR ?= $(shell pwd) # Default will just end up where zmake is
ALPINE_SDK_USER ?= $(shell id -un)
ALPINE_SDK_USERID ?= $(shell id -u ${ALPINE_SDK_USER})
ALPINE_SDK_GROUP ?= $(shell id -gn)
ALPINE_SDK_GID ?= $(shell id -g)
ALPINE_SDK_USER_PKGS ?= # Set this in the environment ?

# Docker details
DOCKER_BIN ?= /var/run/docker.sock
DOCKER_GROUP ?= $(shell ls -ld ${DOCKER_BIN}|tr -s ' '|cut -d ' ' -f 4)
DOCKER_GID ?= $(shell grep -e '^${DOCKER_GROUP}' /etc/group|cut -d ':' -f 3)
DOCKER_CONTAINER ?= sdk-alpine-container-${ALPINE_MULTIARCH_VER}
DOCKER_CONTAINER_HOSTNAME ?= zdk-container
DOCKER_VOLUME_ROOT_CACHE ?= sdk-alpine-volume-root-cache-${ALPINE_MULTIARCH_VER} #can be rebuilt
DOCKER_VOLUME_HOME ?= sdk-alpine-volume-home-${ALPINE_MULTIARCH_VER} #User data
DOCKER_VOLUME_MOUNT_TYPE ?= volume
DOCKER_VOLUME_HOME_MOUNTDIR ?= /home/${ALPINE_SDK_USER}
DOCKER_VOLUME_DEBUG_IMAGE ?= sdk-debug-image
DOCKER_COMMON_PREFIX := # 

# No more tweakable defaults after this line
ALPINE_SDK_BASE_PKGS := busybox go git libc-dev make docker shadow openssh-client 
ALPINE_SDK_PKGS := ${ALPINE_SDK_BASE_PKGS} ${ALPINE_SDK_USER_PKGS}

# Name things
DOCKER_RUN_PRIFIX := --name ${DOCKER_CONTAINER} --hostname ${DOCKER_CONTAINER_HOSTNAME} 
# host docker socket sharing
DOCKER_RUN_PREFIX += -v /var/run/docker.sock:/var/run/docker.sock
# Destroy build container after use. 
DOCKER_RUN_PREFIX += --rm
# containerise home directory - use a private volume
DOCKER_RUN_PREFIX += --mount type=$(strip ${DOCKER_VOLUME_MOUNT_TYPE}),source=$(strip ${DOCKER_VOLUME_HOME}),target=$(strip ${DOCKER_VOLUME_HOME_MOUNTDIR})
# Bring in the directory on the host where the source is
DOCKER_RUN_PREFIX += -v ${ALPINE_SDK_WORKDIR}:${ALPINE_SDK_WORKDIR} -w ${ALPINE_SDK_WORKDIR}
# Setup user/group -> uid/gid mappings.
DOCKER_RUN_PREFIX += -u ${ALPINE_SDK_USERID}:${ALPINE_SDK_GID} --group-add ${DOCKER_GID} 

DOCKER_BUILD_PREFIX := 
#--no-cache=true
# Target practice!
help:
	@clear
	@echo
	@echo "Welcome to the zededa linux sdk based on docker!"
	@echo 
	@echo "To setup and run a new sdk  environment, run 'make build-sdk run-sdk-shell'"
	@echo "Other make targets of interest:" 
	@echo "		 build-sdk, run-sdk-shell, clean-sdk"
	@echo
	@echo "build-sdk: Download docker base image and install basic sdk" 
	@echo "		 set ALPINE_SDK_USER_PKGS to the list of additional Alpine Linux packages you need pre-installed."
	@echo
	@echo "run-sdk-shell: run your favourite $ALPINE_SDK_SHELL inside the newly built sdk environment"
	@echo "		 set ALPINE_SDK_SHELL to the path of your favourite shell." 
	@exit


clean: clean-files

clean-files:
	rm -f Dockerfile

clean-container:
	docker container rm ${DOCKER_CONTAINER}

clean-volume-root-cache:
	docker volume rm ${DOCKER_VOLUME_ROOT_CACHE}

# XXX: I don't want this to be enabled.
#clean-volume-home:
#	@echo Sorry - if you really want to do this, do this on the command line.

clean-sdk: # Silly attempt to babysit
	@echo "Are you sure you want to destroy your entire SDK data and state ?" ; echo -n "(NO/yeS/^C): "
	@read SDKDELCONFIRMED && test $$SDKDELCONFIRMED == "yeS" || { echo "Aborted clean";exit 1; }
	@echo "Destroying SDK data and state by calling make in a subshell"
	${MAKE} -k clean-container clean-volume-root-cache

# Let's import some variables from the environment!
.PHONY: Dockerfile

# XXX: This whole thing below needs to go into a parser that groks Dockerfile BNF
# POSIX fascism - not using 'sed -i'
Dockerfile: Dockerfile.in 
	set -e ;\
	_ZDK_TMPFILE=$$(mktemp) ;\
	sed s/\$$\{ALPINE_MULTIARCH_VER\}/${ALPINE_MULTIARCH_VER}/g $< > $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{ALPINE_SDK_SHELL\}/$(subst /,\\/,${ALPINE_SDK_SHELL})/g $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{ALPINE_SDK_USER\}/${ALPINE_SDK_USER}/g $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{ALPINE_SDK_USERID\}/${ALPINE_SDK_USERID}/g $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{ALPINE_SDK_GROUP\}/${ALPINE_SDK_GROUP}/g $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{ALPINE_SDK_GID\}/${ALPINE_SDK_GID}/g $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{ALPINE_SDK_PKGS\}/'${ALPINE_SDK_PKGS}'/g $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{DOCKER_GROUP\}/${DOCKER_GROUP}/g $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{DOCKER_GID\}/${DOCKER_GID}/g $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{SDK_REPO_BASE\}/$(subst /,\\/,${SDK_REPO_BASE})/g $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $$_ZDK_TMPFILE ;\

build-sdk: Dockerfile
	docker build ${DOCKER_BUILD_PREFIX} -t ${DOCKER_VOLUME_ROOT_CACHE} .

run-sdk-shell: 
	docker run ${DOCKER_RUN_PREFIX} -it ${DOCKER_VOLUME_ROOT_CACHE} ${ALPINE_SDK_SHELL} ${ALPINE_SDK_SHELL_ARGS}

# Used for image inspection. We merge the contents of
# DOCKER_VOLUME_ROOT_CACHE and the
# requested container into a new container and start a shell in this
# new container.
# We use a hack by just re-using the Dockerfile template by sticking
# what we need at the bottom of the Auto-gen-ed Dockerfile

run-debug-shell: build-sdk
	# Dockerfile is now autogen-ed. We just tack our stuff into it.
	# XXX: Figure out multiline string echo.
	# XXX: First
	set -e ;\
	_ZDK_TMPFILE=$$(mktemp) ;\
	echo "#" > $$_ZDK_TMPFILE ;\
	echo "# Copy the image we're interested in inspecting." >> $$_ZDK_TMPFILE  ;\
	echo "FROM ${DOCKER_VOLUME_DEBUG_IMAGE} AS image-inspected" >> $$_ZDK_TMPFILE ;\
	echo "#" >> $$_ZDK_TMPFILE ;\
	_DOCKERSTRING=$$(cat $$_ZDK_TMPFILE Dockerfile) ;\
	echo "$$_DOCKERSTRING" > Dockerfile ;\
	rm -f $$_ZDK_TMPFILE
	@echo >> Dockerfile
	@echo "#" >> Dockerfile 
	@echo "# Bring in contents of image being inspected." >> Dockerfile
	@echo "COPY --from=image-inspected / /${DOCKER_VOLUME_DEBUG_IMAGE}/" >> Dockerfile
	# Cleanup old volume
	#docker image rm -f ${DOCKER_VOLUME_ROOT_CACHE} # Clean the slate.
	# Run build with new Dockerfile in place.
	docker build ${DOCKER_BUILD_PREFIX} -t ${DOCKER_VOLUME_ROOT_CACHE} .
	# Run a sub make with run-sdk-shell
	${MAKE} MAKEFLAGS= run-sdk-shell

