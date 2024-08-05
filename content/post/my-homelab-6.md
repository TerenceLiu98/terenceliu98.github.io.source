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

### PowerDNS and Adguard Home

I just follow the instructure from [Debian 11 / Ubuntu 22.04 安装 PowerDNS 和 PowerDNS-Admin 自建权威 DNS 教程](https://u.sb/debian-install-powerdns/)

As soon as I set up the PowerDNS, I use as as one of the upstream DNS servers of my Adguard Home. With the PowerDNS, I can easily control the domain resolution inside the intranet. Here is the example of DNS setting in Adg:

```bash
[/cloud.cklau.cc/]192.168.101.2
1.1.1.1
1.0.0.1
```

## Storage and File system

Previously, I use Nextcloud as my webdrive, however, since there is a uploading limition in Cloudflare's TOS, the Nextcloud is not suitable for using CDN. I replaced it with [Seafile](https://www.seafile.com/en/home/) as it is fast and simple. Yes, NextCloud can provide more features, but its performance is not good enough, sometimes the web interface take around 5-10sec to load for each action you perform. I am not familiar with PHP thus, I just kept the default settings of the page response, which may cause the performance issue.

I migrated the storage to Seafile, which natively support block storage and end-to-end encryption. The Chunk uploading mechanism may bypass the uploading limit of Cloudflare. I test it several time by uploading cuple large files and all of them passed. (Some intrstruction says it may not, but in my case it does)

```yaml
version: '2.0'
services:
  db:
    image: mariadb:10.1
    container_name: seafile-mysql
    environment:
      - MYSQL_ROOT_PASSWORD=seafile
      - MYSQL_LOG_CONSOLE=true
    volumes:
      - ./mysql:/var/lib/mysql
    networks:
      - seafile-net
    restart: always

  memcached:
    image: memcached:1.6
    container_name: seafile-memcached
    entrypoint: memcached -m 256
    networks:
      - seafile-net
    restart: always

  seafile:
    image: seafileltd/seafile-mc:latest
    container_name: seafile
      #command: pip install requests_oauthlib
    ports:
      - "9999:80"
    volumes:
      - /mnt/storage/seafile:/shared
    environment:
      - DB_HOST=db
      - DB_ROOT_PASSWD=seafile
      - TIME_ZONE=Etc/UTC
      - SEAFILE_ADMIN_EMAIL=<admin-email>
      - SEAFILE_ADMIN_PASSWORD=<admin-password>
      - SEAFILE_SERVER_LETSENCRYPT=false
      - SEAFILE_SERVER_HOSTNAME=seafile.example.com
    depends_on:
      - db
      - memcached
    networks:
      - seafile-net
    restart: always
networks:
  seafile-net:
```

Also, seafile natively support Single-Sign-on with LDAP and OAuth2, by following the [Manual](https://manual.seafile.com/deploy/oauth/)'s instruction. The configuration path is: `/opt/seafile/conf/seahub_settings.py`.
