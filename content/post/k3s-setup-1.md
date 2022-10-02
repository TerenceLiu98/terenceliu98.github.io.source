---
title: "Set up a K3s Cluster with your VPS (1)"
date: 2022-09-26T00:11:21+08:00
draft: false
tags: ['k3s', 'kubernetes']
---


## Before

K3s is a lightweight Kubernetes which is more suitable for the Edge/IoT/CI/ARM scenario/devices. Usually, for person, we do not have multiple high-performance device like 24c server or even higher. Hence, K3s is a way we can learn how to set up a kubernetes cluster.

For me, I am a bare metal fanatic many year ago, but I changed into a Docker user after I know more about virtualization and containers.  These OS-level virtualization is more convenient when we are trying to migrate our service, like blog migration, authentication migration, etc.

## Environment

Here is the list of my device:

| Node Name | Location | Specification | OS | Network | IP |
| :-------: | :------: | :-----------: | :--: | :-----: | :--: |
| hilbert(master) | Tencent Cloud (SH-CN) | 4C8G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 1.xx.xx.xx + 192.168.36.1 | 
| cantor(master) | Tencent Cloud (SH-CN) | 2C4G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 110.xx.xx.xx + 192.168.36.2 |
| newton(agent) | Tencent Cloud (GZ-CN) | 1C2G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 119.xx.xx.xx + 192.168.36.3 |

The reason I would like to setup K3s over Wireguard is because of the expandability. Once over the wireguard, I could add other VPS/Server into the LAN and as a node of the K3s cluster easily even if the node does not has a networking problem and as the Wireguard is safe enough I do not have to consider the security issues of nodes' interconnection.

### Set up Wireguard

I write a [tool](https://github.com/TerenceLiu98/wgtools) which can help me set up the Wireguard configuration (you can also try this tool, and any issue or pull request is welcomed)
