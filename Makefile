#!/bin/bash
# Docker_start.sh
# Script to provision a development environment
# with docker-ce and start pharos in a container as per docker-compose.yml

# 1. ID OS - Linux or OSX
# 2. If OSX, install homebrew
# 3. Install Docker-CE on osx (brew cask install docker/linux: apt-get install docker)
# 4. Run make build to build the latest version of Pharos
# 5. docker-compose up -f docker-compose-dev.yml
# 6. Connect to pharos.docker.localhost in your browser.

# -  make restart: docker-compose up -d -f docker-compose-dev.yml
#

REGISTRY = registry.gitlab.com/aptrust
REPOSITORY = container-registry
NAME=$(shell basename $(CURDIR))
VERSION = latest
TAG = $(NAME):$(VERSION)
REVISION=$(shell git rev-parse --short=2 HEAD)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help build publish

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

revision: ## Show me the git hash
	echo "$(REVISION)"

build: ## Build the Pharos container
	docker build -t aptrust/$(TAG) -t $(TAG) -t $(NAME):$(REVISION) -t $(REGISTRY)/$(REPOSITORY)/$(TAG) .

build-nc: ## Build the Pharos container, no cached layers.
	docker build --no-cache -t aptrust/$(TAG) -t $(TAG) -t $(NAME):$(REVISION) -t $(REGISTRY)/$(REPOSITORY)/$(TAG) .

up: ## Start containers for Pharos, Postgresql, Nginx
	docker-compose up

down: ## Stop containers for Pharos, Postgresql, Nginx
	docker-compose down


run: ## Just run Pharos in foreground
	docker run -p 9292:9292 $(TAG)

runex: ## Start Pharos container, run command and exit.
	docker run $(TAG) $(filter-out $@, $(MAKECMDGOALS))
#	docker exec $(TAG) $(filter-out $@, $(MAKECMDGOALS))

%:
	    @true

tests: ## Run Pharos spec tests
	docker network create -d bridge pharos-test-net > /dev/null 2>&1 || true
	docker start pharos-test-db > /dev/null 2>&1 || docker run -d --network pharos-test-net --hostname pharos-test-db --name pharos-test-db -p 5432:5432 postgres:9.6.6-alpine
	docker run  -e PHAROS_DB_NAME=pharos_test -e PHAROS_DB_HOST=pharos-test-db -e PHAROS_DB_USER=postgres -e PHAROS_DB_HOST=pharos-test-db --network pharos-test-net --rm --name pharos-migration $(TAG) /bin/bash -c "echo 'Init DB setup'; rake db:setup; rake db:migrate; rake pharos:setup"
	docker run --rm -it --network pharos-test-net -e PHAROS_DB_NAME=pharos_test -e PHAROS_DB_HOST=pharos-test-db -e RAILS_ENV=test $(TAG) /bin/bash -c "bin/rake"
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

devstop: ## Stop and remove running Docker containers
	docker stop pharos-dev-db
	docker stop pharos-dev-web

publish:
	docker login $(REGISTRY)
	docker tag aptrust/pharos $(REGISTRY)/$(REPOSITORY)/pharos && \
	docker push $(REGISTRY)/$(REPOSITORY)/pharos
	docker push aptrust/pharos


# Docker release - build, tag and push the container
release: build publish ## Make a release by building and publishing the `{version}` as `latest` tagged containers to Gitlab

push: ## Push the Docker image up to the registry
	docker push  $(REGISTRY)/$(REPOSITORY)/$(TAG)

clean: ## Clean the generated/compiles files
