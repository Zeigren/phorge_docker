# Docker For [Phorge](https://we.phorge.it/)

![Docker Image Size (latest)](https://img.shields.io/docker/image-size/zeigren/phorge/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/zeigren/phorge)

## Tags

- latest
- 1.1.0
- 1.0.0

Tag labels are based on the container image version

## Stack

- PHP 7.4-fpm-alpine
- Caddy
- MariaDB

## Links

### [Docker Hub](https://hub.docker.com/r/zeigren/phorge)

### [ghcr.io](https://ghcr.io/zeigren/phorge_docker)

### [GitHub](https://github.com/Zeigren/phorge_docker)

### [Main Repository](https://phabricator.kairohm.dev/diffusion/53/)

## Usage

Use [Docker Compose](https://docs.docker.com/compose/) or [Docker Swarm](https://docs.docker.com/engine/swarm/) to deploy. There are examples for using Caddy or Traefik for HTTPS.

## Configuration

Configuration consists of setting environment variables in the `.yml` files. More environment variables for configuring Phorge and PHP can be found in `docker-entrypoint.sh` and for Caddy in `phorge_caddyfile`.

Setting the `DOMAIN` variable changes whether Caddy uses HTTP, HTTPS with a self signed certificate, or HTTPS with a certificate from Let's Encrypt or ZeroSSL.

`phorge_mailers.json` is a simple template for configuring an [email provider](https://we.phorge.it/book/phabricator/article/configuring_outbound_email/) if you're using one.

On first start you'll need to add an [authentication provider](https://we.phorge.it/book/phabricator/article/configuring_accounts_and_registration/), otherwise you won't be able to login or create new users. If you don't have mail setup you can connect to the Phorge container and use `/var/www/html/phorge/bin/auth recover <username>` to get a recovery link.

### [Docker Swarm](https://docs.docker.com/engine/swarm/)

I personally use this with [Traefik](https://traefik.io/) as a reverse proxy, I've included an example `traefik.yml` but it's not necessary.

You'll need to create the appropriate [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) and [Docker Configs](https://docs.docker.com/engine/swarm/configs/).

Run with `docker stack deploy --compose-file docker-swarm.yml phorge`

### [Docker Compose](https://docs.docker.com/compose/)

Run with `docker-compose up -d`. View using `127.0.0.1:9080`.
