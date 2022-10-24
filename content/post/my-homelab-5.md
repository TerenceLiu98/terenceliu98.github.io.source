---
title: "Homelab: How to build a AIO home-server"
date: 2022-10-24T00:11:21+08:00
draft: false
tags: ['homelab','hardware']
---

## Before

I buy this machine for multiple reasons, but must importantly, the previous NAS is built on a very old machine and the disk are "second-hand", thus, I am not sure the stability of the old guy. And I got my bonus of the previous project, so I just spent the money on this bunch of hardware. For this time, I don't want it be a pure NAS, and it should be a ALL-IN-ONE machine.  

## Hardware

| Module | Series | Price |
| ------ | ------ | ----- | 
| CPU + Motherboard | Intel Xeon D-1581 + [HSGM D1581-R3](https://www.huoshen99.com/) | ¥498 |
| Memory | second-hand ECC DDR3 1600 16GB $\times$ 4 | ¥79 |
| Graphic card | Old NVIDIA RTX 2060 | ¥0 |
| Storage-SSD | DAHUA C900 512GB | ¥245 | 
| Storage-HDD | TOSHIBA MG04ACA400N 4T $\times$ 4 | ¥1340 |
| Case | not named | ¥399 |
｜Total | | ¥2561 

The reason I chose Xeon D-1581 is that I do not expect playing games or running some programs that expect high performance of single-core on this machine, instead, I need multiple cores for virtural machine for some experiment, where I don't need to spend money on the VPS. This is also explain why I need 64GB for RAM. For the storage part, I split the 4 hard disk into two group and each group has 2 disk, the group 1 I create a raid 1 for the important file storage, like photos, documentation and my code; the group 2 I create a LVM volume for daily storage, for example, the movie, music, and etc..

## Software

I use Ubuntu 22.04 LTS as my base system, there is no reason/explanation, I familiar with ubuntu and I trust it can do a great job in the long-time task. Here is the configuration I have done on this machine:

### NVIDIA DRIVER and CUDA

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

### Container: LXC and LXD

LXC stands for Linux Containers, I choose using the LXC as it can be easily used in PCI passthrough by just follow the above instruction and install the `nvidia-container-toolkit`. 

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

## Storage: Raid1 and LVM volume

Assume that we have `/dev/sda`, `/dev/sdb`, `/dev/sdc`, and `/dev/sdd`, we can simply use `mdadm` to create a Raid1:

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

For the LVM volume:

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

For the mounting, you can also use the `uuid` to mount the storage. Simply use `blkid` and you can find the disk's uuid.