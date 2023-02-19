---
title: "K3s/Kubernetes - From K3s to Kubernetes: Build a High availability Kubernetes Cluster with Kubeadm"
date: 2023-02-19T22:42:17+08:00
lastmod: 2023-02-19T22:42:17+08:00
draft: false
tags: ['k3s', 'kubernetes', 'containerd', 'docker']
series: ['kubernetes']
---

<!--more-->

Why we need a High availability Kubernetes? In production-ready environment, a system hang is not affordable. The Kubernetes can help us handling the containers' replica or the pod/service rescheduling. However, If there is only one control node, this may cause a big problem. Thus, when we talking about K8s's HA, usually, we are talking on the control plane's HA. I am not saying that the worker node are not important, or do not need HA, but, more importantly, is the control nodes' safety.

## Before,

The prerequisites of build a high availability K8s cluster:

1. Three or more machines that meet K8s's minimum requirements for the control-plane nodes. The quantities of control nodes usually are an odd numbers (to avoid split-brain). Thus, the minimum number is three.
2. Three or more machines that meet K8s's minimum requirements for the worker nodes. 
3. Full network connectivity between all machines in the cluster 
4. Superuser privileges on all machines

Here is my nodes:

| Hostname | IP address | Usage |
| :------: | :--------: | :---: |
| newton | 192.168.101.1 | load balancer |
| cantor | 192.168.102.1 | control-plane |
| gauss | 192.168.102.2 | control-plane | 
| freud | 192.168.103.1 | control-plane | 
| hilbert | 192.168.102.3 | worker |
| einstein | 192.168.104.1 | worker | 
| bohr | 192.168.104.2 | worker |  

As you can see, there are three control-plane, three worker, and one load-balancer.

## Installation

First, we need to modify the host `/etc/hosts` to map IP address to host names: 

```bash
newton    192.168.101.1
cantor    192.168.102.1
gauss     192.168.102.2
freud     192.168.103.1
hilbert   192.168.103.1
einstein  192.168.104.1
bohr      192.168.104.2
```

**This step** is important, without this step, the `etcd` cluster may be failed to establish.

Modify the kernel parameters and install the tools we need:

* ipvsadm 
* netfilter
* containerd
* kubeadm
* kubelet
* kubectl

```bash
echo "=== install ipvsadm ==="
sudo apt-get install ipvsadm -y 
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack
cat <<EOF | sudo tee /etc/modules-load.d/ipvs.conf
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF
sudo sysctl --system
echo "done"

echo "=== load overlay & br_netfilter, setup netfilter ==="
sudo modprobe overlay && sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
echo "done"

echo "=== ip forwarding ==="
cat <<EOF | sudo tee /etc/sysctl.conf
kernel.sysrq = 1
net.ipv6.conf.all.disable_ipv6=0
net.ipv6.conf.default.disable_ipv6=0
net.ipv6.conf.lo.disable_ipv6=0
kernel.printk = 5
EOF

echo "=== install containerd ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.bfsu.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update && sudo apt-get -y install containerd.io
sudo mkdir -p /etc/containerd && sudo containerd config default | sudo tee /etc/containerd/config.toml
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
debug: false
EOF
sudo sed 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml > .etc.containerd/config.toml
echo "done"

echo "=== install kubeadm kubelet kubectl ==="
sudo apt install -y apt-transport-https ca-certificates curl
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add - 
echo 'deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main' | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get -y install kubelet kubeadm kubectl
echo "install kubelet kubeadm kubectl...done"

echo "start kubelet"
sudo systemctl enable --now kubelet
```

Run the above script on every machines, for the worker nodes, you may not install the `kubeadm`, `kubelet` and `kubectl`. 

Install the HAproxy in `newton - 192.168.101.1`

```bash
sudo apt-get install haproxy -y

## put this text in /etc/haproxy/haproxy.cfg
frontend kube-apiserver
  bind 192.168.101.1:6443
  mode tcp
  option tcplog
  default_backend kube-apiserver

backend kube-apiserver
    mode tcp
    option tcp-check
    balance source
    server k8s-master1 192.168.102.1:6443 check fall 3 rise 2
    server k8s-master2 192.168.102.2:6443 check fall 3 rise 2
    server k8s-master2 192.168.103.1:6443 check fall 3 rise 2
```

Run the `kubeadm init` in the first control node, here is my modified script:

```bash
sudo kubeadm init \
	--kubernetes-version 1.26.0 \                
	--control-plane-endpoint 192.168.101.1:6443 \
	--apiserver-advertise-address 192.168.102.1 \
	--upload-certs \
	--service-cidr=10.96.0.0/12 \    # (optional)
	--pod-network-cidr=10.244.0.0/16 \  # (optional)
	--image-repository registry.cn-hangzhou.aliyuncs.com/google_containers \ 
        --v 5
```

where `--control-plane-endpoint` should be the load-balancer's IP, and `--apiserver-advertise-address` should be local IP; `--image-repository` is specify the repository, which is helpful for the user who cannot access `registry.k8s.io`.

Wait for a while, if you can see the output like this, it means that you have successfully install the Kubernetes on the first machine:

```bash 
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join 192.168.101.1:6443 --token xxxxxxxxxxxxxxxxxxxxxxxxx \
	--discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx \
	--control-plane --certificate-key xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.101.1:6443 --token xxxxxxxxxxxxxxxxxxxxxx \
	--discovery-token-ca-cert-hash sha256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

This output show three points:

1. How to load the `KUBECONFIG` to current user's home directory
2. How to add worker nodes to this cluster
3. How to add other control-plane to this cluster

You can see that the output only give one certificate for worker/control node, however, we have multiple work/control nodes, thus, we need to generate token and certificates for each of them:

1. For the worker node: `sudo kubeadm token create --print-join-command`
2. For other control-plane node: `echo "$(sudo kubeadm token create --print-join-command) --control-plane --certificate-key $(sudo kubeadm init phase upload-certs --upload-certs | tail -1)"`

Copy the output to each corresponding nodes and run the script, wait for a while and you can see it works.

## Troubleshooting

1. How to Install Helm for the user who cannot access `GitHub`: `wget https://goodrain-pkg.oss-cn-shanghai.aliyuncs.com/pkg/helm && chmod +x helm && sudo mv helm /usr/local/bin/`
2. How to change node's `InternalIP`: Go to `/var/lib/kubelet/kubeadm-flags.env`, add `--node-ip=xxx.xxx.xxx.xxx` at the end of `BELET_KUBEADM_ARGS` and `sudo systemctl restart kubelet`
