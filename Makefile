#!/bin/bash
# Makefile to wrap common docker and dev related tasks. Just type 'make' to get
# help.
#
# Requirements:
#  - Install Docker locally
#	 	Mac OS `brew cask install docker`
#    	Linux: `apt-get install docker`

REGISTRY = registry.gitlab.com/aptrust
REPOSITORY = container-registry
NAME=$(shell basename $(CURDIR))
REVISION=$(shell git log -1 --pretty=%h)
REVISION=$(shell git rev-parse --short=7 HEAD)
BRANCH = $(subst /,_,$(shell git rev-parse --abbrev-ref HEAD))
PUSHBRANCH = $(subst /,_,$(TRAVIS_BRANCH))
TAG = $(NAME):$(REVISION)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help build publish

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

revision: ## Show me the git hash
	@echo $(REVISION)
	@echo $(BRANCH)

build: ## Build the Pharos container from current repo. Make sure to commit all changes beforehand
	echo $(REVISION) >> .revision
	docker build --build-arg PHAROS_RELEASE=$(REVISION) -t $(TAG) -t aptrust/$(TAG) -t $(REGISTRY)/$(REPOSITORY)/$(TAG) -t $(REGISTRY)/$(REPOSITORY)/pharos:$(REVISION)-$(BRANCH) .
	docker build --build-arg PHAROS_RELEASE=${REVISION} -t $(REGISTRY)/$(REPOSITORY)/nginx-proxy-pharos:$(REVISION) -t $(REGISTRY)/$(REPOSITORY)/nginx-proxy-pharos:$(REVISION)-$(BRANCH) -t aptrust/nginx-proxy-pharos -f Dockerfile.nginx .

build-nc: ## Build the Pharos container, no cached layers.
	echo $(REVISION) >> .revision
	docker build --no-cache --build-arg PHAROS_RELEASE=$(REVISION) -t aptrust/$(TAG) -t $(REGISTRY)/$(REPOSITORY)/$(TAG) .
	docker build --build-arg PHAROS_RELEASE=${REVISION} -t $(REGISTRY)/$(REPOSITORY)/nginx-proxy-pharos:$(REVISION) -t $(REGISTRY)/$(REPOSITORY)/nginx-proxy-pharos -t aptrust/nginx-proxy-pharos -f Dockerfile.nginx .

up: ## Start containers for Pharos, Postgresql, Nginx
	DOCKER_TAG_NAME=$(REVISION) docker-compose up

down: ## Stop containers for Pharos, Postgresql, Nginx
	docker-compose down

run: ## Just run Pharos in foreground
	docker run -p 9292:9292 $(TAG)

runshell: ## Run Pharos container with interactive shell
	docker run -it -p 9292:9292 $(TAG) bash

runcmd: ## Start Pharos container, run command and exit.
	docker run $(TAG) $(filter-out $@, $(MAKECMDGOALS))

%:
	@true

test-ci: build ## Run Pharos spec tests in CI
	docker network create -d bridge pharos-test-net
	docker run -d --network pharos-test-net -h pharos-test-db --name pharos-test-db -p 5432:5432 postgres:9.6.6-alpine
	docker run -e TRAVIS_JOB_ID="$(TRAVIS_JOB_ID)" -e TRAVIS_BRANCH="$(TRAVIS_BRANCH)" -e RAILS_ENV=test -e PHAROS_DB_NAME=travis_ci_test -e PHAROS_DB_HOST=pharos-test-db -e PHAROS_DB_USER=postgres --network pharos-test-net $(TAG) /bin/bash -c "echo 'Init DB setup'; rake db:setup; rake db:migrate; rake pharos:setup; bin/rails spec"
	docker stop pharos-test-db && docker rm pharos-test-db
	docker network rm pharos-test-net

dtest: ## Run Pharos spec tests
	docker network create -d bridge pharos-test-net > /dev/null 2>&1 || true
	docker start pharos-test-db > /dev/null 2>&1 || docker run -d --network pharos-test-net --hostname pharos-test-db --name pharos-test-db -p 5432:5432 postgres:9.6.6-alpine
	docker run  -e PHAROS_DB_NAME=pharos_test -e PHAROS_DB_HOST=pharos-test-db -e PHAROS_DB_USER=postgres -e PHAROS_DB_HOST=pharos-test-db --network pharos-test-net --rm --name pharos-migration $(TAG) /bin/bash -c "echo 'Init DB setup'; rake db:setup; rake db:migrate; rake pharos:setup"
