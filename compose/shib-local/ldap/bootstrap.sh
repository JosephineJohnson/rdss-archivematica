#!/bin/bash

LDAP_DOMAIN=${LDAP_DOMAIN:-"example.ac.uk"}
LDAP_BASEDN="$(echo -n DC=${LDAP_DOMAIN} | sed 's#[.]#,DC=#g')"

# Install LDAP edu schema
/src/ldap/edu/install.sh

# Update LDAP users template with current base DN and domain name
sed "s/[\$]{LDAP_BASEDN}/${LDAP_BASEDN}/g" /src/ldap/users.ldif.tpl | \
	sed "s/[\$]{LDAP_DOMAIN}/${LDAP_DOMAIN}/g" > /tmp/users.ldif

# Install LDAP users
ldapadd -D "cn=admin,${LDAP_BASEDN}" -w admin -f "/tmp/users.ldif"
