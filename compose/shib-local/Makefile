.DEFAULT_GOAL := build

BASE_DIR ?= ${CURDIR}

DOMAIN_NAME ?= example.ac.uk

all: destroy init-ca build create-secrets up bootstrap list

build: build-idp
	COMPOSE_FILE=$(DEFAULT_COMPOSE_FILE) docker-compose build

build-idp:
	@mkdir -p "$(BASE_DIR)/build/idp/"
	# Generate IdP metadata-providers.xml
	@docker run --rm \
		--volume "$(BASE_DIR)/idp-metadata-providers.py:/src/idp-metadata-providers.py:ro" \
		--volume "$(BASE_DIR)/etc/idp/:/src/etc/:ro" \
		--volume "$(BASE_DIR)/build/idp/:/build" \
		--workdir "/src" \
		python:2-alpine \
		python idp-metadata-providers.py /src/etc/service-providers.json > \
			"$(BASE_DIR)/build/idp/metadata-providers.xml"
	# Create base IdP configuration
	@docker run --rm \
		-h idp.$(DOMAIN_NAME) \
		--volume "$(BASE_DIR)/idp/bin:/setup/bin:ro" \
		--volume "$(BASE_DIR)/etc/idp:/setup/conf:ro" \
		--volume "$(BASE_DIR)/build/idp/:/ext-mount" \
		-e DOMAIN_NAME=$(DOMAIN_NAME) \
		-e IDP_OWNER_UID=$(shell id -u) \
		-e IDP_OWNER_GID=$(shell id -g) \
		unicon/shibboleth-idp /setup/bin/init-idp.sh
	# Copy IdP dockerfile to build dir as part of its container context
	@cp -p $(BASE_DIR)/idp/Dockerfile $(BASE_DIR)/build/idp/

# This is needed by upstream makefile
bootstrap:

create-secrets:
	# Create keys and certs for the IdP service
	@mkdir -p "$(BASE_DIR)/build/secrets/idp"
	@docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		--volume "$(BASE_DIR)/../shib/ca/:/src/ca" \
		--volume "$(BASE_DIR)/idp/:/src/idp:ro" \
		--volume "$(BASE_DIR)/build/secrets/idp:/build" \
		--env DOMAIN_NAME="$(DOMAIN_NAME)" \
		--workdir "/src/idp" \
		rawmind/alpine-base:3.5-1 \
		./create-secrets.sh

destroy:
	@mkdir -p "$(BASE_DIR)/build/idp/"
	# Stop containers and remove volumes
	COMPOSE_FILE=$(COMPOSE_FILE) docker-compose down --volumes

init-ca:
	[ -f $(BASE_DIR)/ca/domains/${DOMAIN_NAME}/certs/${DOMAIN_NAME}-ca.crt ] || \
		(cd $(BASE_DIR)/ca && ./init.sh)

nuke-ca:
	# Nuke the Certificate Authority (not necessary for every rebuild)
	cd $(BASE_DIR)/ca && ./nuke.sh && cd $(BASE_DIR)

.PHONY: all bootstrap build destroy init-ca nuke-ca
