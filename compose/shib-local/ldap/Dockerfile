FROM osixia/openldap

MAINTAINER Arkivum Limited

# Copy the bootstrap script to a location where the Osixia container set up will
# find it
COPY bootstrap.sh /container/service/ldap-bootstrap/process.sh

# Install the 'runit' tool because Osixia requires it for multi-service image
RUN apt-get -y update && /container/tool/add-service-available :runit
