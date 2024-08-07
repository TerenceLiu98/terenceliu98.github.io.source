---
title: "👨‍💻 My Personal Experimental Network: L-Net 1.1"
date: 2022-12-26T00:16:21+08:00
draft: false
math: true
tags: ['networking', 'wireguard', 'BGP', 'experimental network']
series: ['networking']
---

<!--more-->

## Before

In the previous project: [Homelab]({{< ref "/post/lnet-1" >}} "My Personal Experimental Network"), I create a experimental network and I call it L-Net 1.0. However, I am trying to redesign the network as I am trying to maximize the usage of all the bandwidth,  route auto-correction, and manage the resources based on one machine outside the cluster. Here is the diagram:

Here, as usual, I made three network areas, “East-Asia-CN” is `192.168.101.0/24` , “Southeast-Asia-HKSAR“ is `192.168.102.0/24`, and “East-Aisa-JP“ is `192.168.103.0/24`.  As you can see, I draw three routers in the diagram, but it is four, and I will explain why. For the backbone network, For Mainland China $\Leftrightarrow$ HKSAR is `10.255.101.0/24`,  Mainland China $\Leftrightarrow$ Japan is `10.255.102.0/24` and Japan $\Leftrightarrow$ HKSAR  is `10.255.103.0/24`. One more thing, I combine my Singapore server into the “Southeast-Asia-HK“ network as I only have one server in South Asia, and the combination can reduce multiple configurations. 

## HOWTO

## Wireguard

