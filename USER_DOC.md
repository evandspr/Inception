# User documentation

## Services provided

| Service   | What it does                                                   |
|-----------|----------------------------------------------------------------|
| NGINX     | Web server, the only entry point (HTTPS, port 443)             |
| WordPress | The website and its administration panel                       |
| MariaDB   | Database storing the site content (posts, users, settings)     |

## Start and stop

From the root of the repository:

| Command      | Effect                                                          |
|--------------|-----------------------------------------------------------------|
| `make`       | Build the images and start the stack                            |
| `make stop`  | Stop the containers (they can be restarted with `make start`)   |
| `make start` | Restart stopped containers                                      |
| `make down`  | Stop and remove the containers (data is kept)                   |
| `make fclean`| Remove everything, **including the website data**               |

## Access the website

1. Make sure `/etc/hosts` contains: `127.0.0.1 edesprez.42.fr`
2. Website: <https://edesprez.42.fr>
3. Administration panel: <https://edesprez.42.fr/wp-admin>

The certificate is self-signed, so the browser shows a warning: accept it to continue.

## Credentials

Credentials are stored locally in the `secrets/` folder (never in git):

| File                           | Content                                         |
|--------------------------------|-------------------------------------------------|
| `secrets/credentials.txt`      | WordPress admin and user passwords              |
| `secrets/db_password.txt`      | Password of the WordPress database user         |
| `secrets/db_root_password.txt` | Password of the MariaDB root user               |

Usernames are in `srcs/.env` (`WP_ADMIN_USER`, `WP_USER`, `MYSQL_USER`).

## Check that everything works

```sh
make ps                      # the 3 containers must be "Up"
make logs                    # live logs of all services
curl -k https://edesprez.42.fr        # returns the HTML of the site
curl http://edesprez.42.fr            # must FAIL: port 80 is not open
```
