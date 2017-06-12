Shibboleth-enabled Archivematica: Nginx Service
================================================

The Shibboleth Nginx service runs the [nginx](https://www.nginx.com) web server with the [nginx-shibboleth module](https://github.com/nginx-shib/nginx-http-shibboleth) enabled. In addition, it runs the [Shibboleth FastCGI SP](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPFastCGIConfig) application, which `nginx` communicates with via UNIX sockets, as well as [supervisord](http://supervisord.org/) to run the Shibboleth components as daemons (in the absence of `systemd` in a Docker container).

It provides two templated files: the [template nginx config file](etc/nginx/conf.d/example.conf.tpl) and the [template Shibboleth config file](etc/shibboleth/shibboleth2.xml.tpl). The [build script](build.sh) provides these, along with the required private key and certificates signed by the [domain CA](../shib/ca).

The nginx service hosts two virtual servers, one for the Archivematica Dashboard on port 443, and one for the Archivematica Storage Service on port 8443. Each server is configured with the required Shibboleth locations, as well as the `/` location, which is secured by Shibboleth. Some resources, such as `/api` and static media are not secured, because they don't need to be.

By default the nginx service is configured to be available at `https://archivematica.example.ac.uk/`.

Docker Image
-------------

The docker image for this service is based on [virtualstaticvoid/shibboleth-nginx](https://hub.docker.com/r/virtualstaticvoid/shibboleth-nginx/) image, which in turn has Debian Wheezy as its base OS.


### Arguments

The [Dockerfile](Dockerfile) used to build the image takes a number of arguments.

| Argument | Description |
|---|---|
| DOMAIN_NAME | The domain that the service is part of, e.g. `example.com`. |
| NGINX_CONF_TEMPLATE_FILE | Path of the nginx config template file, which will be used to create `/etc/nginx/conf.d/default.conf`. This is specifically concerned with Shibboleth-enabled services, not anything else that may be hosted by `nginx`. |
| SHIBBOLETH_ATTRCHECKER_TEMPLATE_FILE | Path of the Shibboleth 'attrChecker' template file, which will be used to update `/etc/shibboleth/attrChecker.html`. |
| SHIBBOLETH_CONF_TEMPLATE_FILE | Path of the Shibboleth config template file, which will be used to create `/etc/shibboleth/shibboleth2.xml`. |

All of the above arguments are required; there are no defaults.

Building
---------

This container is built by the [parent Makefile](../Makefile).

Template Files
---------------

This service makes use of two templated configuration files, neither of which aren't included in this base configuration. These are referenced by arguments to the Dockerfile, as follows:

| Template File Variable | Description |
|---|---|
| NGINX_CONFIG_TEMPLATE_FILE | Provides the template for the `/etc/nginx/conf.d/default.conf` file. This is expected to include configuration for interfacing with the SP FastCGI module, as well as defining which locations are protected by Shibboleth in their configuration. |
| SHIBBOLETH_ATTRCHECKER_TEMPLATE_FILE | Provides the template for the `/etc/shibboleth/attrChecker.html` file. See [attrChecker](#attrchecker) below for more information. |
| SHIBBOLETH_CONFIG_TEMPLATE_FILE | Provides the template for the `/etc/shibboleth/shibboleth2.xml` file. This configures how the SP functions; see the [SP configuration documentation](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPConfiguration) for full details of what can be in this configuration file.

Both of these templates are interpreted using [envplate](https://github.com/kreuzwerker/envplate) at instantiation time, since `envplate` is used as the `ENTRYPOINT` for the parent `virtualstaticvoid/shibboleth-nginx` image.

Configuration
--------------

The files in [etc](etc) configure this service, and are as follows:

* `nginx/shib_clear_headers` clears HTTP headers related to Shibboleth, to avoid spoofing etc
* `nginx/shib_fastcgi_params` defines a number of FastCGI parameters specific to Shibboleth
* `shibboleth/attrChecker.html` provides a diagnostics page for checking attributes sent by an IdP for an authenticated user (see [Diagnostics](#diagnostics), below).
* `shibboleth/attrChecker.pl` may be used to update `attrChecker.html` based on the SP's metadata.
* `shibboleth/console.logger` configures logging for the Shibboleth SP console tools (see [Diagnostics](#diagnostics), below).
* `shibboleth/security-policy.xml` overrides the default security policy in terms of trusting signatures etc. See [Security Policies](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPSecurityPolicies) documentation for more on this.
* `shibboleth/shibd.logger` configures logging for the Shibd daemon process, which responds to the FastCGI calls. This configuration causes all logging to go to `stdout` and `stderr`, so that `docker logs` can pick them up.

Because there are two applications, there needs to be two FastCGI handlers too. This requires a change to the [Supervisor configuration](etc/supervisor/conf.d/shibboleth.conf), to add the additional handler.

The Archivematica Shibboleth configuration has been tuned to work with the eduPerson schema, which is what the [attribute map](etc/shibboleth/attribute-map.xml) does. The [shibboleth2.xml](etc/shibboleth/shibboleth2.xml.tpl) includes access control elements that restrict access to the Dashboard and Storage Service based on a user's entitlements (derived from the `eduPersonEntitlement` attribute in LDAP). The Dashboard and the Storage Service are treated as two seperate applications, each with their own `entityID`.

Diagnostics
------------

To aid diagnostics, a number of tools are included in the Shibboleth SP installation in this container. These are standard tools, publicly available, that are either installed by default or that have been included specifically.

The notes here are intended to give an overview of each tool, and also to raise awareness that they even exist, since their documentation is buried deep in the official Shibboleth documentation. Hopefully this knowledge will save a lot of time and frustration when working with Shibboleth and its configuration!

### AttrChecker

the [attrChecker]() is included as an additional page that intercepts requests if they don't have a required list of attributes being sent from the IdP. This is useful to ensure that the SP is configured correctly, and also that the IdP is sending the necessary parameters.

The intercept is dependent on the concrete service including the following `sessionHook` and `Handler` in its configuration:

	<ApplicationDefaults sessionHook="/Shibboleth.sso/AttrChecker" ... >
		<Sessions>
			<Handler type="AttributeChecker" Location="/AttrChecker" attributes="cn entitlement eppn givenName mail sn" template="attrChecker.html" flushSession="true" showAttributeValues="true"/>
			...
		</Sessions>
		...
	</ApplicationDefaults>

The `attributes` attribute of the `Handler` element should be updated to match the list of attributes the SP requires from IdPs for the application to function.

### MDQuery

The `mdquery` tool allows the configuration for metadata in the SP to be checked. Its full documentation is [here](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPmdquery).

As an example, here's how you might check the IdP metadata for the SAML2 protocol:

	mdquery -e https://idp.example.ac.uk/idp/shibboleth -saml2 -idp

When using this tool, extra log output can be obtained by modifying the `console.logger` config file to set the log level to `DEBUG`.

### ResolverTest

The `resovlvertest` tool can be used to test what attributes the SP receives from the IdP and what survive the various filters etc. Its full documentation is [here](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPresolvertest).

As an example, here's how you might check what happens when the SP tries to resolve the attributes for the user `aa` for the `archivematica-dashboard` application:

	resolvertest -a archivematica-dashboard -i https://idp.example.ac.uk/idp/shibboleth -saml2 -n aa@example.ac.uk

As with `mdquery`, the `console.logger` configuration file can be used to increase the logging level to offer more information for diagnostics.

### Shibd

This isn't really a tool as such. The `shibd` executable is intended to be run as a daemon, but it can also be used to test the validity of the `shibboleth2.xml` configuration file. Its full documentation is [here](https://wiki.shibboleth.net/confluence/display/SHIB2/NativeSPshibd).

For example:

	shibd -t

This starts the `shibd` service in the foreground, loads its configuration, and then shuts the service down again and exits. If you need to increase the log level for this, use the `shibd.logger` configuration file.
