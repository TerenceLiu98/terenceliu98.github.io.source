---
title: "👨‍💻 My Personal Experimental Network: L-Net 1.2"
date: 2022-12-26T00:16:21+08:00
draft: true
math: true
tags: ['networking', 'wireguard', 'BGP', 'experimental network']
---

## Before

In the previous project: [Homelab]({{< ref "/post/lnet-2" >}} "My Personal Experimental Network"), I upgraded my configuration on the L-Net, where I tried eBGP and iBGP for the routing exchange between different subnet.

![L-Net 1.1](https://s3.cklau.cc/outline/uploads/f96d0f35-cf0a-46bd-aeca-b1a1ac9052c9/fee27882-b91c-4a86-b6fa-cb4f2e779982/lnet.png)

However, since, there are too many interface in the backbone device. In this post, I tried to build a overlay network with VXLAN over Wireguard. 

## VXLAN 

> VXLAN, Virtual eXtensible LAN is a network virtualization technology that attempts to address the scalability problems associated with large cloud computing deployments. It uses a VLAN-like encapsulation technique to encapsulate OSI layer 2 Ethernet frames within layer 4 UDP datagrams, using 4789 as the default IANA-assigned destination UDP port number.

In short, it is a extension for VLAN where VLAN only use 12 bit and can only cantains 4094 VLANs, however, VXLAN use 24-bit (VNI, vxlan network identfier) which can allows more vlan as it has a large MAC address tables. However, in my scenario, I build vxlan over wireguard just because vxlan interface is on layer 2 where it contains MAC address which provide more flexibility, e.g. multicast, broadcast, and etc..

### Point to Point VXLAN

Assumes that there are two machines: A wth `192.168.100.100/32` and B with `192.168.100.101/32`, and we want to create a overlay CIDR `10.100.0.0/24`.  To do so, first we need to create the vxlan interface `vxlanAB` in each machine, assign the ip to the interface and set up the interace:

```bash
# for machine A
ip link add vxlanAB type vxlan id 42 dstport 4789 remote 192.168.100.101 local 192.168.100.100 dev eth0
ip addr add 10.100.0.1/24 dev vxlanAB
ip link set vxlanAB up

# for machine B
ip link add vxlanAB type vxlan id 42 dstport 4789 remote 192.168.100.100 local 192.168.100.101 dev eth0
ip addr add 10.100.0.2/24 dev vxlanAB
ip link set vxlanAB up

# try to ping from A to B 
ping 10.100.0.2
```

### Multicast VXLAN 

If we have three machines, A wth `192.168.100.100/32`, B with `192.168.100.101/32` and C with `192.168.100.102/32`. We can us VXLAN's multicast for auto dscovery by adding the vtep into the multicast group

```bash
# for machine A
ip link add vxlanABC type vxlan id 42 dstport 4789 group 239.1.1.1 dev eth0
ip addr add 10.100.0.1/24 dev vxlanABC
ip link set vxlanABC up

# for machine B
ip link add vxlanABC type vxlan id 42 dstport 4789 group 239.1.1.1 dev eth0
ip addr add 10.100.0.2/24 dev vxlanABC
ip link set vxlanABC up

# for machine C
ip link add vxlanABC type vxlan id 42 dstport 4789 group 239.1.1.1 dev eth0
ip addr add 10.100.0.3/24 dev vxlanABC
ip link set vxlanABC up

# try to ping from A to B/C
ping 192.168.0.{2, 3}
```

Multicast VXLAN has multiple benefits, for example, auto discovery of other VTEPs shareingthe same multicast group, group bandwidth usage (packets are replaced as late as possible). However, since Wireguard is a Layer 3 tunnel, which means we cannot multicast or broadcast via it. With `ifconfig`, it shows: `wg0: flags=209<UP,POINTOPOINT,RUNNING,NOARP>  mtu 1420`. In this way we can only build the tunnel with unicast addresses, which can be easily done by using iproute2. We keep the assumption of machines' name and ip, and develop a unicast flooding:

1. Machine A will send a ARP package asking `who is 10.100.0.2`
2. this package will send to all machines' VTEP

```bash
# for machine A
ip link add vxlanABC type vxlan id 42 dstport 4789 dev eth0
bridge fdb append to 00:00:00:00:00:00 dst 192.168.100.101 dev vxlanABC
bridge fdb append to 00:00:00:00:00:00 dst 192.168.100.102 dev vxlanABC
ip addr add 10.100.0.1/24 dev vxlanABC
ip link set vxlanABC up

# for machine B
ip link add vxlanABC type vxlan id 42 dstport 4789 dev eth0
bridge fdb append to 00:00:00:00:00:00 dst 192.168.100.100 dev vxlanABC
bridge fdb append to 00:00:00:00:00:00 dst 192.168.100.102 dev vxlanABC
ip addr add 10.100.0.1/24 dev vxlanABC
ip link set vxlanABC up

# for machine C
ip link add vxlanABC type vxlan id 42 dstport 4789 dev eth0
bridge fdb append to 00:00:00:00:00:00 dst 192.168.100.100 dev vxlanABC
bridge fdb append to 00:00:00:00:00:00 dst 192.168.100.101 dev vxlanABC
ip addr add 10.100.0.1/24 dev vxlanABC
ip link set vxlanABC up
```
In this scheme, we set up a unknown-unicast traffic, where a machine recives unicast traffic intended to be delivered to a destination that is not in its forwarding information base, which means every machine in the network will receive the VXLAN message, we can use `tcpdump -vni vxlanABC` to check this message: 

```bash
20:19:56.674410 ARP, Ethernet (len 6), IPv4 (len 4), Request who-has 10.100.0.1 tell 10.100.0.2, length 28
20:19:56.706706 ARP, Ethernet (len 6), IPv4 (len 4), Reply 10.100.0.1 is-at 4e:b8:1f:b5:df:6f, length 28
```
With this solution, the machine can receives all the MAC-IP to FDB after a while.

## L-Net 1.2

Previously, I set up multiple wireguard tunnels for establishing the backbone network. However,  dozen of interfaces is ok but not elegant. Also, if we want to develop a full-mesh network, we need $2n-2$ tunnels for $n$ nodes. With the implemenetation of VXLAN over Wireguard, the underlay full-mesh network(wireguard) can be easily developed.

In wireguard configuration, we can use `PreUp/PostUp - PreDown/PostDown` command to set up ip route before/after the wireguard interface up/down. Thus, we can set up the vxlan configuration inside the wireguard configuration. Under this configuration, we no longer care about the wireguard's ip addr, instead, we are using the vxlan's ip addr. Here is an example:

```bash
[Interface]
Address = 192.168.228.166/24
ListenPort = 51820
PrivateKey = <pri-key>

Table = off
PostUp = ip link add v%i type vxlan id 49371 dstport 4789 ttl 1 dev %i
PostUp = bridge fdb append to 00:00:00:00:00:00 dst 192.168.228.128 dev v%i
PostUp = bridge fdb append to 00:00:00:00:00:00 dst 192.168.228.60 dev v%i
PostUp = ip address add 192.168.102.1/24 dev v%i
PostUp = ip address add fde9:632e:2c3f:0:62bb:bbe3:3778:37ad/64 dev v%i
PostUp = ip link set v%i up
PreDown = ip link set v%i down
PreDown = ip link delete v%i

[Peer]
# Name = gauss
PublicKey = <pub-key>
AllowedIPs = 192.168.228.128/32
PersistentKeepalive = 25
Endpoint = xxx.xxx.xxx.xxx:51820

[Peer]
# Name = hilbert
PublicKey = <pub-key>
AllowedIPs = 192.168.228.60/32
PersistentKeepalive = 25
Endpoint = xxx.xxx.xxx.xxx:51820
```
Since, the vxlan's traffic is over wireguard's interface, intuitively, I use `PostUp` in the configuration. By following the *unicast flooding* configuration, we can set up the vxlan inside the wireguard config file. For the router, we can keep `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE` in the `PostUp` as we are trying to use it as the gateway for network traffic.

Based on the experience above, I modify the [wgtools](https://github.com/TerenceLiu98/wgtools/tree/vxlan) to fit the demands. In the new branch, we did not care about the wireguard's addr, instead, we focus on the vxlan's addr. Thus, I just use `192.168.200.0/16` for generate the wg connection. For the rest part are basically the same from the previous. 