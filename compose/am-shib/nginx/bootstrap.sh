#!/bin/bash

# Copy CA cert into trusted location and update Linux trusted certs registry
mkdir -p /usr/local/share/ca-certificates/${DOMAIN_NAME}/ 
cp -p /secrets/nginx/sp-ca-cert.pem /usr/local/share/ca-certificates/${DOMAIN_NAME}/
update-ca-certificates

# Update Shib SP attrChecker script based on config
cd /etc/shibboleth && ./attrChecker.pl
