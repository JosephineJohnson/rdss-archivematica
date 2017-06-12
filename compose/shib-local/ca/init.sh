#!/bin/bash

DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}
DOMAIN_ORGANISATION=${DOMAIN_ORGANISATION:-"Example University"}

DOMAIN_DIR=domains/${DOMAIN_NAME}

CA_NAME=${DOMAIN_NAME}-ca

CA_COMMONNAME="${DOMAIN_ORGANISATION} CA"
CA_ORGANIZATION="${DOMAIN_ORGANISATION}"
CA_CITY="London"
CA_STATE="London"
CA_COUNTRY="GB"
CA_EMAIL="admin@${DOMAIN_NAME}"

CA_CONFIG=${DOMAIN_DIR}/${CA_NAME}.conf

mkdir -p ${DOMAIN_DIR}/{certs,db,export,newcerts,private}

# Use the CA config template to create the concrete CA config
sed "s/[\$]{CA_NAME}/$CA_NAME/" ca.conf.tpl | \
    sed "s#[\$]{DOMAIN_DIR}#${DOMAIN_DIR}#" > $CA_CONFIG

# Create the required CA database files
if [ ! -f "${DOMAIN_DIR}/db/index.txt" ] ; then
    touch ${DOMAIN_DIR}/db/index.txt
fi
if [ ! -f "${DOMAIN_DIR}/db/serial" ] ; then
    date "+%Y%m%d%k%M%S01" > ${DOMAIN_DIR}/db/serial
fi

if [ ! -f "${DOMAIN_DIR}/db/crlnumber" ] ; then
    echo "01" > ${DOMAIN_DIR}/db/crlnumber
fi

# Generate a passphrase
passwd="$(dd if=/dev/urandom ibs=1024 count=1 >/dev/null 2>&1 | openssl passwd stdin)"
if [ ! -f "${DOMAIN_DIR}/private/$CA_NAME.key.passphrase" ] ; then
    echo "$passwd" > ${DOMAIN_DIR}/private/$CA_NAME.key.passphrase
else
    passwd="$(cat ${DOMAIN_DIR}/private/$CA_NAME.key.passphrase)"
fi

# Create the CA private key
if [ ! -f "${DOMAIN_DIR}/private/$CA_NAME.key" ] ; then
    openssl genrsa -des3 -passout pass:"$passwd" -out ${DOMAIN_DIR}/private/$CA_NAME.key 4096
fi

# Create the CA public certificate
if [ ! -f "${DOMAIN_DIR}/certs/$CA_NAME.crt" ] ; then
    openssl req -new -x509 -days 3650 \
       -key ${DOMAIN_DIR}/private/$CA_NAME.key \
       -out ${DOMAIN_DIR}/certs/$CA_NAME.crt \
       -config $CA_CONFIG \
       -subj \
          "/CN=$CA_COMMONNAME/O=$CA_ORGANIZATION/L=$CA_CITY/ST=$CA_STATE/C=$CA_COUNTRY/emailAddress=$CA_EMAIL" \
       -passin pass:"$passwd"
fi

# Initialize the CRL
if [ -f "${DOMAIN_DIR}/certs/$CA_NAME.crt" -a -f "${DOMAIN_DIR}/private/$CA_NAME.key" ] ; then
    openssl ca -gencrl \
       -keyfile "${DOMAIN_DIR}/private/$CA_NAME.key" \
       -cert "${DOMAIN_DIR}/certs/$CA_NAME.crt" \
       -out "${DOMAIN_DIR}/certs/$CA_NAME.crl" -config $CA_CONFIG \
       -passin pass:"$passwd"
fi

# Make sure the private directory is private
chmod 700 ${DOMAIN_DIR}/private
chmod 600 ${DOMAIN_DIR}/private/*
