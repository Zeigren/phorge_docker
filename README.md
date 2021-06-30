# Docker For [Phorge](https://we.phorge.it/)

![Docker Image Size (latest)](https://img.shields.io/docker/image-size/zeigren/phorge/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/zeigren/phorge)

## Tags

- latest
- 1.0.0

Tag labels are based on the container image version

## Stack

- PHP 7.4-fpm-alpine
- Nginx Alpine
- MariaDB

## Links

### [Docker Hub](https://hub.docker.com/r/zeigren/phorge)

### [GitHub](https://github.com/Zeigren/phorge_docker)

### [Main Repository](https://phabricator.kairohm.dev/diffusion/53/)

## Usage

Use [Docker Compose](https://docs.docker.com/compose/) or [Docker Swarm](https://docs.docker.com/engine/swarm/) to deploy. There are examples for using NGINX or Traefik for SSL termination, or don't use SSL at all.

## Configuration

Configuration primarily consists of environment variables in the `.yml` and `.conf` files.

- phorge_nginx.conf = NGINX config file (needs to be modified if you're using NGINX for SSL termination or not using HTTPS at all)
- Make whatever changes you need to the appropriate `.yml`. All environment variables for Phorge can be found in `docker-entrypoint.sh`
- phorge_mailers.json = Configure your [email provider](https://we.phorge.it/book/phabricator/article/configuring_outbound_email/) if you're using one

On first start you'll need to add an [authentication provider](https://we.phorge.it/book/phabricator/article/configuring_accounts_and_registration/), otherwise you won't be able to login or create new users. If you don't have mail setup you can connect to the Phorge container and use `/var/www/html/phorge/bin/auth recover <username>` to get a recovery link.

### Using NGINX for SSL Termination

- yourdomain.test.crt = The SSL certificate for your domain (you'll need to create/copy this)
- yourdomain.test.key = The SSL key for your domain (you'll need to create/copy this)

### [Docker Swarm](https://docs.docker.com/engine/swarm/)

I personally use this with [Traefik](https://traefik.io/) as a reverse proxy, I've included an example `traefik.yml` but it's not necessary.

You'll need to create the appropriate [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) and [Docker Configs](https://docs.docker.com/engine/swarm/configs/).

Run with `docker stack deploy --compose-file docker-swarm.yml phorge`

### [Docker Compose](https://docs.docker.com/compose/)

You'll need to create a `config` folder and put `phorge_nginx.conf`,  `phorge_mailers.json`, and `phorge_mariadb.cnf` in it. If you're using NGINX for SSL also put your SSL certificate and SSL key in it.

Run with `docker-compose up -d`. View using `127.0.0.1:9080`.
