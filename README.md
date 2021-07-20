# Docker For [Phorge](https://we.phorge.it/)

![Docker Image Size (latest)](https://img.shields.io/docker/image-size/zeigren/phorge/latest)
![Docker Pulls](https://img.shields.io/docker/pulls/zeigren/phorge)

## Links

### [Docker Hub](https://hub.docker.com/r/zeigren/phorge)

### [ghcr.io](https://ghcr.io/zeigren/phorge_docker)

### [GitHub](https://github.com/Zeigren/phorge_docker)

### [Main Repository](https://phabricator.kairohm.dev/diffusion/53/)

## Tags

- latest
- 1.1.0
- 1.0.0

Tag labels are based on the container image version and are entirely arbitrary

## Stack

- PHP 7.4-fpm-alpine - Phorge
- Caddy or NGINX - web server
- MariaDB - database

## Usage

Use [Docker Compose](https://docs.docker.com/compose/) or [Docker Swarm](https://docs.docker.com/engine/swarm/) to deploy. Containers are available from both Docker Hub and the GitHub Container Registry.

There are examples for using either [Caddy](https://caddyserver.com/) or [NGINX](https://www.nginx.com/) as the web server and examples for using Caddy, NGINX, or [Traefik](https://traefik.io/traefik/) for HTTPS (the Traefik example also includes using it as a reverse proxy). The NGINX examples are in the nginx folder.

## Recommendations

I recommend using Caddy as the web server and either have it handle HTTPS or pair it with Traefik as they both have native [ACME](https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment) support for automatically getting HTTPS certificates from [Let's Encrypt](https://letsencrypt.org/) or will create self signed certificates for local use.

If you can I also recommend using [Docker Swarm](https://docs.docker.com/engine/swarm/) over [Docker Compose](https://docs.docker.com/compose/) as it supports [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) and [Docker Configs](https://docs.docker.com/engine/swarm/configs/).

If Caddy doesn't work for you or you are chasing performance then checkout the NGINX examples. I haven't done any performance testing but NGINX has a lot of configurability which may let you squeeze out better performance if you have a lot of users, also check the performance section below.

## Configuration

Configuration consists of setting environment variables in the `.yml` files. More environment variables for configuring Phorge and PHP can be found in `docker-entrypoint.sh` and for Caddy in `phorge_caddyfile`.

Setting the `DOMAIN` variable changes whether Caddy uses HTTP, HTTPS with a self signed certificate, or HTTPS with a certificate from Let's Encrypt or ZeroSSL. Check the Caddy [documentation](https://caddyserver.com/docs/automatic-https) for more info.

`phorge_mailers.json` is a simple template for configuring an [email provider](https://we.phorge.it/book/phabricator/article/configuring_outbound_email/) if you're using one.

On first start you'll need to add an [authentication provider](https://we.phorge.it/book/phabricator/article/configuring_accounts_and_registration/), otherwise you won't be able to login or create new users. If you don't have mail setup you can connect to the Phorge container and use `/var/www/html/phorge/bin/auth recover <username>` to get a recovery link.

### [Docker Swarm](https://docs.docker.com/engine/swarm/)

I personally use this with [Traefik](https://traefik.io/) as a reverse proxy, I've included an example `traefik.yml` but it's not necessary.

You'll need to create the appropriate [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/) and [Docker Configs](https://docs.docker.com/engine/swarm/configs/).

Run with `docker stack deploy --compose-file docker-swarm.yml phorge`

### [Docker Compose](https://docs.docker.com/compose/)

Run with `docker-compose up -d`. View using `127.0.0.1:9080`.

### Performance Tuning

By default I set PHP to scale up child processes based on demand, this is great for a low resource and light usage environment but setting this to be dynamic or static will yield better performance. Check the PHP Configuration section in `docker-entrypoint.sh` for some tuning options to set and/or research.
