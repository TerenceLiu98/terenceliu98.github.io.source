---
title: "Homelab: My Distributed Homelab"
date: 2022-07-21T00:11:21+08:00
draft: false
tags: ['homelab','networking','hardware']
---

## Networking

For the homelab, I would like to choose a commerical company's product, as the service can be guaranteed by the company reputation. All my devices can connect to the WAN via NAT1 such that I don't need the nat passthrough solution. I choose [Tailscale](https://tailscale.com/) as I mentioned, it performs well under my testing. Just follow the instruction and the networking problem is solved.

## Service

For the homelab, I would like to docker as it is very covinence and can set up easily.

To install the docker, I just follow the intrduction from the [document](https://docs.docker.com/engine/install/ubuntu/):

```shell
# uninstall old versions (if installed) 
sudo apt-get install remove docker docker-engine docker.io containere runc

# install using the repository
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release # some preliminary
sudo mkdir -p /etc/apt/keyrings # add gpg key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
## add key
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# OPTIONAL: for China's user you may use mirrors.bfsu.edu.cn for a smooth download experience
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.bfsu.edu.cn/docker-ce/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# update apt repository and install docker and related packages
sudo apt-get update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

# check docker verion
sudo docker version
# Client: Docker Engine - Community
#  Version:           20.10.18
#  API version:       1.41
#  Go version:        go1.18.6
#  Git commit:        b40c2f6
#  Built:             Thu Sep  8 23:11:43 2022
#  OS/Arch:           linux/amd64
#  Context:           default
#  Experimental:      true

# Server: Docker Engine - Community
#  Engine:
#   Version:          20.10.18
#   API version:      1.41 (minimum version 1.12)
#   Go version:       go1.18.6
#   Git commit:       e42327a
#   Built:            Thu Sep  8 23:09:30 2022
#   OS/Arch:          linux/amd64
#   Experimental:     false
#  containerd:
#   Version:          1.6.8
#   GitCommit:        9cd3357b7fd7218e4aec3eae239db1f68a5a6ec6
#  runc:
#   Version:          1.1.4
#   GitCommit:        v1.1.4-0-g5fd4c4d
#  docker-init:
#   Version:          0.19.0
#   GitCommit:        de40ad0
```

### MultiMedia

I use Jellyfin as my multimedia server and install it via the `docker-compose.yml`:

```yaml
version: "2.1"
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    volumes: # map the physical volume to the container
      - /path/to/library:/config       
      - /path/to/tvseries:/data/tvshows
      - /path/to/movies:/data/movies
    ports:
      - 8096:8096
    restart: always # when docker restart, the docker image will auto restart
```

### Authentication

I use Authentik and Keycloak for the Authentication. The Authentik is for my self-hosted service, and the KeyCloak is for the other serive that I need to provide to other users. Similarly, I use `docker-compose.yml` to set up these services:

```yaml
# Authentik
# you need to set up the ENV parameters on other file call `.env`, check https://goauthentik.io/docs/installation/docker-compose for the detail
version: '3.4'

services:
  postgresql:
    image: docker.io/library/postgres:12-alpine
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
      start_period: 20s
      interval: 30s
      retries: 5
      timeout: 5s
    volumes:
      - database:/var/lib/postgresql/data
    environment:
      - POSTGRES_PASSWORD=${PG_PASS:?database password required}
      - POSTGRES_USER=${PG_USER:-authentik}
      - POSTGRES_DB=${PG_DB:-authentik}
    env_file:
      - .env
  redis:
    image: docker.io/library/redis:alpine
    command: --save 60 1 --loglevel warning
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "redis-cli ping | grep PONG"]
      start_period: 20s
      interval: 30s
      retries: 5
      timeout: 3s
    volumes:
      - redis:/data
  server:
    image: ${AUTHENTIK_IMAGE:-ghcr.io/goauthentik/server}:${AUTHENTIK_TAG:-2022.9.0}
    restart: unless-stopped
    command: server
    environment:
      AUTHENTIK_REDIS__HOST: redis
      AUTHENTIK_POSTGRESQL__HOST: postgresql
      AUTHENTIK_POSTGRESQL__USER: ${PG_USER:-authentik}
      AUTHENTIK_POSTGRESQL__NAME: ${PG_DB:-authentik}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
      # AUTHENTIK_ERROR_REPORTING__ENABLED: "true"
    volumes:
      - ./media:/media
      - ./custom-templates:/templates
      - geoip:/geoip
    env_file:
      - .env
    ports:
      - "0.0.0.0:${AUTHENTIK_PORT_HTTP:-9000}:9000"
      - "0.0.0.0:${AUTHENTIK_PORT_HTTPS:-9443}:9443"
  worker:
    image: ${AUTHENTIK_IMAGE:-ghcr.io/goauthentik/server}:${AUTHENTIK_TAG:-2022.9.0}
    restart: unless-stopped
    command: worker
    environment:
      AUTHENTIK_REDIS__HOST: redis
      AUTHENTIK_POSTGRESQL__HOST: postgresql
      AUTHENTIK_POSTGRESQL__USER: ${PG_USER:-authentik}
      AUTHENTIK_POSTGRESQL__NAME: ${PG_DB:-authentik}
      AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS}
      # AUTHENTIK_ERROR_REPORTING__ENABLED: "true"
    # This is optional, and can be removed. If you remove this, the following will happen
    # - The permissions for the /media folders aren't fixed, so make sure they are 1000:1000
    # - The docker socket can't be accessed anymore
    user: root
    volumes:
      - ./media:/media
      - ./certs:/certs
      - /var/run/docker.sock:/var/run/docker.sock
      - ./custom-templates:/templates
      - geoip:/geoip
    env_file:
      - .env

volumes:
  database:
    driver: local
  redis:
    driver: local
```

```yaml
# KeyClock
version: '3'

services:
  postgres:
      image: postgres
      volumes:
        - ./data:/var/lib/postgresql/data
      environment:
        POSTGRES_DB: keycloak
        POSTGRES_USER: keycloak
        POSTGRES_PASSWORD: password

  keycloak:
      image: keycloak/keycloak:latest
      environment:
        DB_VENDOR: POSTGRES
        DB_ADDR: postgres
        DB_DATABASE: keycloak
        DB_USER: keycloak
        DB_SCHEMA: public
        DB_PASSWORD: password       # change it if you want
        KEYCLOAK_USER: admin
        KEYCLOAK_PASSWORD: Pa55w0rd # change it if you want 
        PROXY_ADDRESS_FORWARDING: "true"
        REDIRECT_SOCKET: "proxy-https"
      ports:
        - 8080:8080
      depends_on:
        - postgres
```

### Working and Coding

Most of the time, I just use the local environment for the documentation and coding, however, sometimes I will re-build the computer and to avoid the data loss. Thus, I choose [outline](https://github.com/outline/outline) for the documentation, [dokuwiki](https://www.dokuwiki.org/dokuwiki) for building the wiki system, [Nexcloud] as my personal Net storage,  and [Gitea](https://gitea.io) as my self-hosted code repository:

```yaml
# outline 
# you need to set up the ENV parameters on other file call `.env`, check https://app.getoutline.com/s/770a97da-13e5-401e-9f8a-37949c19f97e/doc/docker-7pfeLP5a8t for the detail
version: "3"
services:

  outline:
    image: outlinewiki/outline
    env_file: ./docker.env
    command: sh -c "yarn sequelize:migrate --env=production-ssl-disabled && yarn start --env=production-ssl-disabled"
    ports:
      - "3000"3000"
    depends_on:
      - postgres
      - redis

  redis:
    image: redis
    env_file: ./docker.env
    ports:
      - "6379:6379"
    volumes:
      - ./redis.conf:/redis.conf
    command: ["redis-server", "/redis.conf"]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 30s
      retries: 3

  postgres:
    image: postgres
    env_file: ./docker.env
    ports:
      - "5432:5432"
    volumes:
      - database-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready -U user"]
      interval: 30s
      timeout: 20s
      retries: 3
    environment:
      POSTGRES_USER: user       # change it if you want
      POSTGRES_PASSWORD: pass   # change it if you want
      POSTGRES_DB: outline

  storage:
    image: minio/minio:latest
    env_file: ./docker.env
    ports:
      - "9000:9000"
      - "9001:9001"
    entrypoint: sh
    command: -c 'minio server /data --console-address ":9001"'
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - /mnt/minio/data:/data
      - /mnt/minio/config:/root/.minio
    healthcheck:
      test: ["CMD", "curl", "-f", "http://storage:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

volumes:
  storage-data:
  database-data
```

```yaml
# dokuwiki
version: '2'
services:
  dokuwiki:
    image: docker.io/bitnami/dokuwiki
    ports:
      - '8089:8080'
    volumes:
      - ./dokuwiki:/bitnami/dokuwiki'
```

```yaml
# Nextcloud
version: '2'

services:
  app:
    container_name: nextcloud_app
    image: nextcloud
    restart: always
    ports:
      - 10000:80
    environment:
      - DATABASE_URL=mysql+pymysql://nextcloud:nextcloud@db/nextcloud
      - REDIS_URL=redis://redis:6379
    volumes:
      - /opt/nextcloud/www:/var/www/html
    depends_on:
      - db
      - redis
    networks:
        default:
        internal:

  db:
    container_name: nextcloud_db
    image: mariadb:10.5
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=nextcloud   # change it if you want
      - MYSQL_USER=nextcloud            # change it if you want
      - MYSQL_PASSWORD=nextcloud        # change it if you want
      - MYSQL_DATABASE=nextcloud        # change it if you want
    volumes:
      - /opt/nextcloud/db:/var/lib/mysql
    networks:
        internal:
    command: --transaction-isolation=READ-COMMITTED --binlog-format=ROW

  redis:
    container_name: nextcloud_redis
    image: redis
    volumes:
      - /opt/nextcloud/redis/data:/data
      - /opt/nextcloud/redis/redis.conf:/etc/redis/redis.conf
    restart: always
    networks:
        internal:
    command: redis-server /etc/redis/redis.conf --appendonly yes

networks:
    default:
    internal:
        internal: true
```


```yaml
# Gitea
version: "3"

networks:
  gitea:
    external: false

services:
  server:
    image: gitea/gitea:latest
    container_name: gitea
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - GITEA__database__DB_TYPE=postgres
      - GITEA__database__HOST=db:5432   # change it if you want
      - GITEA__database__NAME=gitea     # change it if you want
      - GITEA__database__USER=gitea     # change it if you want
      - GITEA__database__PASSWD=gitea   # change it if you want
    restart: always
    networks:
      - gitea
    volumes:
      - ./gitea:/data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "3000:3000"
      - "1022:22"
    depends_on:
      - db

  db:
    image: postgres:14
    restart: always
    environment:
      - POSTGRES_USER=gitea
      - POSTGRES_PASSWORD=gitea
      - POSTGRES_DB=gitea
    networks:
      - gitea
    volumes:
      - ./postgres:/var/lib/postgresql/data
```
### RSS Feed Reader

I use Miniflux as my RSS Feed Reader, the reason why I give Tiny Tiny RSS is that Miniflux V2 is written by Go-lang and I don't like PHP.

```yaml
version: '3.4'
services:
  miniflux:
    image: miniflux/miniflux:latest
    ports:
      - "8080:8080"
    depends_on:
      - db
    environment:
      - DATABASE_URL=postgres://miniflux:secret@db/miniflux?sslmode=disable
      - RUN_MIGRATIONS=1
      - CREATE_ADMIN=1
      - ADMIN_USERNAME=admin
      - ADMIN_PASSWORD=Pa55word
      - OAUTH2_USER_CREATION=true
      - OAUTH2_PROVIDER=oidc
      - OAUTH2_CLIENT_ID=<oauth-client-id>
      - OAUTH2_CLIENT_SECRET=<oauth-client-secret>
      - OAUTH2_REDIRECT_URL=<miniflux-url>oauth2/oidc/callback
      - OAUTH2_OIDC_DISCOVERY_ENDPOINT=<oidc-endpoint>
  db:
    image: postgres:latest
    environment:
      - POSTGRES_USER=miniflux
      - POSTGRES_PASSWORD=secret
    volumes:
      - miniflux-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "miniflux"]
      interval: 10s
      start_period: 30s
volumes:
  miniflux-db:
```

## Key and Password Management

There are multiple different password manager, Google Password Manager, 1Password, LastPass, etc.. But I choose Bitwarden as I can self-host the software on my own machine and I don't need to worry about the data leakage.

```yaml
version: "3"
services:
  bitwarden:
    image: bitwardenrs/server
    container_name: bitwardenrs
    restart: always
    ports:
        - "127.0.0.1:8000:80"
        - "127.0.0.1:3012:3012"
    volumes:
      - ./bw-data:/data
    environment:
      WEBSOCKET_ENABLED: "true"
      SIGNUPS_ALLOWED: "false"
      WEB_VAULT_ENABLED: "true"
      ADMIN_TOKEN: "<admin-token>" # you can generate the token by using openssl: `openssl rand -hex 32`
```

