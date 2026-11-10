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

	# --bootstrap : execute le SQL puis s'arrete, sans demarrer de serveur
	# (pas de reseau, pas de processus en arriere-plan)
	mariadbd --user=mysql --bootstrap <<EOF
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('${DB_ROOT_PASSWORD}');
FLUSH PRIVILEGES;
EOF
fi

echo "[mariadb] Demarrage."
# exec : mariadbd REMPLACE le script et devient le PID 1 du conteneur
exec mariadbd --user=mysql
