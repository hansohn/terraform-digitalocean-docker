MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

# include makefiles
export SELF ?= $(MAKE)
PROJECT_PATH ?= $(shell 'pwd')
include $(PROJECT_PATH)/Makefile.*

REPO_NAME ?= $(shell basename $(CURDIR))

#-------------------------------------------------------------------------------
# docker
#-------------------------------------------------------------------------------

DOCKER_USER ?= hansohn
DOCKER_REPO ?= $(firstword $(subst -docker, , $(REPO_NAME)))
DOCKER_TAG_BASE ?= $(DOCKER_USER)/$(DOCKER_REPO)

DOCTL_VERSION ?= latest
TERRAFORM_VERSION ?= latest

GIT_BRANCH ?= $(shell git branch --show-current 2>/dev/null || echo 'unknown')
GIT_HASH := $(shell git rev-parse --short HEAD 2>/dev/null || echo 'pre')

DOCKER_TAGS ?=
DOCKER_TAGS += --tag $(DOCKER_TAG_BASE):$(GIT_HASH)
ifeq ($(GIT_BRANCH), main)
DOCKER_TAGS += --tag $(DOCKER_TAG_BASE):latest
DOCKER_TAGS += --tag $(DOCKER_TAG_BASE):$(TERRAFORM_VERSION)
endif

DOCKER_BUILD_PATH ?= docker
DOCKER_BUILD_ARGS ?=
DOCKER_BUILD_ARGS += --build-arg DOCTL_VERSION=$(DOCTL_VERSION)
DOCKER_BUILD_ARGS += --build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION)
DOCKER_BUILD_ARGS += --platform=linux/amd64,linux/arm64
DOCKER_BUILD_ARGS += $(DOCKER_TAGS)

DOCKER_RUN_ARGS ?=
DOCKER_RUN_ARGS += --interactive
DOCKER_RUN_ARGS += --tty
DOCKER_RUN_ARGS += --rm

DOCKER_PUSH_ARGS ?=
DOCKER_PUSH_ARGS += --all-tags
DOCKER_PUSH_ARGS += --platform=linux/amd64,linux/arm64

## Lint Dockerfile
docker/lint:
	-@if docker info > /dev/null 2>&1; then \
		echo "[INFO] Linting '$(DOCKER_REPO)/Dockerfile'."; \
		docker run --rm -i hadolint/hadolint < $(DOCKER_BUILD_PATH)/Dockerfile; \
	else \
		echo "[ERROR] Docker 'lint' failed. Docker daemon is not Running."; \
	fi
.PHONY: docker/lint

## Docker build image
docker/build:
	-@if docker info > /dev/null 2>&1; then \
		echo "[INFO] Building '$(DOCKER_USER)/$(DOCKER_REPO)' docker image."; \
		docker buildx build $(DOCKER_BUILD_ARGS) $(DOCKER_BUILD_PATH)/; \
	else \
		echo "[ERROR] Docker 'build' failed. Docker daemon is not Running."; \
	fi
.PHONY: docker/build

## Docker run image
docker/run:
	-@if docker info > /dev/null 2>&1; then \
		echo "[INFO] Running '$(DOCKER_USER)/$(DOCKER_REPO)' docker image"; \
		docker run $(DOCKER_RUN_ARGS) "$(DOCKER_TAG_BASE):$(GIT_HASH)" bash; \
	else \
		echo "[ERROR] Docker 'run' failed. Docker daemon is not Running."; \
	fi
.PHONY: docker/run

## Docker push image
docker/push:
	-@if docker info > /dev/null 2>&1; then \
		echo "[INFO] Pushing '$(DOCKER_USER)/$(DOCKER_REPO)' docker image"; \
		docker push $(DOCKER_PUSH_ARGS) $(DOCKER_TAG_BASE); \
	else \
		echo "[ERROR] Docker 'push' failed. Docker daemon is not Running."; \
	fi
.PHONY: docker/push

## Docker lint, build and run image
docker: docker/lint docker/build docker/run
.PHONY: docker all

#-------------------------------------------------------------------------------
# clean
#-------------------------------------------------------------------------------

## Clean docker build images
clean/docker:
	-@if docker info > /dev/null 2>&1; then \
		if docker inspect --type=image "$(DOCKER_TAG_BASE):$(GIT_HASH)" > /dev/null 2>&1; then \
			echo "[INFO] Removing docker image '$(DOCKER_USER)/$(DOCKER_REPO)'"; \
			docker rmi -f $$(docker inspect --format='{{ .Id }}' --type=image $(DOCKER_TAG_BASE):$(GIT_HASH)); \
		fi; \
	fi
.PHONY: clean/docker

## Clean everything
clean: clean/docker
.PHONY: clean
