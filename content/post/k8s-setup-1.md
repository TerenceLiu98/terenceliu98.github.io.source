---
title: "K3s/Kubernetes - From K3s to Kubernetes: Set up a Kubernetes in a nutshell (1)"
date: 2022-10-23T00:11:21+08:00
lastmod: 2022-10-23T00:11:21+08:00
draft: false
tags: ['k3s', 'kubernetes', 'containerd', 'docker']
series: ['kubernetes']
---

<!--more-->

# Before

## What is Kuberntes 

Kubernetes, is an open-source system for automating deployment, scaling, and management of containerized applications. Usually, we call it `K8s` as there are 8 characters between `K` and `s` :).

Basically, all the application are **containerized**, and we can easily the reason why we use K8s is that the use of microservices increasing, away from traditional monolithic-type applications. As a result, containers provide the perfeet host form these individual microservices as **containers manage dependencies, are indipendent, OS-agnostic and ephemaral, amongst other benefits**, which is very powerful and suitable for users as we want users to run their application isolated and donot be influenced by others.

Here are the benefits of kubernetes:

* High Availability - this simply means that your application will always up and running, whether you have a new update to roll-out or have some unexpected pods crashing
* Scalability - K8s supports autoscaling and will automatically scale up your cluster as soon as you need it, and scale it back down to save resources.
* Disaster Recovery  - this can ensures that the application will always have the latest data and states of your applicaions (based on the HA)

## The modules inside the Kubernetes 

There are two kinds of node inside a K8s cluster:

* `control-plane`: is used for nodes control and applications scheduling
  * `kube-apiserver`: provide K8s API service, and it validates and configures data for the api objects which include pods, services, replicationcontroller, and others.
  * `kube-controller-manager`: is a daemon where we can see it as the HQ of control. It is a control loop taht watches the shared state of the cluster through the api erver and makes changes attempting to move the current state towards the desired state.
  * `kube-scheduler`: is a control plane process which assigns Pods to Nodes, where we can see it as the HQ of scheduling. The scheduler determines which Nodes are valid placements for each Pod in the scheduling queue according to constraints and available resources. The scheduler then ranks each valid Node and binds the Pod to a suitable Node.
* `node`: usually, applications are usally running  on these nodes
  * `kubelet`: is the primary "node agent" that runs on each node. It can register the node with the apiserver using one of hostname; a flag to override the hostname; or specific logic for a cloud provider
  * `kube-proxy`: reflects services as defined in the K8s API on each node and can do simple TCP, UDP, and SCTP stream fowarding on round robin TCP, UDP, and SCTP forwarding across a set of backends. 

# How to Install 

There are multiple different way to install K8s on no matter bare metal or virtual machine. For example:

* [Minkube](https://minikube.sigs.k8s.io/docs/): for learn and develop
* [kubeadm](https://github.com/kubernetes/kubeadm): production-ready
* [kOps](https://github.com/kubernetes/kops): production-ready
* [kubespray](https://github.com/kubernetes-sigs/kubespray): production-redy

In here I choose Kubeadm.

## Preperation

Previously, Kubernetes cannot start when the swap on. However, in [Version 1.22](https://kubernetes.io/blog/2021/08/09/run-nodes-with-swap-alpha/) they support for usingthe swap memory, thus, it is not neccessary to turn of the swap, but still, you can turn it off if you want: 

```shell
sudo swapoff -a
```
Then, we may need to specify the ip and hostname on the `/etc/hosts`

```shell
cat >> /etc/hosts << EOF
192.168.10.2  cantor
192.168.10.3  gauss
192.168.10.4  hilbert  
```
To install `containerd` as the container engine on the system, install some pre-requisite modules:

```shell
sudo modprobe overlay && sudo modeprobe br_netfilter
```
You can also ensure these are persistent and configure the `sysctl parameters`

```shell
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo systtl --system
```
## Install Containerd

Since Version 1.24 of Kubernetes, [the dockershim is deperated](https://kubernetes.io/blog/2022/05/03/kubernetes-1-24-release-announcement/#major-themes) and move on of using Containerd. 

```shell
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.bfsu.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo mkdir -p /etc/containerd && sudo containerd config default | sudo tee /etc/containerd/config.toml

# You can also try mirrors.bfsu.edu.cn - Docker mirrors 
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo mkdir -p /etc/containerd && sudo containerd config default | sudo tee /etc/containerd/config.toml
```
You may wonder why I install the docker as the K8s does not need it anymore, actually, I don't know why, but if I miss this package, the `kubeadm init` will fails for some reasons.[^1]

We need some modification of `/etc/containerd/config.toml`:

```shell
# set SystemdCgroup as true
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  BinaryName = ""
  CriuImagePath = ""
  CriuPath = ""
  CriuWorkPath = ""
  IoGid = 0
  IoUid = 0
  NoNewKeyring = false
  NoPivotRoot = false
  Root = ""
  ShimCgroup = ""
  SystemdCgroup = true

# To accelerate the installations, change sand_box mirros to aliyun (optional) 
sandbox_image = "registry.cn-hangzhou.aliyuncs.com/pause:3.6"
```
## Install Kubernetes

Use `aubeadm` to initlization the cluster: 

```shell
sudo kubeadm init --pod-network-cidr <pod-cidr> \
        --service-cidr <service-cidr> \
        --apiserver-advertise-address <your-ip> \
        --control-plane-endpoint <your-ip> \
        --v 5

# To accelerate the installations, change sand_box mirros to aliyun (optional) 
sudo kubeadm init --pod-network-cidr <pod-cidr> \
        --service-cidr <service-cidr> \
        --apiserver-advertise-address <your-ip> \
        --control-plane-endpoint <your-ip> \
        --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers \
        --v 5

# after the initlization you need to create the kubeconfig
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

After the intilization, you also need Container Network Interface (CNI), I choose `flannel` since I used to use it in my K3s cluster.

```shell
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
```

Wait for any while and check the whether the kubernetes (pods and nodes) is running properly.

## Install the MetalLB

Unlike the [K3s](https://github.com/k3s-io/klipper-lb), the Kubernetes does not contain a intergrated LoadBalancer, thus, we need to install it by ourselves. I use [MetalLB](https://metallb.universe.tf/concepts/) in here. There are multiple ways to install the MetalLB, I use the manifest to install it.

```shell
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

# defining the IPs to assign  to the loadbalancer ssevices (I choose L2 in here)
cat <<EOF | sudo tee metallb-ips.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ip-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.4.4/32  # the external IP of your nodes
  - 10.0.4.15/32

---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: metal-l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - ip-pool
EOF
```

That's it, you can choose a `ingress-controller` you like and after install it, a K8s (v1.25.3) cluster is configured :) 

[^1]: I think the reason is that I missed the `runc` package.

