---
title: "🧑🏿‍💻 Homelab: CloudFlare is All you Need"
date: 2024-08-10T00:11:21+08:00
draft: false
tags: ['homelab','networking','hardware', '网络', '存储', 'NAS']
series: ['homelab']
---

回到原点，又开始了一年一度的 Homelab 折腾。这一次， 打算整点「起夜」级方案 :)

<!--more-->

何为企业级方案?

大致来说，就是很稳，非常稳，十分有十二分的稳。至少是正向推理的时候是这样的，至于意外情况，不列入考虑范围{{< sidenote >}}作为企业级方案，自然需要是需要应急预案，至于能不能遇上就再议{{< /sidenote >}}。 那么作为一个 `yaml` 玩家，自然而然的选择就只会落在 Kubernetes 之上，至于如何通过 `kubeadm` 搭建高可用的 K8s 集群，不在本文讨论范围之内，请参考以前的文章。 当然，为了{{< ruby 绕过域名备案 >}}增加可访问性{{< /ruby >}}，我的第一选择当时是选择地处香港的服务器作为集群的主控节点。无法否认的是，AWS/Azure/GCP 的服务器是我等穷学生无法负担得起的，而小众商家又有着概率跑路/较高概率被攻击，本着「起夜级」的思想，最终将集群的主控节点定在了吃灰中的腾讯云广州轻量应用服务器（稳定且低延迟）。

在经过很多年的大浪淘沙之后，手里仅剩下两台机器[^1]，一台作为主存储节点 (Riemann)，而另外一台则是计算节点 (Nexus)，比较有意思的是，计算节点上其实也插了一些存储用的硬盘而存储节点上也有一些计算资源。为了不浪费存储且完成「起夜」级的中心思想，我选择了 GlusterFS 作为主要的文件系统。诚然， Ceph 才是主流，GlusterFS 这种牛夫人才是~~稳定可靠之选~~。

一切部署完毕以后，如何让身处 UTC 的我快速访问 CST 的内容则成为了下一个企业级难题。对于真正的企业来说，当然不难：
1. IPLC/IEPL 直接拉专线；但，横跨亚欧大陆，我相信也不是多少企业可以承担得起这样的专线
2. SD-WAN  依托服务商提供的全球传输网络，通过 SDN 技术到达不同的 POP 点

考虑到孑然一人的我并没有太宽裕的经费，最终没有选择十分复杂的方案，而是依托赛博菩萨[^2]的全球加速网络实现 SD-WAN 的部分功能。当然，并不是全程企业级，而是一半企业级。先来说说说「起夜」级部分：

考虑到赛博菩萨在 CST 地区的作用有限，在筛选了许久后，我选择了几个中转点：HKG/AMS/LAX。在这些地方选择廉价且响应迅速的机器，接入到我的节点之中，作为出站第一步。注意，这些机器并没有接入集群之中，只是作为中转，在一定程度上做到了隔离，因为即使这些机器沦陷/服务商跑路我的集群也不会收到太大的牵连[^3]。至于如何中转，则是 Wireguard+VxLAN 一把梭再加一点点的 TCP 以应对全球 ISP 对 UDP 的劣化。并且，我并没有将主控节点与海外机器互联，这样也降低了主控节点被攻破的风险。而至于为什么这样可以访问，就全靠 K8S 的 External IP 了:

1. 在配置 MetalLB 的时候，我们需要创建 External IP 池，常规设置中，我们一般会把那些公网可达的 IP 放进去，比如我这里的腾讯云的 IP；但在我这套方案中，仅需要把 worker 的内网 IP 放入即可：
    ```yaml
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
      metadata:
        name: ip-pool
        namespace: metallb-system
    spec:
      addresses:
      - 192.168.101.101-192.168.101.102 # Riemann 和 Nexus 的内网 IP，需要主控节点也可以访问的 IP
    ---
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
      metadata:
        name: public-ip
        namespace: metallb-system
    spec:
      ipAddressPools:
      - ip-pool
    ```
