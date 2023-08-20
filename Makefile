# The registry, repository and image names default to the official but can be overriden
# via environment variables.
# For testing, You can start a local registry with:
#    docker run -d -p 5000:5000 --restart=always --name registry registry:2
#    with REGISTRY ?= localhost:5000

-include .env
export

REGISTRY ?= docker.io
REPO_NAME  ?= postgis
IMAGE_NAME ?= postgis

PUSH_FULL_IMAGENAME = ;$(DOCKER) image push $(REGISTRY)/$(REPO_NAME)/$(IMAGE_NAME):
FULL_IMAGENAME_WITH_T =  -t $(REGISTRY)/$(REPO_NAME)/$(IMAGE_NAME):

DOCKER ?=docker
DOCKERHUB_DESC_IMG=peterevans/dockerhub-description:latest
DOCKER_BUILDOPT ?= --network=host --progress=plain

GIT ?=git
OFFIMG_LOCAL_CLONE ?=$(HOME)/official-images
OFFIMG_REPO_URL ?=https://github.com/docker-library/official-images.git

# Default target: help
.DEFAULT_GOAL := help

# Dynamically determine versions and variants based on
#   the existence of Dockerfile at the depth of two directories
#     where the first directory names starting with a number.
DOCKERFILE_DIRS := $(shell find . -mindepth 2 -maxdepth 2 -type d -exec test -e '{}/Dockerfile' \; -print | sed 's|./||' | awk '/^[0-9]/ {print}')
VERSIONS := $(sort $(shell echo '$(DOCKERFILE_DIRS)' | tr ' ' '\n' | cut -d'/' -f1))
VARIANTS := $(sort $(shell echo '$(DOCKERFILE_DIRS)' | tr ' ' '\n' | cut -d'/' -f2))

check_variant:
ifeq ($(VARIANT),default)
	$(error VARIANT is set to 'default', which is not allowed!)
endif
ifeq ($(VARIANT),alpine)
	$(error VARIANT is set to 'alpine', which is not allowed!)
endif

# Build targets for each version-variant combination
define build-target
build-$(1)-$(2): check_variant \
			     $(if $(filter 2,$(shell echo $(1) | grep -o '-' | wc -l)),build-$(shell echo $(1) | cut -d- -f1,2)-$(2))
	@echo '::Building $(FULL_IMAGENAME_WITH_T)$(1)-$(2)'
	@echo ':::::: dependency: $(if $(filter 2,$(shell echo $(1) | grep -o '-' | wc -l)),build-$(shell echo $(1) | cut -d- -f1,2)-$(2)) '
	$(DOCKER) build $(DOCKER_BUILDOPT) \
	                --build-arg="REGISTRY=$(REGISTRY)" \
	                --build-arg="REPO_NAME=$(REPO_NAME)" \
	                --build-arg="IMAGE_NAME=$(IMAGE_NAME)" \
					$(if $(filter 1,$(shell echo $(1) | grep -o '-' | wc -l)), --pull ) \
		  		    $(shell cat $(1)/$(2)/tags | sed 's#\([a-zA-Z0-9.-]*\)#$(subst $,,$(FULL_IMAGENAME_WITH_T))\1#g' ) \
					$(1)/$(2)
	$(DOCKER) image ls $(REGISTRY)/$(REPO_NAME)/$(IMAGE_NAME):$(1)-$(2)
endef
$(foreach dir,$(DOCKERFILE_DIRS),$(eval $(call build-target,$(word 1,$(subst /, ,$(dir))),$(word 2,$(subst /, ,$(dir))))))

# Build targets for each version
define build-version-target
build-$(1): $(shell echo '$(DOCKERFILE_DIRS)' | tr ' ' '\n' | grep ^$(1)/ | sed 's|$(1)/|build-$(1)-|')
endef
$(foreach version,$(VERSIONS),$(eval $(call build-version-target,$(version))))
# General build target
build: $(foreach dir,$(DOCKERFILE_DIRS),build-$(word 1,$(subst /, ,$(dir)))-$(word 2,$(subst /, ,$(dir))))


# --------------------------------------------------

test-prepare:
ifeq ("$(wildcard $(OFFIMG_LOCAL_CLONE))","")
	@echo '::Cloning official-images $(OFFIMG_LOCAL_CLONE)'
	$(GIT) clone $(OFFIMG_REPO_URL) $(OFFIMG_LOCAL_CLONE)
else
	@echo '::Updating official-images : $(OFFIMG_LOCAL_CLONE)'
	cd $(OFFIMG_LOCAL_CLONE) && $(GIT) pull origin master
endif

# Test targets for each version-variant combination
define test-target
test-$(1)-$(2): test-prepare \
                build-$1-$(2) \
			    $(if $(filter 2,$(shell echo $(1) | grep -o '-' | wc -l)),test-$(shell echo $(1) | cut -d- -f1,2)-$(2))
	@echo ':Testing $(1)/$(2)' - $(shell cat $(1)/$(2)/tags | cut -d' ' -f1)
	@echo ':::::: dependency: $(if $(filter 2,$(shell echo $(1) | grep -o '-' | wc -l)),test-$(shell echo $(1) | cut -d- -f1,2)-$(2)) '
	$(OFFIMG_LOCAL_CLONE)/test/run.sh -c $(OFFIMG_LOCAL_CLONE)/test/config.sh -c test/postgis-config.sh $(REGISTRY)/$(REPO_NAME)/$(IMAGE_NAME):$(shell cat $(1)/$(2)/tags | cut -d' ' -f1)
endef
$(foreach dir,$(DOCKERFILE_DIRS),$(eval $(call test-target,$(word 1,$(subst /, ,$(dir))),$(word 2,$(subst /, ,$(dir))))))

