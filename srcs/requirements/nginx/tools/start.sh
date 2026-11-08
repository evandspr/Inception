#!/bin/sh
set -e

# Certificat TLS auto-signe, genere une seule fois
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
	echo "[nginx] Generation du certificat TLS..."
	mkdir -p /etc/nginx/ssl
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout /etc/nginx/ssl/inception.key \
		-out /etc/nginx/ssl/inception.crt \
		-subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}" 2> /dev/null
fi

# On remplace DOMAIN_NAME dans la config par la valeur du .env
sed "s/DOMAIN_NAME/${DOMAIN_NAME}/g" \
	/etc/nginx/conf.d/inception.conf.template > /etc/nginx/conf.d/inception.conf

echo "[nginx] Demarrage."
# daemon off : nginx reste au premier plan ; exec : devient le PID 1
exec nginx -g 'daemon off;'