Yes, I still use my script [wgtools](https://github.com/TerenceLiu98/wgtools) to generate the Wireguard configuration. However, if we try to use iBGP inside the network area, we need to create a star-shaped network and disable changing the routing table. Here is an example:

```bash
#################################
#### Configuration of router ####
#################################
[Interface]
Address = 192.168.101.1/32,fd4f:3f1f:d743:0:ccce:d274:c262:ff9b/128
ListenPort = 51820
PrivateKey = <router-private-key>

Table = off

[Peer]
# Name = node-1
PublicKey = <node-1-public-key>
AllowedIPs = 192.168.101.2/32,fd4f:3f1f:d743:0:f8e3:c5be:c0fa:dd2f/128
PersistentKeepalive = 25
Endpoint = <node-1-ip-address>:51820

[Peer]
# Name = node-2
PublicKey = <node-3-public-key>
AllowedIPs = 192.168.101.3/32,fd4f:3f1f:d743:0:8174:fd0f:3627:4c50/128
PersistentKeepalive = 25
Endpoint = <node-2-ip-address>:51820

#################################
#### Configuration of node-1 ####
#################################
[Interface]
Address = 192.168.101.1/32,fd4f:3f1f:d743:0:ccce:d274:c262:ff9b/128
ListenPort = 51820
PrivateKey = <node-1-private-key>

Table = off

[Peer]
# Name = router
PublicKey = <router-public-key>
AllowedIPs = 0.0.0.0/0,::/0
PersistentKeepalive = 25
Endpoint = <rnode-1-ip-address>:51820
```

As you can see that we set `Table = off`  For routers, we need to set the connection to other nodes; for other nodes, we need to set the `AllowedIPs = 0.0.0.0/0, ::/0` to allow routing based on the iBGP. 

### eBGP and iBGP

After setting up the Wirewuard, we need to set up the eBGP and iBGP. Let's set up the iBGP first: 

```bash
sudo apt-get install bird2 # install bird2 in both routers and nodes
```

Create template `sudo vim /etc/bird/template.conf`, by creating a template we can import the template for duplicated setting:

```bash
# https://bird.network.cz/?get_doc
define LOCAL_ASN = <net-area-ASN>;

define NET = [] # mark down all the ip in all the net area

template bgp tpl_ibgp {
    local as LOCAL_ASN; # 
    med metric on;
    path metric on;
    error wait time 5, 10; # Minimum and maximum delay in seconds between a protocol failure (either local or reported by the peer) and automatic restart. Doesn not apply when disable after error is configured. If consecutive errors happen, the delay is increased exponentially until it reaches the maximum. Default: 60, 300.
    error forget time 20; # Maximum time in seconds between two protocol failures to treat them as a error sequence which makes error wait time increase exponentially.
    multihop 1;
    graceful restart on;

    ipv4 {
        import filter {
            if net ~ NET then accept;
            reject;
        };
        export filter {
            if net ~ NET then accept;
            reject;
        };
        next hop self;
        gateway recursive; # since we are using multihop we cannot use gateway direct
    };
}
```
Set up the `/etc/bird/bird.conf`:

```
#############
# for router:
router id <router-id>;

include "/etc/bird/template.conf";

protocol device {
    scan time 5;
}

protocol kernel {
    ipv4 {
        import all;
        export all;
    };
    merge paths on;
}

protocol direct {
    ipv4;
    interface "<wg-interface-name>";
}

protocol static cn {
    ipv4;
    route <node-1-ip> via "<wg-interface-name>";
    route <node-2-ip> via "<wg-interface-name>";
}

protocol bgp cantor from tpl_ibgp {
    neighbor <node-2-ip> internal;
    rr client;
}


#############
# for node 1:
router id <node-1-id>;

include "/etc/bird/template.conf";

protocol device {
    scan time 5;
}

protocol kernel {
    ipv4 {
        import all;
        export all;
    };
    merge paths on;
}

protocol direct {
    ipv4;
    interface "<wg-interface-name>";
}

protocol static cn {
    ipv4;
    route <router-ip> via "<wg-interface-name>";
}

protocol bgp cantor from tpl_ibgp {
    neighbor <router-ip> internal;
    rr client;
}
```

Here you can see that we create a static route between the router and node-1, and this could be seen as the `PostUp = ip addr add <local-ip> peer <remote-ip> dev %i`  in Wireguard configuration.  After the configuration of bird we can simply use `sudo birdc c && sudo birc show protocols` to check whether the iBGP is established.

For the eBGP part, it is similar to the iBGP part, we need a template and settings:

```bash
### At Template in Both router-1 and router-2
# https://bird.network.cz/?get_doc
define LOCAL_ASN = <net-area-ASN>;

define NET = [] # mark down all the ip in all the net area

template bgp tpl_ebgp {
    local as LOCAL_ASN;
    path metric 1;
    direct;
    graceful restart on;

    ipv4 {
        import filter {
            if net ~ NET then accept;
            reject;
        };
        export filter {
            if net ~ NET then accept;
            reject;
        };
        next hop self;
        gateway direct;
    };

}
```

For the settings:

```bash
############# /etc/bird/bird.conf
# for router-1:
# ... add a new protocol bgp 

protocol bgp area1_area_2 from tpl_ebgp {
    neighbor <router2-ip> as router2_ASN;
}

############# /etc/bird/bird.conf
# for router-2:
# ... add a new protocol bgp 

protocol bgp area_2_area_1 from tpl_ebgp {
    neighbor <router1-ip> as router1_ASN;
}
```

After the configuration, we can easily build a link-local and pseudo-link-global network by using the BGP protocol. In these configurations, I use IP address as the filter, you may try ASN as the filter, here is an example,

```bash
filter FILTER_ASN
int set accept_asn; {
    accept_asn = [area1_ASN, area2_ASN, area3_ASN];
    if bgp_path.last ~ accept_asn then {
        accept;
    }
    reject;
}

template bgp tpl_ebgp {
    local as LOCAL_ASN;
    path metric 1;
    direct;
    graceful restart on;

    ipv4 {
        import filter FILTER_ASN;
        export filter FILTER_ASN;
        next hop self;
        gateway direct;
    };

}
```

Here are some points you may concern about:

1. If your router is needed to be attached, the backbone network’s CIDR needs to be accepted by the BGP, I try multiple times but I did not fix this issue.
2. Inside a network area, all nodes are in a  star topology network and the router is the root node. This means if the router is down, the connections between nodes are also down. You may use wgsd to establish a direct connection inside the network area.


## Wireguard multiplexing?

In the standard Wireguard, each interface corresponds to one port and if we have multiple different settings configuration we may lost in the port selection or just do not remember the which port percisely link to the interface. Under this circumstance, I use [gost](https://github.com/ginuerzh/gost) to aggregate the interfaces' ports into one port.

```bash
# download the latest version from github
wget https://github.com/ginuerzh/gost/releases/download/v2.11.4/gost-linux-amd64-2.11.4.gz
gzip -d gost-linux-amd64-2.11.4.gz
sudo mv gost-linux-amd64-2.11.4 /usr/local/bin/gost && sudo chmow +x /usr/local/bin/gost

sudo cat > /etc/systemd/system/gost.service << EOF
[Unit]
Description=Gost Proxy
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/gost -C /etc/gost/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

mkdir /etc/gost
cat > /etc/gost/config.json << EOF
{
    "Debug": true,
    "Retries": 0,
    "ServeNodes": [
        "udp://:51820/127.0.0.1:51821,127.0.0.1:51822,127.0.0.1:21823"
    ]
}
EOF

sudo systemctl enable --now gost
```

Then, we can use `51820` for all three interface's connection.