2. 配置 Ingress Controller，我目前选择的是官方的 [ingress-nginx-controller](https://github.com/kubernetes/ingress-nginx)；如果想要充分利用 IP 池中的所有 IP， 我们则需要分别创建两个 ingress controller：
    ```bash
    # 每一个 ingress controller 都是 Load Balancer， 所以一共可以拿到两个 IP
    helm upgrade --install ingress-nginx-a ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx-a --create-namespace
    helm upgrade --install ingress-nginx-b ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx-b --create-namespace
    ```
3. `IPTABLES` 一把梭，让外部服务器进行端口转发，当然，也可以选择其他工具：
    ```bash
    echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.conf
    sudo iptables -t nat -A PREROUTING -p tcp -m multiport --dport 80,443 -j DNAT --to-destination 192.168.101.101:80
    sudo iptables -t nat -A POSTROUTING -p tcp -d 192.168.101.101 -m multiport --dport 80,443 -j SNAT --to-source 192.168.101.2
    ```
三步走以后，「起夜」级的链路就构造完成了，这时只需要我们将域名解析到外部服务器的 IP 上即可访问集群内部部署的 web 服务。不过，只有三个节点怎么服务全球，还是不够全面。一个企业级的方案一定要做到全球覆盖。那此时就邀请到赛博菩萨登场了。Cloudflare 给每个用户都提供了一个隧道服务叫做 [「Cloudflare Tunnel」](https://www.cloudflare.com/products/tunnel/):

> Cloudflare Tunnel provides you with a secure way to connect your resources to Cloudflare without a publicly routable IP address. With Tunnel, you do not send traffic to an external IP — instead, a lightweight daemon in your infrastructure (cloudflared) creates outbound-only connections to Cloudflare’s global network. Cloudflare Tunnel can connect HTTP web servers, SSH servers, remote desktops, and other protocols safely to Cloudflare. This way, your origins can serve traffic through Cloudflare without being vulnerable to attacks that bypass Cloudflare.
> 摘自 [Cloudflare Tunnel 官方文档](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)

这里提到，Cloudflare 实际上是从内网直接到 Cloudflare 的边缘节点，而不需要服务部署在一个公网可达的服务器上，但是在这里，我在直将三个公网可达的服务器作为连接边缘节点和源服务器的中间跳板，而其中的跳板就是 CF Tunnel。这样布置的好处是，我们的回源路径不需要经过纷繁复杂的公网经过无数的 pop 和无尽的绕路，被 BGP 转的晕头转向，最终遗失在太平洋；流量在进入 CF Tunnel 会去寻找离自己最近的“源”站，然后下一跳就是”源“站（集群）了[^4]。 Tunnel 会自动寻找最近的“源”站也是官方文档提及的：
> By design, replicas(是指 cloudflared replicas) do not offer any level of traffic steering (random, hash, or round-robin). Instead, when a request arrives to Cloudflare, **it will be forwarded to the replica that is geographically closest**. If that distance calculation is unsuccessful or the connection fails, we will retry others, but there is no guarantee about which connection is chosen.

对于 Cloudflare 来说，可能付费用户需要的是 traffic steering，但实际上，我需要的是 geo steering。自此：
1. 美洲用户大概率会进入隧道到达 LAX，然后跨越太平洋回源；
2. 欧洲和部分亚细亚用户会到 AMS，然后走京德线路回源；
3. 其他亚细亚和大洋洲用户会到达 HKG，然后回源；
4. 目前，没有测试过非洲的体验，所以暂且没有结果。

理论上似乎会有加速，那实际上测试呢？我用 [dotcom-tools](https://www.dotcom-tools.com/) 对网站打开速度进行测试，选取了马德里、华盛顿和香港进行测试，效果如下图，可以看到三地平均访问速度确实是有所提升，而其中华盛顿地区的测试不升反降，这个可能是本身测试节点到“源”站的路由比 CF 的好吧，也有可能 CF 带这些流量去了欧洲，这就不得而知了。不过总体而言，实验应当算作成功。

<table>
    <tr>
        <td><img src="https://32cf906.webp.li/2024/08/media-before-cf.png" /></td>
        <td><img src="https://32cf906.webp.li/2024/08/media-cf-speedup.png"/></td>
    </tr>
    <tr>
        <td><center>Before</center></td>
        <td><center>After</center></td>
    </tr>
</table>

自此，全球加速部分到此结束。大概的有点有如下几条：
1. 任意添加接入点：我们仅需要让新增节点和集群建立通畅连接，即可随时增（删）接入点，主要目的是用来应对不同网络波动和 VPS 服务商 SLA 情况。
2. 隐藏源站和降低费用：如果使用 GeoDNS 和 CDN 进行加速，则需要支付 DNS 分区解析和对应 CDN 的费用。总所周知，赛博菩萨的 DNS 没有分区解析，Geo steering 需要付费。

当然，实际上方案依旧存在缺陷，例如，接入点和集群连接需要手动配置，CF 路由黑箱。当然，前者是我的问题，后者也是我的问题。


[^1]: 实际上有些后悔，为什么不是存储节点叫做 Nexus 计算节点 Riemann，这样才符合人设。
[^2]: 赛博菩萨之所以是菩萨，是因为善。
[^3]: 这也是为什么我选择腾讯云的服务器作为主控节点的原因，毕竟是大厂。
[^4]: 这里提到的「下一跳」是指 overlay 网络里的，实际上还是需要经过很多 pop，只不过因为都在这个大内网里不会被展示出来。