#!/bin/bash

ZULU_HOME=/opt/zulu8.20.0.5-jdk8.0.121-linux_x64

if [ -s /usr/share/pki/ca-trust-source/anchors/${DOMAIN_NAME}-ca.crt ] ; then
	exit
fi

# Copy CA cert into trusted location and update Linux trusted certs registry
cp -p /secrets/${DOMAIN_NAME}-ca.crt /usr/share/pki/ca-trust-source/anchors/ && update-ca-trust
# Also update JRE trusted certs so Tomcat trusts it too
chmod +x ${ZULU_HOME}/bin/keytool
sleep 5
${ZULU_HOME}/bin/keytool -import -noprompt -trustcacerts -alias ${DOMAIN_NAME} \
	-file /secrets/${DOMAIN_NAME}-ca.crt \
	-keystore  /opt/zulu8.20.0.5-jdk8.0.121-linux_x64/jre/lib/security/cacerts \
	-storepass changeit