#   Test for only latest build
#	docker run --rm -it --network pharos-test-net -e PHAROS_DB_NAME=pharos_test -e PHAROS_DB_HOST=pharos-test-db -e RAILS_ENV=test $(TAG) /bin/bash -c "bin/rake"
#	Test current codebase
	docker run --rm -it --network pharos-test-net -e PHAROS_DB_NAME=pharos_test -e PHAROS_DB_HOST=pharos-test-db -e RAILS_ENV=test -v ${PWD}:/pharos2 $(TAG) /bin/bash -c "/pharos2/bin/rails spec"
	docker stop pharos-test-db && docker rm -v pharos-test-db || true
	docker network rm pharos-test-net

dev: ## Run Pharos for development on localhost
	docker network create -d bridge pharos-dev-net > /dev/null 2>&1 || true
	#docker start pharos-dev-db > /dev/null 2>&1 || docker run -d --network pharos-dev-net --hostname pharos-dev-db -e POSTGRES_DB=pharos_development --name pharos-dev-db -p 5432:5432 postgres:9.6.6-alpine
	docker start pharos-dev-db > /dev/null 2>&1 || docker run -d --network pharos-dev-net --hostname pharos-dev-db --name pharos-dev-db -p 5432:5432 postgres:9.6.6-alpine
	docker run  -e PHAROS_DB_NAME=pharos_development -e PHAROS_DB_HOST=pharos-dev-db -e PHAROS_DB_USER=postgres -e PHAROS_DB_HOST=pharos-dev-db --network pharos-dev-net --rm --name pharos-migration $(TAG) /bin/bash -c "sleep 15 && rake db:exists && rake db:migrate || echo 'Init DB setup'; rake db:setup RAILS_ENV=development; rake db:migrate; rake pharos:setup"
	docker start pharos-dev-web > /dev/null 2>&1 || docker run -d -e PHAROS_DB_HOST=pharos-dev-db -e PHAROS_DB_NAME=pharos_development -e PHAROS_DB_USER=postgres --network=pharos-dev-net -p 9292:9292 --name pharos-dev-web $(TAG)

devclean: ## Stop and remove running Docker containers
	docker stop pharos-dev-db && docker rm -v pharos-dev-db || true
	docker stop pharos-dev-web && docker rm -v pharos-dev-web || true
	docker network rm pharos-dev-net

devstop: ## Stop running Docker containers. Can pick up dev later
	docker stop pharos-dev-db
	docker stop pharos-dev-web

publish:
	# GITLAB
	docker login $(REGISTRY)
#	docker push $(REGISTRY)/$(REPOSITORY)/pharos
	docker push $(REGISTRY)/$(REPOSITORY)/pharos:$(REVISION)-$(BRANCH)
	docker push $(REGISTRY)/$(REPOSITORY)/nginx-proxy-pharos:$(REVISION)-$(BRANCH)
	#docker build --build-arg PHAROS_RELEASE=${REVISION} -t $(REGISTRY)/$(REPOSITORY)/nginx-proxy-pharos -t aptrust/nginx-proxy-pharos -f Dockerfile.nginx .
	# Docker Hub
	#docker login docker.io
	#docker push aptrust/pharos

publish-ci:
	@echo $(DOCKER_PWD) | docker login -u $(DOCKER_USER) --password-stdin $(REGISTRY)
	docker tag  $(REGISTRY)/$(REPOSITORY)/pharos:$(REVISION) $(REGISTRY)/$(REPOSITORY)/pharos:$(REVISION)-$(PUSHBRANCH)
	docker tag  $(REGISTRY)/$(REPOSITORY)/nginx-proxy-pharos:$(REVISION) $(REGISTRY)/$(REPOSITORY)/nginx-proxy-pharos:$(REVISION)-$(PUSHBRANCH)
	#docker push $(REGISTRY)/$(REPOSITORY)/pharos
	docker push $(REGISTRY)/$(REPOSITORY)/pharos:$(REVISION)-$(PUSHBRANCH)
	docker push $(REGISTRY)/$(REPOSITORY)/nginx-proxy-pharos:$(REVISION)-$(PUSHBRANCH)
	# Docker Hub
	#docker login docker.io
	#docker push aptrust/pharos

# Docker release - build, tag and push the container
release: build publish ## Make a release by building and publishing the `{version}` as `latest` tagged containers to Gitlab

push: ## Push the Docker image up to the registry
	docker push  $(REGISTRY)/$(REPOSITORY)/$(TAG)

clean: ## Clean the generated/compiles files
