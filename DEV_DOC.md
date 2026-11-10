# Developer documentation

## Set up the environment from scratch

### Prerequisites

A Linux virtual machine with:
- Docker Engine and the Docker Compose plugin (`docker compose version`)
- `make`
- `sudo` rights (used by `make fclean` to delete the data folder)

### Domain name

```sh
echo "127.0.0.1 edesprez.42.fr" | sudo tee -a /etc/hosts
```

### Configuration files

- `srcs/.env`: non-sensitive variables (domain, data path, database name, usernames).
- `secrets/`: passwords, **ignored by git**. Create them before the first launch:

```sh
mkdir -p secrets
echo "<your_db_password>"      > secrets/db_password.txt
echo "<your_root_password>"    > secrets/db_root_password.txt
cat > secrets/credentials.txt << EOF
WP_ADMIN_PASSWORD=<your_admin_password>
WP_USER_PASSWORD=<your_user_password>
EOF
```

`make` refuses to start if one of these files is missing.

## Build and launch

```sh
make        # creates /home/edesprez/data/{mariadb,wordpress}, then docker compose up -d --build
```

The `Makefile` runs `docker compose -f srcs/docker-compose.yml`, which builds the three
images from `srcs/requirements/<service>/Dockerfile` and starts the containers in order
(mariadb → wordpress → nginx).

On the first launch:
1. `mariadb` initialises its data folder, creates the database and the user, then starts.
2. `wordpress` waits for MariaDB, downloads WordPress with WP-CLI, creates `wp-config.php`,
   installs the site and creates the two users, then starts php-fpm.
3. `nginx` generates a self-signed TLS certificate and starts.

## Manage containers and volumes

| Command                                  | Use                                   |
|------------------------------------------|---------------------------------------|
| `make ps` / `docker ps`                  | List running containers               |
| `make logs`                              | Follow the logs                       |
| `docker logs <service>`                  | Logs of one container                 |
| `docker exec -it <service> sh`           | Open a shell inside a container       |
| `docker volume ls` / `docker volume inspect mariadb_data` | Inspect the volumes  |
| `docker network inspect inception`       | Inspect the network                   |
| `make clean`                             | Remove containers, images and volumes |
| `make fclean`                            | `clean` + delete the data on disk     |
| `make re`                                | Rebuild everything from scratch       |

Connect to the database:
```sh
docker exec -it mariadb mariadb -u wpuser -p wordpress
```

## Where the data is stored

| Volume           | Mounted in container          | Stored on the host                |
|------------------|-------------------------------|-----------------------------------|
| `mariadb_data`   | `mariadb:/var/lib/mysql`      | `/home/edesprez/data/mariadb`     |
| `wordpress_data` | `wordpress:/var/www/html`, `nginx:/var/www/html` (read-only) | `/home/edesprez/data/wordpress` |

Because the data lives on the host, it persists when containers are stopped, removed or
rebuilt. The setup scripts detect existing data and skip the installation. Only
`make fclean` deletes it.
