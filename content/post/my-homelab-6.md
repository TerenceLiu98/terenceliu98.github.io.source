---
title: "Homelab: My Distributed Homelab (2)"
date: 2023-01-24T00:11:21+08:00
draft: false
math: true
tags: ['homelab','hardware']
series: ['homelab']
---

<!--more-->

## Before

I built a distributed Homelab, which is not good enough, where

1. I set up multiple endpoints to forfill the connection of Mainland China's connection and other countries' with two CDN (Tencent CDN and Cloudflare)
2. The network bottleneck is in the BGP router, where the machine in GZ is only 6Mbps 
3. Distributed storage, but not connected
4. Some of them are running Docker, and some are running K3s, which is not a bad thing, but I want a dashboard to centralized the server configuration

Thus, I need to re-design the architecture:

1. Buy a new VM, which has 100Mbps (dynamic) to replace GZ machine - Done
2. Network re-design, how to maximize the usage of each machine's bandwith
3. Set up a root DNS server, to "hijack" the local domain - based on [PowerDNS](https://www.powerdns.com/)
4. Build a distributed object storage system as the underlay of the file system - based on [MinIO](https://min.io/)

## Network Re-design


Since I have multiple different server in differnt locations, I still keep them into different ASN:

1. AS4242101 - CN-SOUTH-1 (Guangzhou, China) - 192.168.101.0/24
2. AS4242102 - CN-EAST-1 (Shanghai, China) - 192.168.102.0/24
3. AS4242103 - AP-EAST-1 (HKSAR, China) - 192.168.103.0/24
4. AS4242104 - AP-SOUTHEAST-1 (Mumbai, India) - 192.168.104.0/24

Previously, `AS4242104` is the machines located in Japan, however, during the Spring Festival, I accidentlly got the quota of ARM machines from Oracle Cloud, thus, I replace the machine X86 machines from Japan to ARM machines to Mumbai. The ARM machine is much powerful then the free-X86, where it has 2C/12G and the X86 has only 1C/1G. 

![NETWORK](https://s3.cklau.cc/outline/uploads/f96d0f35-cf0a-46bd-aeca-b1a1ac9052c9/2b48d637-5791-464d-8252-931046db7358/network.drawio.png)

Besides, I also includes the intranet of my home into the L-NET. The meaning of "include" is that they are acting as the client of L-NET.  Therefore, I desided to set up an external tunnel for the "user" side where the edge access points forward the traffic to the correct machine. However, since clients are using multiple different OS (Windows, Linux, iOS, macOS, Android), I choose [OCServ](https://ocserv.gitlab.io/www/) as the tunnel tools for clients, and keep using Wireguard as the backbone VPN. Anyconnect is more compatible to different distribution.


## Self-hosted DNS Server

My domain is hosted on Cloudflare, however, different services are on different machines and the intranet machines do not need to be routed to CF's access points. Thus, The authoritative DNS server is needed to "hijack" the domain within the L-NET. 

I set up two DNS server in different region as main/backup architecture. In this way, if one server down, the second server can be used as the backup.

I have tried [Bind9](https://www.isc.org/bind/) and [PowerDNS](https://www.powerdns.com/). Both are easy if we deploy them via Docker:

### Bind9 DNS Service

```yaml
version: "3"
services:
  bind9:
    container_name: dns-aristotle
    image: ubuntu/bind9:latest
    environment:
      - BIND9_USER=root
      - TZ=Asia/Shanghai
    ports:
      - "192.168.103.1:53:53/tcp" # bind to the wireguard IP addr
      - "192.168.103.1:53:53/udp"
    volumes:
      - ./config:/etc/bind
      - ./cache:/var/cache/bind
      - ./records:/var/lib/bind
    restart: always
```

```bash
## master DNS server - 192.168.103.1
acl internal {
    192.168.100.0/20;
};

options {
    allow-query { internal; };
    allow-transfer { internal; };
    allow-notify { 192.168.101.2; }; # 192.168.101.2 is the second DNS server
};

zone "local.cklau.cc" IN {
    type slave;
    masters { 192.168.103.1; };
    file "/etc/bind/local.cklau.cc.zone";
};
```

```bash
$TTL 2d

$ORIGIN cklau.cc.

@               IN      SOA     ns.cklau.cc. info.cklau.cc (
                                2022122800      ; serial
                                12h             ; refresh
                                15m             ; retry
                                3w              ; expire
                                3h              ; minimum ttl
                                )
		IN 	NS	ns1.cklau.cc.
		IN 	NS	ns2.cklau.cc.

ns1             IN      A       192.168.103.1
ns2             IN      A       192.168.101.2

;	-- cn-south-1
newton		IN	A	192.168.101.1
aristotle	IN	A	192.168.101.2
riemann		IN 	A	192.168.101.3
;	-- cn-east-1
hilbert		IN	A	192.168.102.1
;	-- ap-east-1
freud		IN	A	192.168.103.1
;	-- ap-south-1	
einstein	IN	A	192.168.104.1
;	-- application
auth		IN	A	192.168.100.46
git			IN	A	192.168.101.3
```

### PowerDNS 

I just follow the instructure from [Debian 11 / Ubuntu 22.04 安装 PowerDNS 和 PowerDNS-Admin 自建权威 DNS 教程](https://u.sb/debian-install-powerdns/)

## Distributed Storage

Since 