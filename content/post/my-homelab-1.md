---
title: "Homelab: My Devices"
date: 2022-07-20T00:11:21+08:00
draft: false
tags: ['homelab','networking','hardware']
---

For a long time, I held many different digital gadgets, however, I did not consider putting them into a cluster, or more precisely, setting up a platform where I can easily manage them. In this summer vacation, I started thinking of a possibility of setting up a distributed homelab.

## Why Distributed

Since I am wandering around the [big bay area](https://en.wikipedia.org/wiki/Guangdong%E2%80%93Hong_Kong%E2%80%93Macao_Greater_Bay_Area), multiple different devices are scattered.  Thus, I have to build a distributed cluster.

Here is the list of my bare metal device:

1. A Server - DELL EMC R730 (Zhuhai) : E5-2650V4 + 128GB + 240GB SSD + 600GB HDD + NVIDIA TITAN XP with 500Mbps
2. A Workstation - DELL Precision T1700 (Zhuhai) + i7-4790 + 16GB + 256GB SSD + 1T SATA HDD + NVIDIA RTX 2060Ti with 500Mbps 
3. A PC in my dormitory (Zhongshan): i5-9400f + 16GB + 256GB SSD + 256GB SSD + 2T SATA HDD + NVIDIA TITAN XP with 500Mbps
4. A home-made NAS (Shenzhen)： AMD A8-5550M + 6G DDR3 + 128G SSD + 3T SATA HDD with 1Gbps
5. A ARM Router (Shenzhen)： rk3568 + 2GB Mem + 8GB EMMC with 1Gbps
6. A ARM Router (Shenzhen)：rk3399 + 1GB Mem + 1GB + 16GB EMMC with 1Gbps

Not only the bare metal, I also own a bunch of VPS/VPC/VM/[Lighthouse](https://www.tencentcloud.com/products/lighthouse), here is the list

1. A Lighthouse server (Tencent Cloud - Guangzhou): 1C2G
2. A Lighthouse server (Tencent Cloud - Shuanghai): 2C4G
3. A Lighthouse server (Tencent Cloud - Shuanghai): 4C8G
4. A Lighthouse server (Tencent Cloud - Shuanghai): 2C2G
5. A Lighthouse server (Tencent Cloud - HKSAR): 2C4G
6. A Lighthouse server (Tencent Cloud - HKSAR): 2C4G
7. A Lighthouse server (Tencent Cloud - Singapore): 2C2G
8. A VM server (Oracle Cloud - Japan): 1C1G
9. A VM server (Oracle Cloud - Japan): 1C1G
10. A VM server (CubeCloud - HKSAR): 1C512M

After the listing, you may know why I need a distributed solution.

## Possible solution 

1. Docker Swarm
2. Kubernetes

Docker Swarm refers to a container orchestration tool that allows user to manage multiple containers within multiple nodes (a cluster). The document can be found in [here](https://docs.docker.com/engine/swarm/)

Kubernetes, a.k. K8s, is an open-source system for automating deployment, scaling and managerment of containerized applications. The introduction can be found in [here](https://kubernetes.io/docs/home/)

In general, Kubernetes is more suitable for those complex applications within the complex development/production environment, and the Docker Swarm is designed for ease of use. Based on the introduction and comparison, I design to use them simultaneously, parts of the device will be used in Docker Swarm (Dhe DS cluster) and others will be used in K8s, those who need persistance will be deployed in DS cluster and the K8s cluster is used for studying.

After the platform architecture, we need a networking solution for putting up these devices into a LAN. Intuitively, I need a VPN(Virtual Private Network) software as these device can be accessed via the WAN. Based on the VPN software, I may develop my own [SD-WAN](https://en.wikipedia.org/wiki/Software-defined_networking). Here are some SDN solutions:

1. [Zerotier](https://www.zerotier.com/)
2. [Tailscale](http://tailscale.com/): based on Wireguard
3. [Nebula](https://github.com/slackhq/nebula): A scalable overlay networking tool by Slack
4. [n2n](https://github.com/ntop/n2n): peer-to-peer VPN

After the comparison, for my home devices, I will choose Tailscale as its performance in my experiment, and for those two cluster, I will use Wireguard as I don't need to pay any fee for occupation. 







