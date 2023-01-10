---
title: "K3s/Kubernetes - 配置高可用 K3s 集群"
date: 2022-09-26T00:11:21+08:00
draft: false
keywords:
  - k3s
  - kubernetes
tags: ['k3s', 'kubernetes']
description: "K3s/Kubernetes - 配置高可用 K3s 集群"
---

#  在此之前

按照 [K3s 的文档](https://doc.k3s.io) 生成基本的 K3s 集群非常容易。 让我们尝试将其修改为 High Availability Cluster。 单个服务器集群可以满足各种用例，但对于 Kubenetes 控制平面的正常运行时间至关重要的环境，我们需要高可用性配置。 高可用性有两种方式：

1. High Availability with an External DB (for example, [PostgreSQL](https://www.postgresql.org/), [MySQL](https://www.mysql.com/),  [MariaDB](https://mariadb.org/))
2. High Availability with Embedded DB ([etcd](https://etcd.io/))

我选择了第二个——带有嵌入式数据库:

## K3s 安装

### K3s 控制节点

为了设置服务器，我按照 [K3s](https://k3s.io) 的说明稍作修改，因为我想自定义网络和节点名称。 这是我用于服务器安装的命令：

```shell
curl -sfL https://get.k3s.io | K3S_TOKEN=<token>  INSTALL_K3S_EXEC="server \
                            --node-ip <wg-node-ip> \
                            --advertise-address <node-public-ip> \
                            --node-external-ip <node-public-ip> \
                            --flannel-iface wg0   \
                            --node-name <node-name> \ 
                            --cluster-init " sh -

# for whom can not access Google and Github fluently, you may try:
curl -sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn \
                            K3S_TOKEN=<token>  INSTALL_K3S_EXEC=" \
                            server https://<server-1-external-ip>:6443\
                            --node-ip <wg-node-ip> \
                            --advertise-address <node-public-ip> \
                            --node-external-ip <node-public-ip> \
                            --flannel-iface wg0   \
                            --node-name <node-name> \ 
                            --cluster-init " sh -
```
您可以在其中看到 `--node-ip` 是为节点的 IP 地址； `--advertise-address` 是 apiserver 用户向集群其他节点发布的 ip 地址； `--node-external-ip` 是为节点宣告的外部 ip 地址； `--flannel-iface`  是 flannel 所使用的网卡设备。

为了生成令牌，我使用了 `openssl rand --hex 16`.

同样，对于第二台服务器，您可以使用上面相同的配置和 IP 替换。

### K3s 计算节点

对于 K3s 计算节点，您可以简单地重用上述命令并进行修改：将 `server` 更改为 `agent`：

```shell
curl -sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_TOKEN=<TOKEN> INSTALL_K3S_EXEC="agent 
                    --server https://<server-ip>:6443 
                    --node-ip <node-wg-ip> 
                    --node-external-ip <node-wg-ip> 
                    --flannel-iface wg0 
                    --node-name <node-name>" sh -
```

在服务端和节点安装完成后，可以检查服务端是否能正确到达节点：

```shell
sudo kubectl get nodes -o wide
# NAME      STATUS   ROLES                       AGE   VERSION        INTERNAL-IP    EXTERNAL-IP     OS-IMAGE           KERNEL-VERSION      CONTAINER-RUNTIME
# cantor    Ready    control-plane,etcd,master   9h    v1.24.6+k3s1   10.210.120.2   xxx.xxx.xxx.xxx   Ubuntu 20.04 LTS   5.4.0-126-generic   containerd://1.6.8-k3s1
# hilbert   Ready    control-plane,etcd,master   9h    v1.24.6+k3s1   10.210.120.1   xxx.xxx.xxx.xxx   Ubuntu 20.04 LTS   5.4.0-126-generic   containerd://1.6.8-k3s1
# newton    Ready    worker                      9h    v1.24.6+k3s1   10.210.120.3   10.210.120.3    Ubuntu 20.04 LTS   5.4.0-126-generic   containerd://1.6.8-k3s1

sudo kubectl top nodes
# NAME      CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# cantor    445m         22%    2451Mi          71%
# hilbert   300m         7%     3942Mi          52%
# newton    90m          9%     1118Mi          56%
```

## Helm 安装

[Helm](https://helm.sh) 是的包管理器，通常我们可以使用它来下载并安装预打包的应用程序到我们的集群。 要安装它，我们可以去 hel m的 GitHub release 找到编译好的二进制文件并下载。 以下是 Linux amd64 的示例：

```shell
wget https://get.helm.sh/helm-v3.10.0-linux-amd64.tar.gz -O helm.tar.gz

tar -xvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bi

helm version
# version.BuildInfo{Version:"v3.10.0", GitCommit:"ce66412a723e4d89555dc67217607c6579ffcb21", GitTreeState:"clean", GoVersion:"go1.18.6"}
```

## 更改 Containerd 的镜像（可选）

由于某些原因，某些地区的网络可能会卡在「拉镜像」这一步，无法连接（或非常慢）某些网站，遗憾的是，gcr.io`和`quay.io`都在列表中。 因此，我们可能需要换成物理位置更近的镜像。

例如：我们可以将 `quay.io` 替换为 `https://quay-mirror.qiniu.com` 和 `gcr.io` 我们可以使用 `https://registry.aliyuncs.com`。 对于docker，我们可以使用 [Daocloud](https://www.daocloud.io/) 的脚本来更新镜像。 这可能有助于加快后续步骤中的安装过程。

## Cert-Manager 安装和配置

[Cert-Manager](https://cert-manager.io/) 是一个云原生的证书管理工具，可以帮助我们自动签署 Let's Encrypt with ACME 的 SSL/TLC 证书。 通常，Cert-Manager 提供两种质询验证 - HTTP01 和 DNS01 质询。 在这里，我们使用 DNS01，但现在，让我们先安装 Cert-Manager。

1. 添加 helm 存储库并更新 repo：`sudo helm repo add jetstack https://charts.jetstack.io && sudo helm repo update` [^1]
2. 安装证书管理器：`helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.9.1 --set installCRDs=true`（创建一个 namespace，并指定 cert-manager 的版本是 v1.9.1；安装CRD资源）
3. 检查证书管理器的状态：`sudo kubectl get pods --namespace cert-manager`

安装 cert-manager 后，我们需要去 [Cloudflare 的仪表板](https://dash.cloudflare.com/profile) 创建一个带有“编辑区域 DNS”模板的 API 令牌，设置权限：`Zone - DNS - Edit `和`Zone-Zone-Read`，其他可以默认。 请记住，API 只会显示一个，您可能需要在打开选项卡之前复制它。

创建一个 yaml（`cloudflare-api-token-secret.yaml`，您可以更改文件名）并启动一个新的 Issuer：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token-secret # you may change the name
  namespace: cert-manager
type: Opaque
stringData:
  api-token: <CF-API-TOKEN>
```

创建另一个 yaml (`ClusterIssuer.yaml`):
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns01
spec:
  acme:
    privateKeySecretRef:
      name: letsencrypt-dns01
    email: <your-email-addr>
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    - dns01:
        cloudflare:
          email: <your-cf-account-email-addr>
          apiTokenSecretRef:
            name: cloudflare-api-token-secret # need to be same with the above yaml metadata's name
            key: api-token
```

创建第三个 yaml (`Certificate.yaml`):
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
 name: <domain-name> # you may change the name
 namespace: default
spec:
 dnsNames:
  - example.com
  - "*.example.com"
 issuerRef:
   kind: ClusterIssuer
   name: letsencrypt-dns01 # Cite ClusterIssuer and use DNS01 for the challenge
 secretName: <secret-name> # the certificate with store in this cecret and you may change it 
```

然后，应用这三个yaml文件，稍等片刻。 使用 `sudo kubectl describe certificate` 检查状态。

```shell
sudo kubectl describe certificate
NAME           READY    SECRET       AGE
<domain-name>   True    <secret>      1m
```
如果准备就绪，则表示证书已颁发。

## Rancher 安装

安装 Rancher 很容易，Rancher 是一个完整的软件堆栈，适用于采用容器的团队。 它解决了管理多个 Kubernetes 集群的操作和安全挑战，同时为 DevOps 团队提供了用于运行容器化工作负载的集成工具。

类似于 Cert-Manager 的安装：

```shell
sudo helm repo add rancher-latest https://releases.rancher.com/server-charts/latest # add 
sudo helm install rancher rancher-latest/rancher --namespace cattle-system --create-namespace --set hostname=rancher.k3s.cklau.ml --set bootstrapPassword=admin --set ingress.tls.source=secret
```

然后，我们需要为 Rancher 创建一个证书和一个入口，我们可以在其中使用我们的域访问：

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: tls-rancher-ingress
  namespace: cattle-system
spec:
  secretName: <secret-name>
  commonName: '*.example.com'
  dnsNames:
  - '*.example.com'
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rancher
  namespace: cattle-system
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns01
spec:
  rules:
  - host: rancher.example.com
    http:
      paths:
      - backend:
          service:
            name: rancher
            port:
              number: 80
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - rancher.example.com
    secretName: <secret-name>
```

应用 yaml 后，我们可以检查 rancher 是否正确安装：`sudo kubectl get pods --namespace cattle-system` 并检查 `rancher.example.com`。

[^1]：出于某种原因，我遇到了 helm 的一些问题，但它们都与 `KUBECONFIG` 相关。 因此，您可以将 `KUBECONFIG` 复制到 `~/.kube/config`，这可能会解决您的问题：`sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/config`