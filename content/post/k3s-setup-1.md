---
title: "K3s/Kubernetes - 快速启动 K3s 服务"
date: 2022-09-24T00:11:21+08:00
lastmod: 2022-09-26T00:11:21+08:00
draft: false
tags: ['k3s', 'kubernetes', 'wireguard']
---


## 在此之前

K3s是一个更适合 Edge/IoT/CI/ARM 场景/设备的轻量级 Kubernetes。 通常，对于人来说，我们没有像 24c 服务器甚至更高的多个高性能设备。 因此，K3s 是我们学习如何设置 kubernetes 集群的一种方式。

对我来说，多年前我是一个裸机狂热者，但是当我对虚拟化和容器有了更多的了解后，我变成了一个 Docker 用户。 这些操作系统级别的虚拟化在我们尝试迁移我们的服务时更加方便，例如博客迁移、身份验证迁移等。

## 部署环境

这是我的设备列表：

| 设备名称 | 设备所在地 | 设备规格 | OS | Network | IP |
| :-------: | :------: | :-----------: | :--: | :-----: | :--: |
| hilbert(server) | Tencent Cloud (SH-CN) | 4C8G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 1.xx.xx.xx + 192.168.36.1 | 
| cantor(server) | Tencent Cloud (SH-CN) | 2C4G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 110.xx.xx.xx + 192.168.36.2 |
| newton(worker) | Tencent Cloud (GZ-CN) | 1C2G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 119.xx.xx.xx + 192.168.36.3 |

我想通过 Wireguard 设置 K3s 的原因是因为可扩展性。 一旦通过 Wireguard，我可以轻松地将其他服务器添加到 LAN 中并作为 K3s 集群的节点，即使该节点没有网络问题，而且 Wireguard 足够安全（我认为），我不必考虑节点的互连时导致的安全问题。

更改服务器名称：

```shell
sudo hostnamectl --static set-hostname node1 && sudo hostnamectl  set-hostname node1
sudo hostnamectl --static set-hostname node2 && sudo hostnamectl  set-hostname node2
sudo hostnamectl --static set-hostname node3 && sudo hostnamectl  set-hostname node3
```

### 设置 Wireguard

我写了一个[工具](https://github.com/TerenceLiu98/wgtools) 可以帮助我设置 Wireguard 配置（你也可以试试这个工具，欢迎任何问题或拉取请求）

1. 创建网域: `python add.py network wg0`
2. 添加节点: `python add.py node wg0 node1` & `python add.py node wg0 node2` & `python ad.py node wg0 node3`
3. 修改节点 Endpoint: `python modify wg0 node1 Endpoint 1.xxx.xxx.xxx` & `python modify wg0 node2 Endpoint 110.xxx.xxx.xxx` `python modify wg0 node3 Endpoint 119.xxx.xxx.xxx`
4. 生成配置: `python generate.py wg0 node1` & `python generate.py wg0 node2` & `python generate.py wg0 node3`
5. 将 Wireguard 配置复制到每个节点: `scp node1.conf user_name@node1:~/wg0.conf` & `scp node2.conf user_name@node2:~/wg0.conf` & `scp node2.conf user_name@node2:~/wg0.conf`


将静态条目添加到 `/etc/hosts`：

```shell
sudo cat > /etc/hosts <<EOF
192.168.1.1 node1
192.168.1.2 node2
192.168.1.3 node3
EOF
```