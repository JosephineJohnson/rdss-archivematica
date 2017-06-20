RANDFILE         = /dev/urandom

[ ca ]
default_ca       = CA_default

[ CA_default ]
dir              = ${DOMAIN_DIR}
certs            = $dir/certs
new_certs_dir    = $dir/newcerts
crl_dir          = $dir/crl
database         = $dir/db/index.txt
private_key      = $dir/private/${CA_NAME}.key
certificate      = $dir/certs/${CA_NAME}.crt
serial           = $dir/db/serial
crl              = $dir/crl.pem
RANDFILE         = $dir/private/.rand
default_days     = 3652
default_crl_days = 30
default_md       = sha512
preserve         = no
policy           = policy_anything
name_opt         = ca_default
cert_opt         = ca_default
unique_subject   = no
copy_extensions  = copy

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits            = 1024
default_md              = sha512
default_keyfile         = privkey.pem
distinguished_name      = req_distinguished_name
x509_extensions         = v3_ca
string_mask             = nombstr

[ req_distinguished_name ]
countryName             = Country Name (2 letter code)
countryName_min         = 2
countryName_max         = 2
stateOrProvinceName     = State or Province Name (full name)
localityName            = Locality Name (eg, city)
0.organizationName      = Organization Name (eg, company)
organizationalUnitName  = Organizational Unit Name (eg, section)
commonName              = Common Name (eg, YOUR name)
commonName_max          = 64
emailAddress            = Email Address
emailAddress_max        = 64

[ v3_ext ]
authorityKeyIdentifier  = keyid,issuer
basicConstraints        = CA:FALSE
keyUsage                = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage         = nonRepudiation, digitalSignature, keyEncipherment

[ v3_ca ]
basicConstraints        = critical, CA:true, pathlen:0
nsCertType              = sslCA
keyUsage                = cRLSign, keyCertSign
extendedKeyUsage        = serverAuth, clientAuth
nsComment               = "OpenSSL CA Certificate"

[ crl_ext ]
basicConstraints        = CA:FALSE
keyUsage                = digitalSignature, keyEncipherment
nsComment               = "OpenSSL generated CRL"

