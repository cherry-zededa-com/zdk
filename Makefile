# Copyright 2017, Zededa Inc.
# Written by Cherry G. Mathew <cherry@zededa.com> 

# CPU ARCH
BUILDARCH ?= $(shell uname -m) # The target CPU architecture == host arch if unspecified.

# Template base distro
SDK_REPO_BASE ?= multiarch/alpine

# Base OS details XXX: Make distro agnostic
ALPINE_VER ?= v3.7
ALPINE_MULTIARCH_VER ?= $(strip ${BUILDARCH})-$(strip ${ALPINE_VER})
ALPINE_SHELL ?= /bin/sh
ALPINE_SDK_BASE_PKGS ?= go git libc-dev make docker
ALPINE_SDK_SETUP_COMMANDS ?= "apk update && \
			      apk add ${ALPINE_SDK_BASE_PKGS}"

# Docker details
DOCKER_CONTAINER ?= sdk-alpine-container-${ALPINE_MULTIARCH_VER}
DOCKER_VOLUME_ROOT_CACHE ?= sdk-alpine-volume-root-cache-${ALPINE_MULTIARCH_VER} #can be rebuilt
DOCKER_VOLUME_HOME ?= sdk-alpine-volume-home-${ALPINE_MULTIARCH_VER} #User data
DOCKER_RUN_PREFIX := --name ${DOCKER_CONTAINER} --mount source=$(strip ${DOCKER_VOLUME_HOME}),target=/home/

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
	@echo "		 set ALPINE_SDK_BASE_PKGS to the list of Alpine Linux packages you would like pre-installed."
	@echo
	@echo "run-sdk-shell: run your favourite $ALPINE_SHELL inside the newly built sdk environment"
	@echo "		 set ALPINE_SHELL to the path of your favourite shell." 
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
#.PHONY: Dockerfile

# XXX: This whole thing below needs to go into a parser that groks Dockerfile BNF
Dockerfile: Dockerfile.in
	set -e ;\
	_ZDK_TMPFILE=$$(mktemp) ;\
	sed s/\$$\{ALPINE_MULTIARCH_VER\}/${ALPINE_MULTIARCH_VER}/ $< > $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{ALPINE_SDK_BASE_PKGS\}/'${ALPINE_SDK_BASE_PKGS}'/ $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $@ $$_ZDK_TMPFILE ;\
	sed s/\$$\{SDK_REPO_BASE\}/$(subst /,\\/,${SDK_REPO_BASE})/ $@ > $$_ZDK_TMPFILE && mv $$_ZDK_TMPFILE $@ || rm -f $$_ZDK_TMPFILE ;\



build-sdk: Dockerfile
	docker build --build-arg SDK_REPO_BASE=${SDK_REPO_BASE} --build-arg ALPINE_MULTIARCH_VER=${ALPINE_MULTIARCH_VER} -t ${DOCKER_VOLUME_ROOT_CACHE} .

run-sdk-shell:
	docker run --rm ${DOCKER_RUN_PREFIX} -it ${DOCKER_VOLUME_ROOT_CACHE} ${ALPINE_SHELL}
