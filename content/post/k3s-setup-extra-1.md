---
title: "K3s/Kubernetes - 番外：自建 Docker 镜像站"
date: 2022-10-02T10:00:00+08:00
draft: false
keywords:
  - kubernetes
  - docker
  - registry
tags: ['k3s', 'kubernetes', 'docker', 'registry']
description: "K3s/Kubernetes - 番外：自建 Docker 镜像站"
---

正如我在[K3s Setup 2]({{< ref "/post/k3s-setup-2" >}} "K3s Setup 2")中提到的，通常中国用户访问`https: //gcr.io`、`https://k8s.gcr.io` 或 `https://ghcr.io`。 因此，在这种情况下，我们可以设置一个服务器作为注册代理端点。

## 一些选项

DockerHub 提供了一个名为 [Docker Registry](https://docs.docker.com/registry/) 的“官方”包，它是一个无状态、高度可扩展的服务器端应用程序，可以存储并让用户分发 Docker 镜像。

Nexus Repository OSS，由 Sonatype 提供，是一个开源存储库，支持多种工件格式，包括 Docker、Java™ 和 npm。

由 VMWare 提供的 Harbor 是一个开源注册表，它通过策略和基于角色的访问控制来保护工件，确保图像被扫描并且没有漏洞，并将图像签名为可信的。

## Nexus 作为 Registry 代理

我们很容易构建 Nexus，只需使用 `docker-compose.yml`：

```yaml
version: "3.7"
services:
  nexus:
    image: sonatype/nexus3:latest
    environment:
      INSTALL4J_ADD_VM_PARAMS: -Xms128m -Xmx512m -XX:MaxDirectMemorySize=512m # decrease the occupancy rate of nexus
    container_name: nexus3
    restart: always
    ports:
      - 8081:8081   # port of frontend of the nexus repo
      - 8082:8082   # port of the docker proxy
    volumes:
      -  ./data:/nexus-data
```

With `sudo docker compose up -d`, we can easily run the nexus. [^1]

For the reverse proxy, I use nginx and here is the configuration:

```shell
server {
    listen 80;
    server_name nexus.exmaple.com;

    return 301 https://$server_name$request_uri;
}

server {
    listen 80;
    server_name registry.example.com;

    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name nexus.example.com;  # nexus frontend

    ssl_certificate <path-of-certificate>;
    ssl_certificate_key <path-of-certificate-key>;
    ssl_session_timeout  5m;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers   on;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Via "nginx";
    }

}

server {
    listen 443 ssl;
    server_name registry.exmaple.com; # docker proxy

    ssl_certificate <path-of-certificate>;
    ssl_certificate_key <path-of-certificate-key>;
    ssl_session_timeout  5m;;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers   on;

    location / {
        proxy_pass http://127.0.0.1:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Via "nginx";
        client_max_body_size 1024M;
    }

    location /v2/ {
        proxy_pass http://127.0.0.1:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Via "nginx";
        client_max_body_size 1024M;
    }

}
```

设置完nexus和nginx后，我们可以去 `https://nexus.example.com` 设置代理规则。

1. For Docker: `Creat Repository` -> Choose `docker(proxy)` ->  `Remote storage = https://registry-1.docker.io` and `Docker Index = Use Docker Hub`
2. For [ghcr.io](https://ghcr.io):  Creat Repository` -> Choose `docker(proxy)` ->  `Remote storage = https://ghcr.io` 
3. For [gcr.io](https://gcr.io):  Creat Repository` -> Choose `docker(proxy)` ->  `Remote storage = https://gcr.io` 
4. For [k8s.gcr.io](https://k8s.gcr.io):  Creat Repository` -> Choose `docker(proxy)` ->  `Remote storage = https://k8s.gcr.io` 
5. **Create a group**:  Creat Repository` -> Choose `docker(group)` ->  `HTTP: 8082` -> `Allow anaymous docker pull`(to allow `docker pull` without authentication) -> select members into the group
6. Go to `Security-Realms` and activate `Docker Bearer Token Realm`

Then, you may try pulling image in you server:

```shell
sudo docker pull registry.example.com/library/nginx:alpine                                # from Docker Hub
sudo docker pull registry.example.com/zvonimirsun/yourls                                  # from ghcr.io
sudo docker pull registry.example.com/google-containers/kubernetes-dashboard-amd64:v1.8.3 # from gcr.io
sudo docker pull registry.example.com/coreos/kube-state-metrics:v1.5.0                    # from quay.io
```

For the system's `containerd`, you can simply go to `/etc/containerd/containerd/config.toml` and modify the configuration and restart `sudo systemctl restart containered`

```shell
[plugins.cri.registry.mirrors]
  [plugins.cri.registry.mirrors."docker.io"]
    endpoint = ["https://mirrors.example.com"]
  [plugins.cri.registry.mirrors."quay.io"]
    endpoint = ["https://mirrors.example.com"]
    [plugins.cri.registry.mirrors."ghcr.io"]
    endpoint = ["https://mirrors.example.com"]
  [plugins.cri.registry.mirrors."gcr.io"]
    endpoint = ["https://mirrors.example.com"]
  [plugins.cri.registry.mirrors."k8s.gcr.io"]
    endpoint = ["https://mirrors.example.com"]
```

对于 rancher 的 `containerd`，k3s 将在 `/var/lib/rancher/k3s/agent/etc/containerd/config.toml` 中为 containerd 生成 config.toml，对于此文件的高级定制，您可以创建另一个名为 ` config.toml.tmpl` 在同一目录中，它将被使用。 然后，修改配置到文件中，重启`sudo systemctl restart k3s`或`sudo systemctl restart k3s-agent`

```shell
[plugins.cri.registry.mirrors]
  [plugins.cri.registry.mirrors."docker.io"]
    endpoint = ["https://mirrors.example.com"]
  [plugins.cri.registry.mirrors."quay.io"]
    endpoint = ["https://mirrors.example.com"]
    [plugins.cri.registry.mirrors."ghcr.io"]
    endpoint = ["https://mirrors.example.com"]
  [plugins.cri.registry.mirrors."gcr.io"]
    endpoint = ["https://mirrors.example.com"]
  [plugins.cri.registry.mirrors."k8s.gcr.io"]
    endpoint = ["https://mirrors.example.com"]
```

[^1]：在启动 yaml 之前，先创建文件夹并授予适当的权限，对我来说：`mkdir data && chmod 777 data` 就足够了。 默认密码存储在 data/admin.password 中。