---
title: "💻 从白苹果到黑苹果 - SER5 MAX 的骇金塔之旅"
date: 2024-01-18T00:12:00+00:00
draft: false
math: true
tags: ['无业游民', '电脑', '折腾']
comment: true
extramaterials:
- type: link
  name: 「SER5 Max 安装黑苹果手记」
  url: https://gameapp.club/post/ser5-max-hackintosh/
- type: video
  name:  「Beelink SER5 刷入 macOS - 视频教程」（AI 音效，慎入） 
  url: https://www.bilibili.com/video/BV1AX4y1q719/?share_source=copy_web&vd_source=4c9d32f99d4c2f6e4dd61d5025185e26
- type: video
  name:  「macOS13升级准备，OTA也能万无一失」
  url: https://youtu.be/zuKaRHaecmg?si=53ODPGaaL7g5r3wg

---

> 💡 For learning and communication purposes only. Commercial use is strictly prohibited. 
> 
> 💡 此文为技术实践记录和个人学习用途，并在实验后卸载及删除相关文件，包括且不限 EFI 文件和镜像。

## 一台 mini PC 

笔者目前的工作和生活在不知不觉之中已经浸润在 iOS + iPadOS + macOS 之中，「搞机多年，归来仍是 Apple」在当年的我看来似乎未来是会一定的，也亦然实现了。而苹果公司的「金内存，银固态」策略让我这个收入尚不如 Homeless 的人抬不起头。不得已，在互联网冲浪中，冥冥之中，让我看到了这一台 mini PC：Beelink SER5 MAX，由零刻公司开发的一台巴掌小主机。具体配置如下: AMD Ryzen 7 5800H + 32GB DDR4 + 1T NVME SSD，作为一个懒人，并没有购买准系统，而 32GB 已经可以满足个人日常使用。至于系统的选择，如果可以和笔者其他设备进行「十物互联」那便是最好的[^1]。从这里，引出了 Hackintosh。

<!--more-->

## 如何赶上潮流

「黑苹果」是指在一台没有苹果 Logo 的电脑上运行麦金塔系统的行为，历史详见这里：[Hackintosh](https://zh.wikipedia.org/wiki/Hackintosh)。根据「型号 + 黑苹果」的关键词进行搜索，我找到了一系列大多是在 2023 年中前期发布的文章和视频，我根据其中总结出几个字：可以装但是不算好用。顺藤摸瓜，我找到了黑苹果“总部”：[黑果小兵的部落阁](https://blog.daliansky.net/)。在大致了解了黑苹果的安装方式后，我果断选择了最稳妥的方式，下载别人制作好的带 EFI 的镜像，Big Sur 的系统似乎也不太古早，也足够使用。

在一系列折腾后，Big Sur 已经满足不了我的使用了，比如，因为人在海外，并不太能很方便的购入网络摄像头[^2]，所以，乘着苹果的[春风](https://support.apple.com/en-gb/102546)，我把 Big Sur 升级到了 Ventura[^3]。这样以来，我就可以使用我的 iPhone 作为网络摄像头用来开会[^4]。在升级的过程中，实际上也是遇到了一些阻滞，比如一开始我是想从从 Big Sur 升级到 Monterey，但是在使用 OC Auxiliary Tool 更新完 OpenCore 和 Kext 后发现我没有办法在启动 Monterey 勾选 [NootedRed](https://chefkissinc.github.io/nred/)，这可不太好，因为失去了核显就等于失去了所有。在一顿折腾后，我决定尝试一下 Ventura 如果不行的话，就待在 Big Sur 算了。 

## 参考资料

所有的参考资料均来自互联网，详见下面的附件栏。

[^1]: 「十物互联」是本人魔改的词汇，意指个人的电子设备可以相互连接。
[^2]: 也不想因为这个而买一个低分辨率的摄像头
[^3]: 即便 Ventura 的部分操作逻辑真的不像是电脑，我也决定忍受。
[^4]: 虽然至今不理解为什么鬼佬喜欢开会喜欢开摄像头，脸和肢体语言不是最重要的好吗。