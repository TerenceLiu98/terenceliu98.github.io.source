---
title: "Homelab: 打造一台 AIO 家用服务器"
date: 2022-10-24T00:11:21+08:00
draft: false
tags: ['homelab','hardware']
---

## 在此之前

买这台机器的原因有很多，但最重要的是，之前的 NAS 是建立在一台很老的机器上，而且磁盘都是“二手”的，所以我不确定这个老家伙的稳定性。 而我拿到了之前项目的奖金，所以该花就花 :)。 这一次，我不希望它是一个纯粹的 NAS，它应该是一个ALL-IN-ONE机器。 

## 硬件

| Module | Series | Price |
| ------ | ------ | ----- | 
| CPU + 主板 | Intel Xeon D-1581 + [HSGM D1581-R3](https://www.huoshen99.com/) | ¥498 |
| 内存 | 二手 ECC DDR3 1600 16GB $\times$ 4 | ¥79 |
| 显卡 | 自用 NVIDIA RTX 2060 | ¥0 |
| SSD 存储 | DAHUA C900 512GB | ¥245 | 
| HDD 存储 | TOSHIBA MG04ACA400N 4T $\times$ 4 | ¥1340 |
| 机箱 | not named | ¥399 |
｜总价 | | ¥2561 

我选择 Xeon D-1581 这个芯片组的原因是我不希望在这台机器上玩游戏或运行一些期望单核高性能的程序，而是我需要多核用于虚拟机进行一些实验，这样，我就可以省去一些在 VPS 上的花费。 这也解释了为什么我需要 64GB 的内存。 对于存储部分，我将 4个硬盘分成两组，每组 2 个磁盘，第 1 组我创建一个 raid 1 用于重要文件存储，如照片，文档和我的代码； 第 2 组我创建一个LVM卷用于日常存储，例如电影，音乐等。

## 软件

我使用 Ubuntu 22.04 LTS 作为我的基础系统， 是我熟悉 Ubuntu，我相信它可以在长期任务中做得很好。虽然在此之前，我是打算使用 ArchLinux 的，但是因为种种原因，比如我的 Linux 基础并不好，不一定可以胜任维护 ArchLinux 和骚操作的维护。这是我在这台机器上完成的配置：

### 显卡驱动和 CUDA 安装

```bash
# check PCI 
sudo lspci -v | grep -i nvidia
# update 
sudo apt-get update && sudo apt-get upgrade -y
# install nv driver
sudo apt-get install nvidia-driver-510 # for some reason I use 510 as I found it is the most stable in my system
# install nv cuda toolkit
sudo apt-get install nvidia-cuda-toolkit
# install nvidia-container-toolkit
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
echo 'deb https://nvidia.github.io/libnvidia-container/stable/ubuntu20.04/$(ARCH) /' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install nvidia-container-toolkit
sudo reboot

# after rebooting, verify that the GPU is working or not:
nvidia-smi && nvcc -V
```

### Linux 容器：LXC

LXC 代表 Linux 容器，我选择使用 LXC，因为它可以很容易地用于 PCI 直通，只需按照上面的说明安装 `nvidia-container-toolkit`. 

```bash
# install lxd
sudo snap install lxd
# create a zfs storage pool
sudo apt install zfsutils-linux
sudo zpool create -f <pool-name> <your disk>
## if you need raid 1:
sudo zpool create -f <pool-name> /dev/<disk-1> /dev/<disk-2>

# lxd initilization
sudo lxd init
# specify the storage pool to the pool that just create before

# create a template profile check the meaning of the command before you use it
lxc profile create <template-name>                      # create a template 
lxc profile device add pgu-template gpu gpu             # add the gpu device      
lx profile set <template-name> nvidia.runtime=true      # use nvidia-runtime
lx profile set <template-name> security.nesting=true    # allow nesting runtime (running ctr inside)

# launch a container
lxc launch ubuntu:22.04 <ctr-name> -p <profile-name> -s <lxc-storage-name>

# run nvidia-smi inside the container
lxc exec <ctr-name> -- nvidia-smi
```
With the above setting, the container will simply use the same `nvidia-driver`, if you want to use the different driver, you can `set <template-name> nvidia.runtime=false` and install the driver inside the container.

## 存储：软 Raid 和 LVM 卷的使用

假设我们有这四个硬盘： `/dev/sda`, `/dev/sdb`, `/dev/sdc`, and `/dev/sdd`, 我们可以用 `mdadm` 来创建 Raid:

```bash
# create raid 1
sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sda /dev/sdb
# check the process of creation
sudo cat /proc/mdstat
# creaet file system
sudo mkfs.ext4 -F /dev/md0
# create a mount point
sudo mkdir -p /mnt/storage
# mount the storage (temporary)
sudo mount /dev/md0 /mnt/storage
# mount the storage (persistent)
echo '/dev/md0 /mnt/storage ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab
```

对于常见 LVM 卷:

```bash
# create a physical volumes on the top of the remaining dick
sudo pvcreate /dev/sdc /dev/sdd && sudo pvs
# create a volume group named as `lv-storage`
sudo vgcreate vg-storage /dev/sdc /dev/sdd && sudo vgdisplay vg-storage
# create two logical volumes 
## the first one is for the lxd and the remains are for daily storage
sudo lvcreate -n lxd-tool -L 120G vg-storage && lvs
sudo lvcreate -n daily-storage -l 100%FREE vg-storage && lvs
# create zfs pool & ext4 
sudo zpool create lxdPool /dev/vg-storage/lxd-pool
sudo mkfs.ext4 -F /dev/vg-storage/daily-storage
# create a mount point
sudo mkdir -p /mnt/daily-storage
# mount the storage (temporary)
sudo mount /dev/vg-storage/daily-storage /mnt/daily-storage
# mount the storage (persistent)
echo '/dev/vg-storage/daily-storage /mnt/daily-storage ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab

# create the storage status
df -h
```

对于自动挂载，我一般会选择可以使用 `uuid` 来进行挂在。 通过 `blkid` 我门很容易的可以找到磁盘的 `uuid`，然后写入到 `/etc/fstab` 里即可。