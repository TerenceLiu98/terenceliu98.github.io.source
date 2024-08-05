---
title: "🧑🏿‍💻 Homelab: A self-hosted GitHub Accelerator"
date: 2023-06-17T00:11:21+08:00
draft: false
math: true
tags: ['homelab', 'proxy', 'github']
series: ['homelab']
---

<!--more-->

In general, there are multiple ways for you to accelerate the `git pull / git push` or download the release/source code from [GitHub](https://github.com):

1. You may directly use a HTTP/HTTPS/SOCK5 proxy in your terminal `export https_proxy=https://[ip]:[port] http_proxy=http://[ip]:[port]` 
2. You may use a public `github-proxy`, e.g. [ghproxy.com](https://ghproxy.com) or [gh-proxy.com](https://gh-proxy.com)

You can also build a self-hosted `ghproxy`-liked web service to avoid data leakage (if there is). With docker, you can set up the service in one or two minutes:

```yaml
version: "3"
services:
  gh-proxy:
    image: stilleshan/gh-proxy
    container_name: gh-proxy
    ports:
      - 12345:80
    restart: always
```

With `nginx` you can proxy the service to a sub-domain:

```
# Upstream where your authentik server is hosted.
upstream ghproxy {
    server 127.0.0.1:12345;
    # Improve performance by keeping some connections alive.
    keepalive 10;
}

# Upgrade WebSocket if requested, otherwise use keepalive
map $http_upgrade $connection_upgrade_keepalive {
    default upgrade;
    ''      '';
}

server {
    # HTTP server config
    listen 80;
    server_name ghproxy.example.com;

    # 301 redirect to HTTPS
    location / {
            return 301 https://$host$request_uri;
    }
}

server {
    # HTTPS server config
    listen 443 ssl http2;
    server_name ghproxy.example.com;

    # TLS certificates
    ssl_certificate /var/www/ssl/example.com.crt;
    ssl_certificate_key /var/www/ssl/example.com.key;

    # Proxy site
    location / {
        proxy_pass http://ghproxy;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade_keepalive;
    }
}
```