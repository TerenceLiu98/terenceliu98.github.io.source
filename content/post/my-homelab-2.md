---
title: "家庭实验室: 设备篇"
date: 2022-07-20T00:11:21+08:00
draft: false
tags: ['homelab','networking','hardware']
---

长期以来，笔者购买了许多电子产品，有物理存在的主机也有在云上的虚拟服务器，但是，从来都没有想过将他们放在一个集群内。或者更准确地说，是搭建一个可以轻松管理它们的平台。 在这个暑假，我开始思考建立分布式家庭实验室的可能性。通过网络，将我的设备串通在一起，希望可以做到不管我在哪都可以访问到。

## 为什么是分布式的

笔者长期混迹在粤港澳大湾区周边城市，各式各样的设备也散落在不同的城市，所以要想组成一个 Lab，这些设备就必然需要通过网线才能相互访问，也就必然是分布式的了。

这是我的设备列表

| Device | Location | Configuration | System | Network | 
| :----: | :------: | :-----------: | :----: | :-----: |
| DELL EMC R730 | Zhuhai, China | E5-2650V4 + 128GB + 240GB SSD + 600GB HDD + NVIDIA TITAN XP | Ubuntu 20.04 LTS | 500Mbps |
| DELL Precision T1700 | Zhuhai, China | i7-4790 + 16GB + 256GB SSD + 1T SATA HDD + NVIDIA RTX 2060Ti | Arch Linux | 500Mbps | 
| Homebuilt PC | Zhongshan, China | i5-9400f + 16GB + 256GB SSD + 256GB SSD + 2T SATA HDD + NVIDIA TITAN XP | Arch Linux | 500Mbps |
| Homebuilt NAS | Shenzhen, China | AMD A8-5550M + 6G DDR3 + 128G SSD + 3T SATA HDD |Ubuntu 20.04 LTS | 1Gbps |
| ARM Router | Shenzhen, China | rk3568 + 2GB Mem + 8GB EMMC | iStoreOS (based on OpenWrt) | 1Gbps |
| ARM Router | Shenzhen, China | rk3399 + 1GB Mem + 1GB + 16GB EMMC | Ubuntu 20.04 LTS | 1Gbps |
| ARM Router (In future) | Guangzhou, China | rk3399 + 1GB Mem + 1GB + 16GB EMMC | Ubuntu 20.04 LTS | 100Mbps |

不仅有各种物理形态的机器，还有较多的 VM/VPC/VPS/轻量服务器：

| Device | Location | Configuration | System | Network | 
| :----: | :------: | :-----------: | :----: | :-----: |
| A Lighthouse server | Tencent Cloud - Guangzhou | 1C2G | Ubuntu 20.04 LTS | 3Mbps |
| A Lighthouse server | Tencent Cloud - Shuanghai | 2C4G | Ubuntu 20.04 LTS | 3Mbps |
| A Lighthouse server | Tencent Cloud - Shuanghai | 4C8G | Ubuntu 20.04 LTS | 3Mbps |
| A Lighthouse server | Tencent Cloud - Shuanghai | 2C2G | Ubuntu 20.04 LTS | 3Mbps |
| A Lighthouse server | Tencent Cloud - HKSAR | 2C4G | Ubuntu 20.04 LTS | 30Mbps |
| A Lighthouse server | Tencent Cloud - HKSAR | 2C4G | Ubuntu 20.04 LTS | 30Mbps |
| A Lighthouse server | Tencent Cloud - Singapore | 2C2G | Ubuntu 20.04 LTS | 30Mbps |
| A VM server | Oracle Cloud - Japan | 1C1G | Ubuntu 20.04 LTS | 500Mbps |
| A VM server | Oracle Cloud - Japan | 1C1G | Ubuntu 20.04 LTS | 500Mbps |
| A VM server | CubeCloud - HKSAR | 1C512M | Ubuntu 20.04 LTS | 1Gbps |

列出这部分设备后，你可能知道我为什么需要分布式解决方案了。

## 可能可行的解决方案

目前，经过我的「调研」，可行的方案大概有如下两种，

1. Docker Swarm
2. Kubernetes

