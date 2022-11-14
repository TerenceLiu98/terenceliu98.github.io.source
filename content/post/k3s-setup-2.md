---
title: "K3s/Kubernetes - 配置高可用 K3s 集群"
date: 2022-09-26T00:11:21+08:00
draft: false
tags: ['k3s', 'kubernetes']
---


Generating a basic K3s cluster is quite easy by following the [K3s's Doc](https://doc.k3s.io). let try to modify it into High Availability Cluster. Single server cluster can meet a variety of use cases, but for environments where uptime of the Kubenetes control plane is critical, where we need the High Availability configuration. There are two ways for High Availability:

1. High Availability with an External DB (for example, [PostgreSQL](https://www.postgresql.org/), [MySQL](https://www.mysql.com/),  [MariaDB](https://mariadb.org/))
2. High Availability with Embedded DB ([etcd](https://etcd.io/))

I chose the second one - with Embedded DB.

## Enviornment

Here is the list of my device:

| Node Name | Location | Specification | OS | Network | IP |
| :-------: | :------: | :-----------: | :--: | :-----: | :--: |
| hilbert(master) | Tencent Cloud (SH-CN) | 4C8G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 1.xx.xx.xx + 192.168.36.1 | 
| cantor(master) | Tencent Cloud (SH-CN) | 2C4G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 110.xx.xx.xx + 192.168.36.2 |
| newton(agent) | Tencent Cloud (GZ-CN) | 1C2G | Ubuntu 20.04 LTS | Pbulic IP + Wireguard | 119.xx.xx.xx + 192.168.36.3 |

## K3s Installation

### K3s Server Node 

To set up the Server, I follow the instruction from [K3s](https://k3s.io) with a little modification, since I want to customize the network and node name. Here is the command I used for server-installation:

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
where you can see that `--node-ip` is the ip address to advertise for node; `--advertise-address` is the ip address that apiserver user to advertise to members of the cluster; `--node-external-ip` is the external ip address to advertise for node; `--flannel-iface` is to override the default flannel interface.

For whom can not access Google and GitHub fluently, you may try:

To generate the token, I used `openssl rand --hex 16`.

Similarly, for the second server, you can use the same configuration above with IPs' substitution. 

### K3s node

For the K3s node, you can simply reuse the above command with a modification: change `server` to `agent`: 

```shell
curl -sfL https://rancher-mirror.oss-cn-beijing.aliyuncs.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn K3S_TOKEN=<TOKEN> INSTALL_K3S_EXEC="agent 
                    --server https://<server-ip>:6443 
                    --node-ip <node-wg-ip> 
                    --node-external-ip <node-wg-ip> 
                    --flannel-iface wg0 
                    --node-name <node-name>" sh -
```

After the installation of the server and node, you may check whether the server can reach the node correctly:
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

## Helm Installlation

[Helm](https://helm.sh) is the package manager of kubernetes, where usually we can use it to download and install pre-packed applications to our cluster. To install it, we can go to helm's GitHub release to find the compiled binary file and download it. Here is an example for the Linux amd64:

```shell
wget https://get.helm.sh/helm-v3.10.0-linux-amd64.tar.gz -O helm.tar.gz

tar -xvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bi

helm version
# version.BuildInfo{Version:"v3.10.0", GitCommit:"ce66412a723e4d89555dc67217607c6579ffcb21", GitTreeState:"clean", GoVersion:"go1.18.6"}
```

## Change the mirrors for Containerd (Optional)

For some reason, the China region's network may be stuck and cannot connect (or very slow) to some of the website, sadly, gcr.io` and `quay.io` are inside the list. Thus, we may need to change to the China's mirrors.

For example: we can subsitute the `quay.io` with `https://quay-mirror.qiniu.com` and `gcr.io` we can use `https://registry.aliyuncs.com`. For the docker, we can use the [Daocloud](https://www.daocloud.io/)'s script to update the mirrors. This may help speeding up the installication process in the after step.

## Cert-Manager Installation and Configuration

[Cert-Manager](https://cert-manager.io/) is a cloud-native certificate management tool which can help us automatically sign SSL/TLC certificate from Let's Encrypt with ACME. Typically, Cert-Manager offers two challenge validations - HTTP01 and DNS01 challenges. In here, we use DNS01, but for now, let us install the Cert-Manager first.

1. Add the helm repository and update repo: `sudo helm repo add jetstack https://charts.jetstack.io && sudo helm repo update` [^1]
2. Install the cert-manager: `helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.9.1 --set installCRDs=true` (create a NS; cert-manager's version is v1.9.1; install the CRD resources)
3. Check the cert-manager's status: `sudo kubectl get pods --namespace cert-manager`

After installing the cert-manager, we need to go to [Cloudflare's dashboard(https://dash.cloudflare.com/profile) to create a API token with "Edit zone DNS" template, set permission: `Zone - DNS - Edit` and `Zone - Zone - Read`, other can be default. Remember that the API will only show onee, you may need to copy it before turn of the tab.

Create a yaml (`cloudflare-api-token-secret.yaml` and you may change the file name) and start a new Issuer:

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

Create another yaml (`ClusterIssuer.yaml`):
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

Create the third yaml (`Certificate.yaml`):
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

Then, apply these three yaml file, and wait for a while. Use `sudo kubectl describe certificate` to check the status.

```shell
sudo kubectl describe certificate
NAME           READY    SECRET       AGE
<domain-name>   True    <secret>      1m
```
If it is ready, it means that the certificate is Issued.

## Rancher Installation

It is easy to install the Rancher, Rancher is a complete software stack for teams adopting containers. It addresses the operational and security challenges of managing multiple Kubernetes clusters, while providing DevOps teams with integrated tools for running containerized workloads.

Similar to the installation of Cert-Manager:

```shell
sudo helm repo add rancher-latest https://releases.rancher.com/server-charts/latest # add 
sudo helm install rancher rancher-latest/rancher --namespace cattle-system --create-namespace --set hostname=rancher.k3s.cklau.ml --set bootstrapPassword=admin --set ingress.tls.source=secret
```

Then, we need to create a certificate and an ingress for Rancher where we can use our domain to access:

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

After apply the yaml, we may check whether the rancher install properly: `sudo kubectl get pods --namespace cattle-system` and check `rancher.example.com`. 

[^1]: For some reason, I met some problems with helm but they all correlated to the `KUBECONFIG`. Thus, you may copy the `KUBECONFIG` to `~/.kube/config` and this may solve your problem: `sudo cat /etc/rancher/k3s/k3s.ymal > ~/.kube/config`


