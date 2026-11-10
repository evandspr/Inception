#!/bin/sh
set -e

# Mots de passe depuis les secrets Docker
DB_PASSWORD=$(cat /run/secrets/db_password)
# credentials contient WP_ADMIN_PASSWORD=... et WP_USER_PASSWORD=...
. /run/secrets/credentials

# On attend que MariaDB accepte les connexions (60 essais max)
i=0
until mariadb-admin ping -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" --silent 2> /dev/null; do
	i=$((i + 1))
	if [ "$i" -ge 60 ]; then
		echo "[wordpress] MariaDB injoignable" >&2
		exit 1
	fi
	echo "[wordpress] En attente de MariaDB..."
	sleep 1
done

# 1er lancement uniquement : le volume est vide -> on installe WordPress
if [ ! -f /var/www/html/wp-config.php ]; then
	echo "[wordpress] Installation de WordPress..."

	wp core download --allow-root

	wp config create --allow-root \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${DB_PASSWORD}" \
		--dbhost=mariadb:3306

	wp core install --allow-root \
		--url="https://${DOMAIN_NAME}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email

	wp user create --allow-root \
		"${WP_USER}" "${WP_USER_EMAIL}" \
		--role=author \
		--user_pass="${WP_USER_PASSWORD}"

	# L'URL du site suit l'adresse utilisee par le navigateur (port compris) :
	# si on change le port de nginx (ex: 8443), le site reste accessible
	wp config set WP_HOME --raw --allow-root \
		"isset(\$_SERVER['HTTP_HOST']) ? 'https://' . \$_SERVER['HTTP_HOST'] : 'https://${DOMAIN_NAME}'"
	wp config set WP_SITEURL --raw --allow-root \
		"isset(\$_SERVER['HTTP_HOST']) ? 'https://' . \$_SERVER['HTTP_HOST'] : 'https://${DOMAIN_NAME}'"
fi

chown -R www-data:www-data /var/www/html
mkdir -p /run/php

echo "[wordpress] Demarrage de php-fpm."
# -F : reste au premier plan (pas de daemon) ; exec : devient le PID 1
exec php-fpm8.2 -F