【Docker Swarm](https://docs.docker.com/engine/swarm/) Docker 出的是容器的集群管理工具。它拥有如下主要特性：

1. 集成于Docker Engine的集群管理工具。
2. 分布式设计：从一个image生成整个集群。一个docker swarm下的不同node，可以分布于同一，或不同的物理设备上。
3. 灵活调度：按需启动或关闭容器。
4. 高可用性：支持监控容器状态，如果容器崩溃，可以自动重启容器。
5. 支持多样的网络配置：支持overlay、macvlan、bridge、host等网络形式。
6. 服务发现
7. 负载均衡
8. 加密传输：默认基于TLS实现容器间的交互，实现加密传输。
9. 升级回退：支持动态升级容器，如果升级后的容器运行不正常，可自动回退到上一版本。

但 [Docker Swarm](https://github.com/docker-archive/classicswarm) 已经被 Docker 抛弃了，但是，我们依旧可以用时 Docker swarm mode 来组建一个个人容器云。


[Kubernetes]((https://kubernetes.io/docs/home/)) 也被称为 K8S, 以容器为中心的管理软件 Kubernetes 已成为部署和操作容器化应用的通行标准。Kubernetes 最初在 Google 开发，然后在 2014 年开源发布。它是基于云的容器编排技术，旨在实现高效资源管理、完全自动化和资源利用率最大化。Kubernetes 具有如下优点：
1.	自动化运营： Kubernetes 具有许多内置命令，可用于处理应用管理中繁重的工作，从而自动化日常操作，帮助您确保应用始终按照预期的方式运行。
2.	基础架构抽象：安装 Kubernetes 后，它将代表您的工作负载处理计算、网络和存储。这使开发者可以专注于应用，而不必担心底层环境。
3.	服务运行状况监控：Kubernetes 会对服务不间断地执行健康检查，重新启动有故障或停滞的容器，且只会在确认服务正常运行时向用户提供服务。

一般来说，Kubernetes 更适合那些复杂的开发/生产环境中的复杂应用，而 Docker Swarm 的设计目的是为了易于使用。 根据介绍和比较，我准备同时部署 K8s 和 Docker swarm，一部分设备在 Docker Swarm（The DS集群）中使用，而其他在K8s中使用，常用的个人服务，如 Git 等会部署在 DS 中，而 K8s 则主要是用来学习。

同时，对于分布式集群，除了框架以外，网络环境也十分重要，如何通过互联网构建属于自己的私人网络呢，如下有几种公开的方案：

1. [Zerotier](https://www.zerotier.com/)
2. [Tailscale](http://tailscale.com/): based on Wireguard
3. [Nebula](https://github.com/slackhq/nebula): A scalable overlay networking tool by Slack
4. [n2n](https://github.com/ntop/n2n): peer-to-peer VPN

对比之后，对于我的家用设备，我会选择 Tailscale 作为我的实验性能，而对于这两个集群内部，我会使用 Wireguard，因为我不需要支付任何费用。

## 部署：网络

我之所以选择 Wireguard，是因为它设计轻巧，速度快，而且安全，因为它使用了最好的加密工具。然而，对于每一次，用户可能需要考虑一个 SUBNET 用于wireguard 和一个 IP 用于每个节点，对我来说，这很烦人，因为我有太多的子网需要配置。因此，我构建了一个小工具：[wgtools](https://github.com/TerenceLiu98/wgtools)

### 如何使用

* prerequest:
	* clone the code into local directory: `git clone  https://github.com/TerenceLiu98/wgtools.git`
	* install the requirement: `python -m pip install -r requirements.txt`
	* install the wireguard before using the tool

* configuration:
	* new a ipv4 pool: `python add.py network wg0`
	* new (a) peer(s): `python add.py node wg0 node1` + `python add.py node wg0 node2` + `python add.py node wg0 node3`
	* check the information: `cat wg0.conf`
	* modify the endpoint: `python modify.py wg0 node1 Endpoint 1.1.1.1`
	* generate configuration for each node: `python generate.py wg0 node1` + `python genenrate.py wg0 node2` + `python generate wg0 node3`

* script
	* copy the configuration to the machine
	* use `wg-quick` to quick start the wireguard
	* check the connectivity via `ping

### 为什么不使用广域网

是的，使用公网 IP 很方便，但可能会遇到一些安全问题，因为节点之间的通信需要暴露多个端口（Kubernetes 和 Docker Swarm）。为了避免这种情况，我可以使用 Wireguard 轻松避免这个问题，因此，为什么不呢。

## 部署：服务

### 安装 Docker 

对于homelab，我想使用docker，因为它非常方便并且可以轻松设置。要安装 docker，只需按照步骤操作即可：

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

### 多媒体娱乐

有多种多媒体软件，例如，[Plex](https://www.plex.tv/)、[Emby](https://emby.media)、[Jellyfin](https://jellyfin.org) , 和 [KODI](https://kodi.tv/)。 出于某种原因，我不想为媒体服务支付太多钱，因为我只是想要一个可以展示海报和视频简介的地方，我不需要太多“花哨”的功能。 相比之下，我选择 Jellyfin，“Emby 的开源版本”，作为我的多媒体服务器，我通过 `docker-compose.yml` 安装它：

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

### 单点认证

支持Oauth的认证软件有很多，例如[Authentik](https://goauthentik.io/)、[Okta](https://www.okta.com/)、[auth0](https:// auth0.com/)、[Ory Hydra](https://github.com/ory/hydra)、[KeyCloak](https://www.keycloak.org/)，还有一些认证云服务，比如[ authing.com](https://authing.cn)。 相比之下，我选择了Authentik和KeyCloak，authentik界面好看，而且KeyCloak是一个应用广泛的软件，这意味着在兴趣上的例子和解决方案更多。 authentik 用于我的自托管服务，而 KeyCloak 用于我需要提供给内网用户的其他服务。 同样，我使用 `docker-compose.yml` 来设置这些服务：

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

### 工作相关

大多数时候，我只是使用本地环境进行文档和编码，但有时我会重新构建计算机以避免数据丢失。 因此，我选择 [outline](https://github.com/outline/outline) 作为文档，[dokuwiki](https://www.dokuwiki.org/dokuwiki) 用于构建 wiki 系统，[Nexcloud] 为 我的个人网络存储，以及 [Gitea](https://gitea.io) 作为我的自托管代码存储库。 Outline 是一个国家替代软件，它还提供了一个漂亮的实时知识库，我可以通过网络轻松地存储我的想法和想法。 Dokuwiki 是一个著名的 wiki 系统，没有数据库后端，这意味着我可以轻松地将它迁移到任何地方。 在 Gitea 和 Gitlab 之间，我最后选择了 Gitea，因为 GitLab 的硬件要求太高，我没有足够的资源来运行 GitLab，我只需要一个地方来存储我的代码，而不是那些额外的功能。

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

### RSS 阅读器

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

## 密钥和密码管理

有多种不同的密码管理器，谷歌密码管理器，1Password，LastPass等。但我选择了Bitwarden，因为我可以在自己的机器上自行托管软件，我不需要担心数据泄露。

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

