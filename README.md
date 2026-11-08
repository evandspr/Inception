*This project has been created as part of the 42 curriculum by edesprez.*

# Inception

## Description

Inception is a system administration project: it sets up a small web infrastructure
made of three services, each running in its own Docker container, all built from
custom Dockerfiles based on **Debian 12 (bookworm)**, the penultimate stable Debian release.

| Service     | Role                                                            |
|-------------|-----------------------------------------------------------------|
| `nginx`     | Only entry point, HTTPS on port 443 (TLSv1.2 / TLSv1.3 only)    |
| `wordpress` | WordPress + php-fpm (port 9000, internal only)                  |
| `mariadb`   | Database used by WordPress (port 3306, internal only)           |

```
   Browser ──HTTPS:443──▶ nginx ──FastCGI:9000──▶ wordpress ──SQL:3306──▶ mariadb
                            │                         │                      │
                            └──── wordpress_data ─────┘                mariadb_data
                                     (volume)                            (volume)
```

## Instructions

Prerequisites: a Linux VM with Docker, Docker Compose and `make`.

```sh
# 1. Point the domain to the local machine
echo "127.0.0.1 edesprez.42.fr" | sudo tee -a /etc/hosts

# 2. Create the secrets (not stored in git), see DEV_DOC.md
# 3. Build and start everything
make
```

Then open <https://edesprez.42.fr> (accept the self-signed certificate warning).

Useful targets: `make down`, `make stop`, `make start`, `make logs`, `make ps`,
`make clean` (containers, images, volumes), `make fclean` (also deletes the data on disk), `make re`.

More details: [USER_DOC.md](USER_DOC.md) and [DEV_DOC.md](DEV_DOC.md).

## Project description

### Use of Docker and sources

Each service has its own folder in `srcs/requirements/` containing:
- a `Dockerfile` that installs the service on `debian:bookworm`;
- a `conf/` folder with its configuration file;
- a `tools/` folder with its entrypoint script.

`srcs/docker-compose.yml` describes the three services, the network, the two volumes and
the secrets. The root `Makefile` calls Docker Compose to build and run everything.

Main design choices:
- **No ready-made images**: only `debian:bookworm` is pulled; every image is built locally
  and tagged `<service>:inception` (the `latest` tag is never used).
- **PID 1**: each entrypoint script performs the first-run setup, then uses `exec` so that
  the real service (`mariadbd`, `php-fpm8.2 -F`, `nginx -g 'daemon off;'`) replaces the
  script and runs in the foreground as PID 1. No `tail -f`, `sleep infinity` or `while true`.
- **Idempotent setup**: the database and WordPress are only installed if the volumes are empty,
  so data survives restarts and rebuilds.
- **Restart policy**: `restart: always` restarts a container if it crashes.

### Virtual Machines vs Docker

A virtual machine emulates a full computer with its own kernel, which makes it heavy
(gigabytes, slow boot). A Docker container shares the host kernel and only isolates
processes (namespaces) and resources (cgroups): it is much lighter and starts in seconds,
but offers weaker isolation than a VM.

### Secrets vs Environment Variables

Environment variables (`srcs/.env`) hold non-sensitive configuration (domain name,
database name, usernames). They are visible with `docker inspect` and inherited by every
process. Docker secrets hold passwords: they are files mounted read-only in
`/run/secrets/` only in the containers that need them, and the `secrets/` folder is
ignored by git.

### Docker Network vs Host Network

With `network: host`, a container uses the host's network directly: no isolation, and
every port it opens is exposed on the host. With a dedicated bridge network (`inception`),
containers are isolated, reach each other by service name (`mariadb`, `wordpress`) thanks
to Docker's internal DNS, and only port 443 of nginx is published to the host.

### Docker Volumes vs Bind Mounts

A bind mount maps any host path into a container and depends on the host's directory
layout. A named volume is managed by Docker (`docker volume ls`, `inspect`, lifecycle tied
to Compose). Here, the two named volumes `mariadb_data` and `wordpress_data` use the local
driver configured to store their data in `/home/edesprez/data`, as required by the subject.

## Resources

- Docker documentation: <https://docs.docker.com/>
- Docker Compose file reference: <https://docs.docker.com/compose/compose-file/>
- Dockerfile best practices: <https://docs.docker.com/build/building/best-practices/>
- Docker secrets in Compose: <https://docs.docker.com/compose/how-tos/use-secrets/>
- NGINX documentation: <https://nginx.org/en/docs/>
- MariaDB documentation: <https://mariadb.com/kb/en/documentation/>
- WP-CLI commands: <https://developer.wordpress.org/cli/commands/>
- PHP-FPM configuration: <https://www.php.net/manual/en/install.fpm.configuration.php>

### Use of AI

Some questions and searching of documentation.
