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

 ![toppology](https://bucket.cklau.cc/outline-bucket/uploads/f96d0f35-cf0a-46bd-aeca-b1a1ac9052c9/dc88ca70-d652-4d2b-9360-931c852ea1b3/LNet.drawio.png)

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

## Configuration

### “Backbone Network”

As usual, I use the tool I wrote [wgtools](https://github.com/TerenceLiu98/wgtools) to generate Wireguard configuration. However, the tool is built for the full-mesh configuration, thus, for the “backbone” network, we need to modify the config, here is an example: in the  `sgcn`  interface, I put the following settings in `bayes`:

```bash
[Interface]
Address = 192.168.141.1/24
ListenPort = 51821
PrivateKey = <interface-prikey>

Table = off

[Peer]
# Name = cn-router
PublicKey = <peer-pubkey>
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
Endpoint = xxx.xxx.xxx.xxx:51821
```

The reason why we need to set the Address of the Interface to `/24` is that if we want the subnet of `newton` are accessible, which means that `192.168.141.2/32` need to be accessible from both sides as it is the bridge between `sgcn` and `cn` as the `sgcn` the interface is the bridge between the “external” to the “internal”. Here is the setting in `newton`:  

```mermaidjs
nterface]
Address = 192.168.141.2/24 # the same reason, this interface is the "bridge" 
ListenPort = 51821
PrivateKey = cJgoIHnDfCl+p8D7KE0jCBkRipEwe3K6Jq7FG8OTzlo=

Table = off

[Peer]
# Name = bayes
PublicKey = FF85tV+bkTWA3rNHpn+sapA/08JV7HO92y/I1P+xsRE=
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
Endpoint = xxx.xxx.xxx.xxx:51821
```

Similarly, you can modify the Address and Endpoint for `sgjp` and `sghk` .

### “Intranet/Internet”

It is easy to generate the configuration with my tools, or maybe you can generate them manually, which is not the key for the configuration. The important part is that for each node of the “intranet“, you can control which other subnet can access to you. Take `gauss` and `einstein` as an example, if you want `gauss` can access from the `einstein` then you need to add the address of `einstein` in the `newton`’s `AllowedIPs`: 

```mermaidjs
# configuration of gauss
[Interface]
Address = 192.168.10.2/32,fd0b:76a0:952b:0:afa3:e03c:fe6d:2e55/128
ListenPort = 51820
PrivateKey = <gauss-privkey>

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Name = newton
PublicKey = <newton-pubkey>
AllowedIPs = 192.168.20.1/32,192.168.248.1/32,fd0b:76a0:952b:0:e96f:2dae:80a8:b578/128
PersistentKeepalive = 25
Endpoint = xxx.xxx.xxx.xxx:51820
```

This is because `newton` is the bridge between `cn` and `jp` , or more specifically, the `einstein` ‘s traffic needs to go through the `jp → sgjp → sgcn → cn` , and for `sgcn → cn` you need to add the `192.168.20.1/32` in the `AllowedIPs` and `cn` will know that this traffic can be accepted by the `cn` and it’s routed via the `192.168.248.1/32`.   

### Wireguard Site-to-Site Configuration

For intuitive thinking, we need to connect cn-router, hksar-router, jp-router, with three different tunnel, however, from here I choose `OSPF(Open Shortest Path First, an Internal Gateway Protocol, or IGP)` and `iBGP(Interior Border Gateway Protocol)` to resolve the routing problem.
(To-be continued)



