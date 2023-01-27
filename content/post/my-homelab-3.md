---
title: "Homelab: My Network setup"
date: 2022-07-21T00:11:21+08:00
draft: false
tags: ['homelab','networking','wireguard']
series: ['homelab']
---

<!--more-->

## In General

![Network](https://bucket.cklau.cc/outline-bucket/uploads/f96d0f35-cf0a-46bd-aeca-b1a1ac9052c9/d9c7631a-cd68-4016-903c-27c804edce1a/server.png)


## Tools I use 

I choose Wireguard since it’s fast because of its light design, and it’s secure because it uses the best cryptographic tools available. However, for each time, the user may need to consider a SUBNET for the wireguard and a IP for each node, for me, it is every annoyed, as I have too many subnet need to be configured. Thus, I build a little tool: [wgtools](https://github.com/TerenceLiu98/wgtools)


### How to use

* prerequest:
	* clone the code into local directory: `git clone  https://github.com/TerenceLiu98/wgtools.git`
	* install the requirement: `python -m pip install -r requirements.txt`
	* install the wireguard before using the tool

* configuration:
	* new a ipv4 pool: `python add.py network wg0`
	* new (a) peer(s): `python add.py node wg0 node1` + `python add.py node wg0 node2` + `python add.py node wg0 node3`
	* check the information: `cat wg0.conf`
	* modify the endpoint: `python modify.py wg0 node1 Endpoint 1.1.1.1`
	* generate configuration for each node: `python generate.py wg0 node1` + `python genenrate.py wg0 node2` + `python generate wg0 node3`

* script
	* copy the configuration to the machine
	* use `wg-quick` to quick start the wireguard
	* check the connectivity via `ping

### Why not WAN

Yes, using the public IP is convenient but you may counter some security problem as there are multiple ports need to exposed for the communication between nodes (both Kubernetes and Docker Swarm). To avoid this, I can easily use a VPN to avoid the problem, thus, why not. 


## What wiregurad can do

To be continued.