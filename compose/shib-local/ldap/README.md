LDAP Service
=============

The [LDAP](ldap) service is used to provide a user directory for the Shibboleth IdP. This container uses the [osixia/openldap](https://hub.docker.com/r/osixia/openldap/) image, which has Debian Jessie as its base OS.

The container image is customized to include our [bootstrap](#bootstrap) script, which adds additional schema for the [eduOrg and eduPerson schema](https://spaces.internet2.edu/display/macedir/LDIFs), as well as some user accounts.

Building
---------

There are no special build steps for this container; just use `docker build` or `docker-compose build` if included in a Compose configuration.

Usage
------

To make use of the eduPerson schema it must be added to the LDAP directory at runtime, after the service has been started. This is done by the [bootstrap script](bootstrap.sh) but requires that the files in [etc/ldap/edu](etc/ldap/edu) have been mounted as a volume under `/scr/ldap` in the service configuration:

	volumes:
		- "./etc/ldap/edu/:/src/ldap/edu/:ro"
		- "./etc/ldap/demo-users.ldif.tpl:/src/ldap/users.ldif.tpl:ro"

The [install script](etc/ldap/edu/install.sh) is executed during bootstrap and performs the required steps to install the edu schema into the LDAP directory. The given `users.ldif.tpl` file is filtered to use the environment variables to fill in the domain name etc to use, and then the `ldapadd` command is used to import the user account records from the `users.ldif` file.

Demo Users
-----------

There are 3 demo user accounts, "Alice Arnold", "Bert Bellwether" and "Charlie Cooper".

* Alice has the entitlements of `matlab-user` and `preservation-user`, allowing her to access Archivematica as a normal user.
* Bert has the entitlement `preservation-admin`, allowing him to access Archivematica as an admin user.
* Charlie has the entitlement `matlab-user`, allowing him no access to Archivematica.

See the [LDIF template](etc/ldap/demo-users.ldif.tpl) for details of their credentials.

For these accounts the `eduPersonPrincipalName` (`eppn` for short) gets used as the Archivematica username. This is configurable in the IdP and SP layers, should it need to be changed.

Deployment
-----------

This service is intended primarily for development/internal use. In production, it is expected that a real LDAP or Active Directory service would be used, and the IdP would be configured to use that instead.

Environment Variables
----------------------

The following environment variables are used by this service:

| Variable | Description |
|---|---|
| LDAP_DOMAIN | Name of the domain to be managed by the LDAP service. Default is `example.ac.uk`. |
| LDAP_ORGANISATION | Name of the organisation for the domain being managed by the LDAP service. Default is `Example University`. |
