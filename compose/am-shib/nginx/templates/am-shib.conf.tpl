#
# Archivematica Dashboard
#
server {
	listen ${AM_DASHBOARD_EXTERNAL_PORT:-443} default ssl;
	client_max_body_size 256M;

	# Include common Archivematica SSL and Shibboleth configuration
	include /etc/nginx/conf.d/am-shib.inc;

	# FastCGI authorizer for Auth Request module
	location = /shibauthorizer {
		internal;
		include fastcgi_params;
		include shib_fastcgi_params;
		fastcgi_param  HTTPS on;
		fastcgi_param  SERVER_PORT ${AM_DASHBOARD_EXTERNAL_PORT:-443};
		fastcgi_param  SERVER_PROTOCOL https;
		fastcgi_param  X_FORWARDED_PROTO https;
		fastcgi_param  X_FORWARDED_PORT ${AM_DASHBOARD_EXTERNAL_PORT:-443};
		fastcgi_pass unix:/tmp/am-dashboard-shibauthorizer.sock;
	}
	
	# FastCGI responder
	location /Shibboleth.sso {
		include fastcgi_params;
		fastcgi_param  HTTPS on;
		fastcgi_param  SERVER_PORT ${AM_DASHBOARD_EXTERNAL_PORT:-443};
		fastcgi_param  SERVER_PROTOCOL https;
		fastcgi_param  X_FORWARDED_PROTO https;
		fastcgi_param  X_FORWARDED_PORT ${AM_DASHBOARD_EXTERNAL_PORT:-443};
		fastcgi_pass unix:/tmp/am-dashboard-shibresponder.sock;
	}

	# server_name is important as it is used by Shibboleth for generating SAML URLs
	# Using the catch-all '_' will NOT work.
	server_name ${NGINX_HOSTNAME:-archivematica.example.ac.uk};

	# By default, all Dashboard resources are Shibboleth protected. Exceptions to
	# this are /api and /media, which are covered by the next location rule.
	location / {
		set $upstream_endpoint http://archivematica-dashboard:8000;
		
		# Enforce authentication using Shibboleth
		include shib_clear_headers;
		more_clear_input_headers 'displayName' 'mail' 'persistent-id';
		shib_request /shibauthorizer;
		
		# Configure proxy
		proxy_set_header Host $http_host;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X_Forwarded-Proto https;
		proxy_redirect off;
		proxy_buffering off;
		proxy_read_timeout 172800s;
		proxy_pass $upstream_endpoint;
	}

	# Exclude /api and /media resources from Shibboleth protection.
	location ~* /(api|media)/ {
		set $upstream_endpoint http://archivematica-dashboard:8000;
		# Configure proxy
		proxy_set_header Host $http_host;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X_Forwarded-Proto https;
		proxy_redirect off;
		proxy_buffering off;
		proxy_read_timeout 172800s;
		proxy_pass $upstream_endpoint;
	}
}

#
# Archivematica Storage Service
#
server {
	listen ${AM_STORAGE_SERVICE_EXTERNAL_PORT:-8443} default ssl;
	client_max_body_size 256M;

	# Include common Archivematica SSL and Shibboleth configuration
	include /etc/nginx/conf.d/am-shib.inc;
	
	# FastCGI authorizer for Auth Request module
	location = /shibauthorizer {
		internal;
		include fastcgi_params;
		include shib_fastcgi_params;
		fastcgi_param  HTTPS on;
		fastcgi_param  SERVER_PORT ${AM_STORAGE_SERVICE_EXTERNAL_PORT:-8443};
		fastcgi_param  SERVER_PROTOCOL https;
		fastcgi_param  X_FORWARDED_PROTO https;
		fastcgi_param  X_FORWARDED_PORT ${AM_STORAGE_SERVICE_EXTERNAL_PORT:-8443};
		fastcgi_pass unix:/tmp/am-storage-service-shibauthorizer.sock;
	}
	
	# FastCGI responder
	location /Shibboleth.sso {
		include fastcgi_params;
		fastcgi_param  HTTPS on;
		fastcgi_param  SERVER_PORT ${AM_STORAGE_SERVICE_EXTERNAL_PORT:-8443};
		fastcgi_param  SERVER_PROTOCOL https;
		fastcgi_param  X_FORWARDED_PROTO https;
		fastcgi_param  X_FORWARDED_PORT ${AM_STORAGE_SERVICE_EXTERNAL_PORT:-8443};
		fastcgi_pass unix:/tmp/am-storage-service-shibresponder.sock;
	}

	# server_name is important as it is used by Shibboleth for generating SAML URLs
	# Using the catch-all '_' will NOT work.
	server_name ${NGINX_HOSTNAME:-archivematica.example.ac.uk};

	# By default, all Storage Service resources are protected. Exceptions to
	# this are /api and /static, which are covered by the next location rule.
	location / {
		set $upstream_endpoint http://archivematica-storage-service:8000;
		
		# Enforce authentication using Shibboleth
		include shib_clear_headers;
		more_clear_input_headers 'displayName' 'mail' 'persistent-id';
		shib_request /shibauthorizer;
		
		# Configure proxy
		proxy_set_header Host $http_host;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X_Forwarded-Proto https;
		proxy_redirect off;
		proxy_buffering off;
		proxy_read_timeout 172800s;
		proxy_pass $upstream_endpoint;
	}

	# Exclude /api and /static resources from Shibboleth protection.
	location ~* /(api|static)/ {
		set $upstream_endpoint http://archivematica-storage-service:8000;
		# Configure proxy
		proxy_set_header Host $http_host;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header X_Forwarded-Proto https;
		proxy_redirect off;
		proxy_buffering off;
		proxy_read_timeout 172800s;
		proxy_pass $upstream_endpoint;
	}
}
