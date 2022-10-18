---
title: "👨‍💻 My Personal Experimental Network: L-Net"
date: 2022-10-18T00:11:21+08:00
draft: false
tags: ['networking', 'wireguard', 'experimental network']
---

## Before

In the previous project: [Homelab]({{< ref "/post/my-homelab-1" >}} "My Homelab 2"), I listed all my devices and VPS on a table, where all the VPS own a specific public IP, and I tried to use the Wireguard to connect them into a Full-mesh intranet.

However, to investigate deeper into the network performance, I started to learn how to federate these clusters while not affecting the current usage. What's more, if I can federate this isolated network, I don't need to build separate services in different clusters. For instance, I can use a single [Prometheus](https://prometheus.io/) to monitor all the devices and no more millions of virtual interfaces :rofl: 


## Design

We are using the `Wireguard` to generate the virtual network interface for each node or each cluster. Between the cluster’s router, we also generate an isolated Wireguard tunnel between two nodes. Here is an example: `a1` is the router of the cluster `A` and `b` is the central router of the whole L-Net and `A`’s IP address is `172.12.1.0/24` , then we need an extra IP address(an extra Wireguard tunnel) for `a → b`.

Under this circumstance, we can connect the nodes inside the `A (a2, a3, …)`  to `b`, and other nodes  from `C (c1, c2, c3, …)` can also connect to `A`.

Here is the topology of my design:

 ![](/api/attachments.redirect?id=86a5c454-3316-4d2f-839d-11c58cc21db9)

Those bold-colored dotted lines can be seen as the Backbone network, and the slim-colored dotted lines can be seen as the internet/intranet. The slim-black dotted line shows that cross IP range is accessible as long as the client allows the traffic.

## Network Configuration

### Loc 1 - Mainland, China


1. Network Interface: `cn`

   
   1. IP address: `192.168.10.0/24`
   2. Allowed IP: `192.168.141.x/32, 192.168.{20,30}.0/24`
2. Network Interface (Router): `sgcn`

   
   1. IP address: `192.168.141.0/24`
   2. Allowed IP: `0.0.0.0/0`

| Service Provider | Location | Name | Public IP | Private IP | Purpose |
|----|----|----|----|----|----|
| Tencent Cloud | GZ | newton | (secret) | 192.168.10.1 / 192.168.141.2 | Router |
| Tencent Cloud | SH | gauss | (secret) | 192.168.10.2 |    |
| Tencent Cloud  | SH | cantor | (secret) | 192.168.10.3 |    |
| Tencent Cloud | SH | hilbert  | (secret) | 192.168.10.4 |    |
| China Telecom Cloud | GZ | NA | (secret) | 192.168.10.5 |    |

### Loc 2 - Japan


1. Network Interface: `jp`

   
   1. IP address: `192.168.20.0/24`
   2. Allowed IP: `192.168.142.0/32, 192.168.{10, 30}.0/24`
2. Network Interface (Router): `sgjp`

   
   1. IP address: `192.168.142.0/24`
   2. Allowed IP: `0.0.0.0/0`

| Service Provider | Location | Name | Public IP | Private IP | Purpose |
|----|----|----|----|----|----|
| Oracle Cloud | JP | einstein | (secret) | 192.168.20.1 / 192.168.142.2 | Router |
| Oracle Cloud | JP | bohr | (secret) | 192.168.20.2 |    |

### Loc 3 - HKSAR, China


1. Network Interface: `hk`

   
   1. IP address: `192.168.30.0/24`
   2. Allowed IP: `192.168.143.0/32, 192.168.{20, 30}.0/24`
2. Network Interface (Router): `sghk`

   
   1. IP address: `192.168.143.0/24`
   2. Allowed IP: `0.0.0.0/0`

| Service Provider | Location | Name | Public IP | Private IP | Purpose |
|----|----|----|----|----|----|
| Cube Cloud | HK | turing | (secret)  | 192.168.30.3 / 192.168.143.2 | Router |
| Tencent Cloud | HK | neumann | (secret) | 192.168.30.1 |    |
| Tencent Cloud | HK | hinton | (secret) | 192.168.30.2 |    |

### Loc 4 - Singapore


1. Network Interface: `sgcn`

   
   1. IP address: `192.168.141.0/24`
   2. Allowed IP: `0.0.0.0/0`
2. Network Interface: `sgjp`

   
   1. IP address: `192.168.142.0/24`
   2. Allowed IP: `0.0.0.0/0`
3. Network Interface: `sghk`

   
   1. IP address: `192.168.143.0/24`
   2. Allowed IP: `0.0.0.0/0`

| Service Provider | Location | Name | Public IP | Private IP | Purpose |
|----|----|----|----|----|----|
| Tencent Cloud | SG | bayes | (secret) | 192.168.141.1 / 192.168.142.1 / 192.168.143.1 | Central Router |


(To-be continued)



