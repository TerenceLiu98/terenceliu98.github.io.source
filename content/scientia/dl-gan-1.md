---
title: "👨‍💻 Style Transfer and Synthesis (1/3): Style Transfer in Image Synthesis"
date: 2023-06-17T00:13:00+08:00
draft: false
math: true
tags: ['Artificial Intelligence', 'Style Tranfer', 'Image Synthesis']
series: ['Style Transfer and Synthesis']
---

<!--more-->

There are multiple papers in the area of style transfer and image inversion or reconstruction. Here are some papers I read and would like to share with you:

### Progressive GAN


* Paper URL: [ICLR 2018 - PROGRESSIVE GROWING OF GANS FOR IMPROVED QUALITY, STABILITY, AND VARIATION](https://arxiv.org/abs/1710.10196) |
* Code URL: https://git.cklau.cc/terenceliu/gans-models/-/tree/main/PGGAN | 

> **Key point**: They propose a novel training process of GAN model: progressive training, i.e. from small model to big model/from low resolution to high resolution

#### Some Hightlights

1. The training (see Figure A) is from left to right, 
    1. start from  feature map, the model produce a (3x4x4) output from the generator $G_1$ and as the input of the discriminator $D_1$
    2. the second process is to upsample the feature map from $4 \times 4$ to $8 \times 8$ and produce a ($3 \times 8 \times 8$) output from the generator $G_2$ and as the input of the discriminator $D_2$
    3. continue with the process, for the last part of the progression, the model output the $1024 \times 1024$ image from the generator and as the input of the discriminator $D_m$
2. To avoid the influence/damage of the transition from low resolution to high resolution, they fade in the new layer smoothly (see Figure B): 
    1. they treat the layers that operate on the higher resolution like a residual block, whose weight $\alpha$ increases linearly from $0$ to $1$.
    2. By adjusting the weight of convolution-based output and upsampling-based output to control the final output: $(\alpha \cdot O_{\text{convolution layer}} + (1 - \alpha) \cdot O_{\text{upsample layer}})$
3. Minibatch Standard Deviation
4. Equalize the Learning Rate
5. Pixelwised Noramlization



