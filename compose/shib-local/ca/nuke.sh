#!/bin/bash

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}
DOMAIN_DIR=domains/${DOMAIN_NAME}

# Remove all generated files from the CA directory
rm -Rfv ${DOMAIN_DIR}
