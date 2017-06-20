#!/bin/bash

LDAP_DOMAIN=${LDAP_DOMAIN:-"example.ac.uk"}
LDAP_BASEDN="$(echo -n DC=${LDAP_DOMAIN} | sed 's#[.]#,DC=#g')"

SCHEMA_INSTALLED_FILE="${CONTAINER_STATE_DIR}/edu_schema_installed"
USERS_TEMPLATE_MD5_FILE="${CONTAINER_STATE_DIR}/users.ldif.tpl.md5"

# Wait for LDAP server to become ready
echo -n "Waiting for LDAP server: "
while [ "$(ss -tanp | grep LISTEN | grep 389)" == "" ] ; do
	echo -n "."
	sleep 4
done
echo " Done."

# Install LDAP edu schema if not already installed
if [ ! -f "${SCHEMA_INSTALLED_FILE}" ] ; then
	/src/ldap/edu/install.sh && date --utc > "${SCHEMA_INSTALLED_FILE}"
fi

# Check if we need to add/update LDAP users
if [ ! -f "${USERS_TEMPLATE_MD5_FILE}" ] || [ ! md5sum -c "${USERS_TEMPLATE_MD5_FILE}" ; then
	# Input has changed, do add or update
	sed "s/[\$]{LDAP_BASEDN}/${LDAP_BASEDN}/g" /src/ldap/users.ldif.tpl | \
		sed "s/[\$]{LDAP_DOMAIN}/${LDAP_DOMAIN}/g" > /tmp/users.ldif
	ldapadd -D "cn=admin,${LDAP_BASEDN}" -w admin -f "/tmp/users.ldif"
	md5sum /src/ldap/users.ldif.tpl > "${USERS_TEMPLATE_MD5_FILE}"
fi

#
# We run the bootstrap for LDAP as a second service within the container. We
# therefore need to give it something to do (tailing /dev/null) whilst it waits
# for the container to shutdown.
#
trap 'trap - TERM; kill -s TERM -- -$$' TERM
tail -f /dev/null & wait
exit 0
