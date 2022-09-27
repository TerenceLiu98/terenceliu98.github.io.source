---
title: "Set up a K3s Cluster with your VPS (2)"
date: 2022-09-26T00:11:21+08:00
draft: false
tags: ['k3s', 'kubernetes']
---


After generate a basic K3s cluster, now, let try to modify it into High Availability Cluster. Single server cluster can meet a variety of use cases, but for environments where uptime of the Kubenetes control plane is critical, where we need the High Availability configuration. There are two ways for High Availability:

1. High Availability with an External DB (for example, [PostgreSQL](https://www.postgresql.org/), [MySQL](https://www.mysql.com/),  [MariaDB](https://mariadb.org/))
2. High Availability with Embedded DB ([etcd](https://etcd.io/))

I chose the second one - with Embedded DB.

## Enviornment

Here is the list of my device:

| Node Name | Location | Specification | OS | Network | IP |
| :-------: | :------: | :-----------: | :--: | :-----: | :--: |
| hilbert(master) | Tencent Cloud (SH-CN) | 4C8G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 1.xx.xx.xx + 192.168.36.1 | 
| cantor(master) | Tencent Cloud (SH-CN) | 2C4G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 110.xx.xx.xx + 192.168.36.2 |
| newton(agent) | Tencent Cloud (GZ-CN) | 1C2G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 119.xx.xx.xx + 192.168.36.3 |

## Configuration

Here is the confiugration of server:

```shell
curl -sfL https://get.k3s.io | K3S_TOKEN=<token>  INSTALL_K3S_EXEC="server \
                            --node-ip <wg-node-ip> \
                            --advertise-address <node-public-ip> \
                            --node-external-ip <node-public-ip> \
                            --flannel-iface wg0   \
                            --node-name <node-name> \ 
                            --cluster-init " sh -
```

For whom can not access Google and GitHub fluently, you may try:
```shell
curl -sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn \
                            K3S_TOKEN=<token>  INSTALL_K3S_EXEC="server \
                            --node-ip <wg-node-ip> \
                            --advertise-address <node-public-ip> \
                            --node-external-ip <node-public-ip> \
                            --flannel-iface wg0   \
                            --node-name <node-name> \ 
                            --cluster-init " sh -

```

To generate the token, I used `openssl rand --hex 16`.

Similarly, for the second server, you can use the same configuration above with IPs' substitution. 

For the agent, you can use the configuration from [k3s-setup-1]({{< ref "/post/k3s-setup-1" >}}) with self-generated `K3S_TOKEN`.

## Trouble-shooting

After the installation, I met the metric-server crashing and I found the solution in here: [metrics-server issues 812](https://github.com/kubernetes-sigs/metrics-server/issues/812#issuecomment-907586608). Simply go to `/var/lib/rancher/k3s/server/manifests/metrics-server/metrics-server-deployment.yaml` and add `- --kubelet-insecure-tls`



