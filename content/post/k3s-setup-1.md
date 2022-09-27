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
| tx-mumbai-1 | Tencent Cloud (Mumbai) | 2C2G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 101.xx.xx.xx + 192.168.36.1 | 
| tx-mumbai-2 | Tencent Cloud (Mumbai) | 2C2G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 129.xx.xx.xx + 192.168.36.2 |
| tx-hksar-1 | Tencent Cloud (Hongkong SAR) | 2C2G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 43.xx.xx.xx + 192.168.36.3 |

The reason I would like to setup K3s over Wireguard is because of the expandability. Once over the wireguard, I could add other VPS/Server into the LAN and as a node of the K3s cluster easily even if the node does not has a networking problem and as the Wireguard is safe enough I do not have to consider the security issues of nodes' interconnection.

### Set up Wireguard

I write a [tool](https://github.com/TerenceLiu98/wgtools) which can help me set up the Wireguard configuration (you can also try this tool, and any issue or pull request is welcomed)

## K3s Server 

To set up the Master/Server, I follow the instruction from [K3s](https://k3s.io) with a little modification, since I want to customize the network and node name. Here is the command I used for server-installation:

```shell
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip <wg-node-ip> \
                                --advertise-address <node-public-ip> \
                                --node-external-ip <node-public-ip> 
                                --flannel-iface wg0 \
                                --node-name <node-name>" sh -
```

where you can see that `--node-ip` is the ip address to advertise for node; `--advertise-address` is the ip address that apiserver user to advertise to members of the cluster; `--node-external-ip` is the external ip address to advertise for node; `--flannel-iface` is to override the default flannel interface.

Notice: if you meet any problem of starting the k3s after run the script, go check the systemd file: `/etc/systemd/system/k3s.service`, you may meet the "quotation mark" problem, where simply delete all the single quotation mark and reform the command like this: 

```shell
ExecStart=/usr/local/bin/k3s server \
	--node-ip <wg-node-ip> \
	--advertise-address <node-public-ip> \
	--node-external-ip <node-public-ip> \
	--flannel-iface wg0 \
	--node-name mumbai-1
```

## K3s node

For the K3s node, first we need the server's token: `sudo cat /var/lib/rancher/k3s/server/node-token`, then, put the token into the script:

```shell
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --server https://<wg-server-ip>:6443 \
                                --token <server-token> \
                                --node-ip <wg-node-ip> \
                                --node-external-ip <wg-node-ip> \
                                --flannel-iface wg0 \
                                --node-name <node-name>" sh -
```

Again, you may reach the "quotation mark" problem.

## After

After setting up both server and node, you may check whether the server can reach the node correctly:

```shell
sudo kubectl get nodes -o wide

# NAME             STATUS   ROLES                  AGE    VERSION        INTERNAL-IP    EXTERNAL-IP     OS-IMAGE           KERNEL-VERSION      CONTAINER-RUNTIME
# mumbai-1         Ready    control-plane,master   113m   v1.24.4+k3s1   192.168.36.1   xxx.xxx.xxx.xxx   Ubuntu 20.04 LTS   5.4.0-126-generic   containerd://1.6.6-k3s1
# mumbai-2-agent   Ready    <none>                 112m   v1.24.4+k3s1   192.168.36.2   192.168.36.2    Ubuntu 20.04 LTS   5.4.0-126-generic   containerd://1.6.6-k3s1

sudo kubectl top nodes
# NAME             CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# mumbai-1         83m          4%     1028Mi          51%
# mumbai-2-agent   36m          1%     754Mi           38%
```
If you see this kind of result, congratulations, you have set up a K3s cluster!

