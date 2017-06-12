#!/bin/bash

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}

DOMAIN_DIR=domains/${DOMAIN_NAME}

CA_NAME=${DOMAIN_NAME}-ca

CA_CONFIG=${DOMAIN_DIR}/${CA_NAME}.conf

if [ $# -lt 2 ] ; then
    echo "usage: sign.sh <nodename> <CSR file>"
    exit 1
fi

nodename=$1
node_csr=$2

# Initialise the CA if not already done
if [ ! -d "${DOMAIN_DIR}" ] ; then
	./init.sh
fi

# Sign the given node certificate request
passwd="$(cat ${DOMAIN_DIR}/private/$CA_NAME.key.passphrase)"
certfile=${DOMAIN_DIR}/certs/$nodename.crt
openssl ca -batch -config $CA_CONFIG \
	-policy policy_anything -extensions v3_ext \
	-keyfile ${DOMAIN_DIR}/private/$CA_NAME.key -passin pass:"$passwd" \
	-cert ${DOMAIN_DIR}/certs/$CA_NAME.crt -notext \
	-out $certfile -in $node_csr


