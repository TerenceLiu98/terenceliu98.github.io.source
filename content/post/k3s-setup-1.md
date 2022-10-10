---
title: "K3s/Kubernetes - Set up a K3s Cluster with your VPS (1)"
date: 2022-09-24T00:11:21+08:00
lastmod: 2022-09-26T00:11:21+08:00
draft: false
tags: ['k3s', 'kubernetes', 'wireguard']
---


## Before

K3s is a lightweight Kubernetes which is more suitable for the Edge/IoT/CI/ARM scenario/devices. Usually, for person, we do not have multiple high-performance device like 24c server or even higher. Hence, K3s is a way we can learn how to set up a kubernetes cluster.

For me, I am a bare metal fanatic many year ago, but I changed into a Docker user after I know more about virtualization and containers.  These OS-level virtualization is more convenient when we are trying to migrate our service, like blog migration, authentication migration, etc.

## Environment

Here is the list of my device:

| Node Name | Location | Specification | OS | Network | IP |
| :-------: | :------: | :-----------: | :--: | :-----: | :--: |
| hilbert(server) | Tencent Cloud (SH-CN) | 4C8G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 1.xx.xx.xx + 192.168.36.1 | 
| cantor(server) | Tencent Cloud (SH-CN) | 2C4G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 110.xx.xx.xx + 192.168.36.2 |
| newton(worker) | Tencent Cloud (GZ-CN) | 1C2G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 119.xx.xx.xx + 192.168.36.3 |

The reason I would like to setup K3s over Wireguard is because of the expandability. Once over the wireguard, I could add other VPS/Server into the LAN and as a node of the K3s cluster easily even if the node does not has a networking problem and as the Wireguard is safe enough I do not have to consider the security issues of nodes' interconnection.

Change servers' name:

```shell
sudo hostnamectl --static set-hostname node1 && sudo hostnamectl  set-hostname node1
sudo hostnamectl --static set-hostname node2 && sudo hostnamectl  set-hostname node2
sudo hostnamectl --static set-hostname node3 && sudo hostnamectl  set-hostname node3
```

### Set up Wireguard

I write a [tool](https://github.com/TerenceLiu98/wgtools) which can help me set up the Wireguard configuration (you can also try this tool, and any issue or pull request is welcomed)

1. Generate a network interface: `python add.py network wg0`
2. Add peers: `python add.py node wg0 node1` & `python add.py node wg0 node2` & `python ad.py node wg0 node3`
3. Modify the endpoint: `python modify wg0 node1 Endpoint 1.xxx.xxx.xxx` & `python modify wg0 node2 Endpoint 110.xxx.xxx.xxx` `python modify wg0 node3 Endpoint 119.xxx.xxx.xxx`
4. Generata Wireguard configuration: `python generate.py wg0 node1` & `python generate.py wg0 node2` & `python generate.py wg0 node3`
5. Copy the Wireguard config to each node: `scp node1.conf user_name@node1:~/wg0.conf` & `scp node2.conf user_name@node2:~/wg0.conf` & `scp node2.conf user_name@node2:~/wg0.conf`


Add static entry to the hosts file:

```shell
sudo cat > /etc/hosts <<EOF
192.168.1.1 node1
192.168.1.2 node2
192.168.1.3 node3
EOF
```