#!/bin/sh
set -e

# Les mots de passe viennent des secrets Docker (montés dans /run/secrets/)
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# 1er lancement uniquement : le volume est vide -> on cree les tables systeme
if [ ! -d /var/lib/mysql/mysql ]; then
	echo "[mariadb] Initialisation du dossier de donnees..."
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

# 1er lancement uniquement : la base WordPress n'existe pas -> on la cree
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
	echo "[mariadb] Creation de la base et de l'utilisateur..."

	# Serveur temporaire, sans reseau, juste pour executer le SQL
	mariadbd --user=mysql --skip-networking &

	# On attend qu'il reponde (30 essais max : ce n'est pas une boucle infinie)
	i=0
	until mariadb-admin ping --silent; do
		i=$((i + 1))
		if [ "$i" -ge 30 ]; then
			echo "[mariadb] Le serveur temporaire ne demarre pas" >&2
			exit 1
		fi
		sleep 1
	done

	mariadb -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SHUTDOWN;
EOF

	# On attend que le serveur temporaire soit bien arrete
	wait
fi

echo "[mariadb] Demarrage."
# exec : mariadbd REMPLACE le script et devient le PID 1 du conteneur
exec mariadbd --user=mysql
