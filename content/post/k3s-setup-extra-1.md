---
title: "🧑🏿‍💻 K3s/Kubernetes - Set up a K3s Cluster with your VPS (Extra Story 1)"
date: 2022-10-02T10:00:00+08:00
draft: false
tags: ['k3s', 'kubernetes', 'docker', 'registry']
series: ['kubernetes']
---

<!--more-->

As I have mentioned in [K3s Setup 2]({{< ref "/post/k3s-setup-2" >}} "K3s Setup 2"), usually, it is not easy for the China's user to access `https://gcr.io`, `https://k8s.gcr.io` or `https://ghcr.io`. Thus, under this circumstance, we may set up a server as the registry proxy endpoint.

## Some options

DockerHub provide a "offical" package called [Docker Registry](https://docs.docker.com/registry/) where it is a stateless, hightly scalable server side application that stores and lets users distribute Docker images. 

Nexus Repository OSS, provided by Sonatype, is an open source repository that supports many artifact formats, including Docker, Java™, and npm.

Harbor, provided by VMWare,  is an opensource registry that secure artifacts with policies and role-based access control, ensures images are scanned and free from vulnerabilities, and signs images as trusted. 

## Nexus as registry proxy

It is easy for us to build the Nexus repositry, simply with the `docker-compose.yml`:

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
    server_name mirrors.example.com;

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
    server_name mirrors.exmaple.com; # docker proxy

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
        proxy_pass http://127.0.0.1:8083;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Via "nginx";
        client_max_body_size 1024M;
    }

}
```

After setting up the nexus and nginx, we can go to `https://nexus.example.com` to set up the proxy rules.

1. For Docker: `Creat Repository` -> Choose `docker(proxy)` ->  `Remote storage = https://registry-1.docker.io` and `Docker Index = Use Docker Hub`
2. For [ghcr.io](https://ghcr.io):  Creat Repository` -> Choose `docker(proxy)` ->  `Remote storage = https://ghcr.io` 
3. For [gcr.io](https://gcr.io):  Creat Repository` -> Choose `docker(proxy)` ->  `Remote storage = https://gcr.io` 
4. For [k8s.gcr.io](https://k8s.gcr.io):  Creat Repository` -> Choose `docker(proxy)` ->  `Remote storage = https://k8s.gcr.io` 
5. **Create a group**:  Creat Repository` -> Choose `docker(group)` ->  `HTTP: 8082` -> `Allow anaymous docker pull`(to allow `docker pull` without authentication) -> select members into the group
6. Go to `Security-Realms` and activate `Docker Bearer Token Realm`

Then, you may try pulling image in you server:

```shell
sudo docker pull mirrors.example.com/library/nginx:alpine                                # from Docker Hub
sudo docker pull mirrors.example.com/zvonimirsun/yourls                                  # from ghcr.io
sudo docker pull mirrors.example.com/google-containers/kubernetes-dashboard-amd64:v1.8.3 # from gcr.io
sudo docker pull mirrors.example.com/coreos/kube-state-metrics:v1.5.0                    # from quay.io
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

For the rancher's `containerd`, k3s will generate config.toml for containerd in `/var/lib/rancher/k3s/agent/etc/containerd/config.toml`, for advanced customization for this file you can create another file called `config.toml.tmpl` in the same directory and it will be used instead. Then, modify the configuration into the file and restart the `sudo systemctl restart k3s` or `sudo systemctl restart k3s-agent`

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

[^1]: Before you up the yaml, create the folder first and give the proper permission, for me: `mkdir data && chmod 777 data` is good enough. The default password is stored in `data/admin.password`.