# Build targets for each version
define test-version-target
test-$(1): $(shell echo '$(DOCKERFILE_DIRS)' | tr ' ' '\n' | grep ^$(1)/ | sed 's|$(1)/|test-$(1)-|')
endef
$(foreach version,$(VERSIONS),$(eval $(call test-version-target,$(version))))
# General test target
test: $(foreach dir,$(DOCKERFILE_DIRS),test-$(word 1,$(subst /, ,$(dir)))-$(word 2,$(subst /, ,$(dir))))

# --------------------------------------------------
# Push targets for each version-variant combination
define push-target
push-$(1)-$(2):	test-$1-$(2) \
                $(if $(findstring latest,$(shell cat $(1)/$(2)/tags)),push-readme) \
				$(if $(filter 2,$(shell echo $(1) | grep -o '-' | wc -l)),push-$(shell echo $(1) | cut -d- -f1,2)-$(2))
	@echo '::Pushing $(1)/$(2)'
	@echo ':::::: dependency: $(if $(filter 2,$(shell echo $(1) | grep -o '-' | wc -l)),push-$(shell echo $(1) | cut -d- -f1,2)-$(2)) '
	@echo 'echo "PUSH:"' $(shell cat $(1)/$(2)/tags | sed 's#\([a-zA-Z0-9.-]*\)#\n$(subst $,,$(PUSH_FULL_IMAGENAME))\1#g' )
endef
$(foreach dir,$(DOCKERFILE_DIRS),$(eval $(call push-target,$(word 1,$(subst /, ,$(dir))),$(word 2,$(subst /, ,$(dir))))))

# Build targets for each version
define push-version-target
push-$(1): $(shell echo '$(DOCKERFILE_DIRS)' | tr ' ' '\n' | grep ^$(1)/ | sed 's|$(1)/|push-$(1)-|')
endef
$(foreach version,$(VERSIONS),$(eval $(call push-version-target,$(version))))
# General push target
push: $(foreach dir,$(DOCKERFILE_DIRS),push-$(word 1,$(subst /, ,$(dir)))-$(word 2,$(subst /, ,$(dir))))

# --------------------------------------------------
push-readme:
	@echo '::PUSH_README.md ( because "latest" tag exists )'
	@if [ "$(REGISTRY)" = "docker.io" ]; then \
		$(DOCKER) pull $(DOCKERHUB_DESC_IMG); \
		$(DOCKER) run -v "$(PWD)":/workspace \
                      -e DOCKERHUB_USERNAME="$(DOCKERHUB_USERNAME)" \
                      -e DOCKERHUB_PASSWORD="$(DOCKERHUB_ACCESS_TOKEN)" \
                      -e DOCKERHUB_REPOSITORY="$(REGISTRY)/$(REPO_NAME)/$(IMAGE_NAME)" \
                      -e README_FILEPATH="/workspace/README.md" $(DOCKERHUB_DESC_IMG); \
	else \
		echo '$(REGISTRY) is not docker.io ; Not pushing README.md to Dockerhub'; \
	fi

all: check_variant update build test

update:
	@echo '::Updating Dockerfiles'
	$(DOCKER) pull buildpack-deps
	$(DOCKER) run --rm -v $$(pwd):/work -w /work buildpack-deps ./update.sh

check-gh-rate:
	@echo 'Checking github ratelimit ...'
	@curl -sI https://api.github.com/users/octocat | grep x-ratelimit

# Help target
help: check_variant
	@echo ' Available make targets:'
	@echo '------------------------------------ '
	@echo 'build        : Build the docker image versions and variants'
	@echo $(foreach version,$(VERSIONS),' build-$(version)')
	@echo $(foreach dir,$(DOCKERFILE_DIRS),' build-$(word 1,$(subst /, ,$(dir)))-$(word 2,$(subst /, ,$(dir)))')
	@echo ' '
	@echo 'test         : Test the docker image versions and variants'
	@echo $(foreach version,$(VERSIONS),' test-$(version)')
	@echo $(foreach dir,$(DOCKERFILE_DIRS),' test-$(word 1,$(subst /, ,$(dir)))-$(word 2,$(subst /, ,$(dir)))')
	@echo ' '
	@echo 'push         : Push to the registry the docker image versions and variants'
	@echo $(foreach version,$(VERSIONS),' push-$(version)')
	@echo $(foreach dir,$(DOCKERFILE_DIRS),' push-$(word 1,$(subst /, ,$(dir)))-$(word 2,$(subst /, ,$(dir)))')
	@echo ' '
	@echo 'all          : Local run: "update" "build" "test" (without push)'
	@echo 'check-gh-rate: Check the github ratelimit'
	@echo 'help         : This help file'
	@echo 'push-readme  : Push README.md to Dockerhub'
	@echo 'test-prepare : Clone official-images repository'
	@echo 'update       : Generate/Update all Dockerfiles'
	@echo '------------------------------------ '
	@echo 'You can check the the commands without executing: make -n <target> '
	@echo ' '

.PHONY: build all update test-prepare test push push-readme check-gh-rate help \
	$(foreach version,$(VERSIONS),' build-$(version)') \
	$(foreach dir,$(DOCKERFILE_DIRS),' build-$(word 1,$(subst /, ,$(dir)))-$(word 2,$(subst /, ,$(dir)))') \
	$(foreach version,$(VERSIONS),' test-$(version)') \
	$(foreach dir,$(DOCKERFILE_DIRS),' test-$(word 1,$(subst /, ,$(dir)))-$(word 2,$(subst /, ,$(dir)))') \
	$(foreach version,$(VERSIONS),' push-$(version)') \
	$(foreach dir,$(DOCKERFILE_DIRS),' push-$(word 1,$(subst /, ,$(dir)))-$(word 2,$(subst /, ,$(dir)))')
