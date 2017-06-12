.DEFAULT_GOAL := build

# The directories to use as part of the docker-compose build. May be a list.
COMPOSE_DIRS=dev

BASE_DIR ?= ${CURDIR}

# Do we want to include any shibboleth services?
ifeq ("$(SHIBBOLETH_CONFIG)", "archivematica")
	override COMPOSE_DIRS += am-shib
endif

# Set the docker-compose COMPOSE_FILE env var to include the config from each
# dir in COMPOSE_DIRS
override COMPOSE_FILE ?= $(shell echo \
	"$(foreach DIR, $(COMPOSE_DIRS),${CURDIR}/docker-compose.$(DIR).yml)"\
	| tr ' ' ':')
export COMPOSE_FILE

all: destroy build up bootstrap list

bootstrap:
	$(foreach DIR, $(COMPOSE_DIRS), $(MAKE) -C $(DIR) $@ ;)

build destroy:
	# Process the common shib dir first
	if [ "$(SHIBBOLETH_CONFIG)" != "" ] ; then \
		$(MAKE) -C shib $@ ; \
	fi
	# Process each of the relevant compose dirs
	$(foreach DIR, $(COMPOSE_DIRS), $(MAKE) -C $(DIR) $@ ;)
	@sleep 10

config:
	$(foreach DIR, $(COMPOSE_DIRS), $(MAKE) -C $(DIR) $@ ;)
	@sleep 10

list:
	docker-compose ps

up:
	docker-compose up -d

watch:
	docker-compose logs -f

watch-idp:
	docker-compose logs -f idp

watch-nginx:
	docker-compose logs -f nginx

.PHONY: all bootstrap build config destroy list watch watch-idp up
