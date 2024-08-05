---
title: "🧑🏿‍💻 Homelab: Don't Let the Docker escape from the ufw's control"
date: 2022-07-21T00:11:21+08:00
draft: false
tags: ['homelab','networking', 'docker', 'ufw']
series: ['homelab']
---


<!--more-->

"Uncomplicated firewall", a.k.a, UFW, is the new/next-generation of firewall of Linux system. As says in its name, "uncomplicated" is the feature. However, in some situation, it is still complicated, for example, works with Docker.

Usually, for the homelab/VPS, we self-host a bunch of services and use them with reverse proxy (like Nginx, Caddy, Traefik) with different subdomain. However, Docker tries to modify the firewall rules without notification, like this:

```shell
ubuntu@myserver:~$ sudo ufw status
Status: active

To                         Action      From
--                         ------      ----                 
80                         ALLOW       Anywhere                  
443                        ALLOW       Anywhere                                 
22                         ALLOW       Anywhere                           
80 (v6)                    ALLOW       Anywhere (v6)             
443 (v6)                   ALLOW       Anywhere (v6)                          
22 (v6)                    ALLOW       Anywhere (v6)
```

In ufw list, I only allow the SSH port and HTTP/HTTPS ports. However, in `IPTABLES`, we can see that: 
```shell
ubuntu@bayes:~$ sudo iptables -L DOCKER
Chain DOCKER (7 references)
target     prot opt source               destination         
ACCEPT     tcp  --  anywhere             172.21.0.2           tcp dpt:http
ACCEPT     tcp  --  anywhere             172.21.0.2           tcp dpt:3012
ACCEPT     tcp  --  anywhere             172.28.0.2           tcp dpt:9000
ACCEPT     tcp  --  anywhere             172.19.0.3           tcp dpt:postgresql
ACCEPT     tcp  --  anywhere             172.19.0.2           tcp dpt:6379
ACCEPT     tcp  --  anywhere             172.19.0.4           tcp dpt:9001
ACCEPT     tcp  --  anywhere             172.19.0.4           tcp dpt:9000
ACCEPT     tcp  --  anywhere             172.18.0.5           tcp dpt:9443
ACCEPT     tcp  --  anywhere             172.18.0.5           tcp dpt:9000
ACCEPT     tcp  --  anywhere             172.20.0.2           tcp dpt:8082
ACCEPT     tcp  --  anywhere             172.20.0.2           tcp dpt:tproxy
```
The Docker turn only multiple ports which does not show in the UFW list.

## How to avoid this

First, make sure that the SSH port is allowed in UFW, and each container can be reached:
```shell
sudo ufw allow ssh              # or ssh ufw allow <ssh-port>
ufw allow from 172.17.0.0/16    # allow containers communication
ufw default deny incoming
ufw default allow outgoing
ufw default allow routed
ufw disable && ufw enable
```

Then, we need to go the Docker's daemon to modify the configuration:

```shell
sudo mkdir -p /lib/systemd/system/docker.service.d
sudo cat << EOF > /lib/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF

sudo cat << EOF > /etc/docker/daemon.json
{
  "hosts": ["fd://"],
  "dns": ["8.8.8.8", "8.8.4.4"],
  "iptables": false
}
EOF

sudo systemctl daemon-reload && sudo systemctl restart docker
```

Last, we need to configura the Docker's NAT to make sure that all the containers can route via the `docker0` interface:

```shell
sudo cat << EOF >> /etc/ufw/before.rules
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING ! -o docker0 -s 172.17.0.0/16 -j MASQUERADE
COMMIT
EOF
```