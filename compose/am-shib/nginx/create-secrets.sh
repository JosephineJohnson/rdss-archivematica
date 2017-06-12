#!/bin/bash

# Can be overridden by environment variables
DOMAIN_NAME=${DOMAIN_NAME:-"example.ac.uk"}
NGINX_HOSTNAME=${NGINX_HOSTNAME:-"archivematica.${DOMAIN_NAME}"}


#
# Globals
#

CA_PEM_CERT="${DOMAIN_NAME}-ca.crt"

NGINX_SHIB_SP_CA_CERT="sp-ca-cert.pem"
NGINX_SHIB_SP_CERT="sp-cert.pem"
NGINX_SHIB_SP_CSR="${NGINX_HOSTNAME}.csr"
NGINX_SHIB_SP_KEY="sp-key.pem"
NGINX_SHIB_SP_WEB_CERT="sp-web-cert.pem"
NGINX_SHIB_SP_WEB_CSR="web.${NGINX_HOSTNAME}.csr"

CA_DIR="/src/ca"
BUILD_DIR="/build"

#
# Helper functions
#

create_key()
{
	local key_out="$1"
	[ -f "$key_out" ] || openssl genrsa -out "$1" 2048
}

# Signs the given CSR with the domain's CA.
create_signed_cert()
{
	local hostname="$1"
	local csr="$2"
	local cert_out="$3"
	
	if [ -f "$cert_out" ] ; then
		return
	fi
	
	pushd "${CA_DIR}"
	local uniq_hostname="${hostname}.$(date +"%Y%m%d%H%M")"
	./sign.sh "${uniq_hostname}" "$csr"
	cp "domains/${DOMAIN_NAME}/certs/${uniq_hostname}.crt" "${cert_out}"
	popd
}

create_sp_csr()
{
	local hostname="$1"
	local key_in="$2"
	local csr_out="$3"
	
	if [ -f "$csr_out" ] ; then
		return
	fi
	
	# Configure our CSR
	cat > /tmp/csr.conf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ dn ]
CN=${hostname}
C=GB
ST=London
L=London
emailAddress=admin@${DOMAIN_NAME}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${hostname}

EOF
	# Generate a CSR for the Shibboleth SP service
	openssl req -nodes -new \
		-config /tmp/csr.conf \
		-passin pass:12345 -passout pass:12345 \
		-key "${key_in}" -out "${csr_out}"
	# Remove temporary CSR config
	rm -f /tmp/csr.conf
}

create_web_csr()
{
	local hostname="$1"
	local key_in="$2"
	local csr_out="$3"
	
	if [ -f "$csr_out" ] ; then
		return
	fi
	
	# Configure our CSR
	cat > /tmp/csr.conf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ dn ]
CN=${hostname}
C=GB
ST=London
L=London
emailAddress=admin@${DOMAIN_NAME}

EOF
	# Generate a CSR for Shibboleth SP web interface (reusing existing key)
	openssl req -nodes -new \
		-config "/tmp/csr.conf" \
		-passin pass:12345 -passout pass:12345 \
		-key "${key_in}" -out "${csr_out}"
	# Remove temporary CSR config
	rm -f /tmp/csr.conf
}

#
# Entry point
#

main()
{
	mkdir -p ${BUILD_DIR}
	# Create private key for Shibboleth SP services
	create_key "${BUILD_DIR}/${NGINX_SHIB_SP_KEY}"
	# Create CSR for Shibboleth SP services
	create_sp_csr "${NGINX_HOSTNAME}" \
		"${BUILD_DIR}/${NGINX_SHIB_SP_KEY}" \
		"${BUILD_DIR}/${NGINX_HOSTNAME}.csr"
	# Sign CSR to create the SP certificate
	create_signed_cert "${NGINX_HOSTNAME}" \
		"${BUILD_DIR}/${NGINX_SHIB_SP_CSR}" \
		"${BUILD_DIR}/${NGINX_SHIB_SP_CERT}"
	# Create CSR for nginx SSL
	create_web_csr "${NGINX_HOSTNAME}" \
		"${BUILD_DIR}/${NGINX_SHIB_SP_KEY}" \
		"${BUILD_DIR}/${NGINX_SHIB_SP_WEB_CSR}"
	# Sign CSR to create the nginx certificate
	create_signed_cert "${NGINX_HOSTNAME}" \
		"${BUILD_DIR}/${NGINX_SHIB_SP_WEB_CSR}" \
		"${BUILD_DIR}/${NGINX_SHIB_SP_WEB_CERT}"
	# Copy CA cert
	cp -p "${CA_DIR}/domains/${DOMAIN_NAME}/certs/${CA_PEM_CERT}" \
		"${BUILD_DIR}/${NGINX_SHIB_SP_CA_CERT}"
}

main