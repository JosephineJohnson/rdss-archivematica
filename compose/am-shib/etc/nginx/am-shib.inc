
# SSL configuration
ssl_certificate     /secrets/nginx/sp-web-cert.pem;
ssl_certificate_key /secrets/nginx/sp-key.pem;
ssl_protocols       SSLv3 TLSv1 TLSv1.1 TLSv1.2;
ssl_ciphers         HIGH:!aNULL:!MD5;
ssl_session_cache   shared:SSL:10m;
ssl_session_timeout 10m;

# Resources for the Shibboleth error pages. This can be customised.
location /shibboleth-sp {
	alias /etc/shibboleth/;
}