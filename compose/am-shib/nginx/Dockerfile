FROM virtualstaticvoid/shibboleth-nginx

MAINTAINER Arkivum Limited

## Arguments ###################################################################

# Specifies the domain that our image is in, e.g. example.com. Required.
ARG DOMAIN_NAME

# Specifies the path of the nginx config template file. Required.
ARG NGINX_CONF_TEMPLATE_FILE

# Specifies the path of the Shibboleth 'attrChecker' template file. Required.
ARG SHIBBOLETH_ATTRCHECKER_TEMPLATE_FILE

# Specifies the path of the Shibboleth config template file. Required.
ARG SHIBBOLETH_CONF_TEMPLATE_FILE

## Environment variables #######################################################

# Override responder path - for some reason the parent image uses '/saml'
# instead of the official default '/Shibboleth.sso'
ENV SHIBBOLETH_RESPONDER_PATH "/Shibboleth.sso"

## Shibboleth customizations ###################################################

# Redirect Shibboleth logs to stdout and stderr
RUN rm -f /var/log/shibboleth/shibd*.log && \
	ln -s /dev/stdout /var/log/shibboleth/shibd.log && \
	ln -s /dev/stderr /var/log/shibboleth/shibd_warn.log

## Nginx configuration #########################################################

# Ensure the nginx user exists and belongs to the shibd group
RUN useradd -s /bin/nologin nginx && usermod -G _shibd nginx

# Override shibd supervisor config to allow nginx user to access sockets
RUN sed -i 's/socket_mode=0600/socket_mode=0660/' \
	/etc/supervisor/conf.d/shibboleth.conf

## Templates ###################################################################

COPY $NGINX_CONF_TEMPLATE_FILE /etc/nginx/conf.d/am-shib.conf
COPY $SHIBBOLETH_ATTRCHECKER_TEMPLATE_FILE /etc/shibboleth/attrChecker.html
COPY $SHIBBOLETH_CONF_TEMPLATE_FILE /etc/shibboleth/shibboleth2.xml
