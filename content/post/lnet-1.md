---
title: "My Personal Experimental Network: LNet"
date: 2022-10-18T00:11:21+08:00
draft: false
tags: ['networking', 'wireguard', 'experimental network']
---

## Before

In the previous project: [Homelab]({{< ref "/post/my-homelab-1" >}} "My Homelab 2"), I listed all my device and VPS on a table, where all the VPS own a specifi public IP and I tride to use the Wireguard to connect them into a Full-mesh intranet.

However, to investigate deeper into the network performance, I started to learn how to federate these clusters while not effect the current usage. What's more, if I can federate these isolated network, then I don't need to build seperate services in different cluster. For instance, I can use a single [Prometheus](https://prometheus.io/) to monitor all the devices and no more millions of virtual interfaces :)

(To-be continued)



