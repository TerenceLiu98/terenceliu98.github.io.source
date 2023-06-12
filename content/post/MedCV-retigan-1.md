---
title: "👨🏿‍⚕️ RetiGAN: A GAN-based model on retinal Image synthesis"
date: 2023-04-02T00:13:00+08:00
draft: false
math: true
tags: ['Artificial Intelligence', 'Medical Image', 'Fundus Image']
series: ['MedCV']
---

<!--more-->

## Before (TL;DR)

The field of medical imaging is rapidly adopting artificial intelligence (AI) as a promising technology, with a particular focus on deep learning techniques. These AI methods have the potential to be applied across a range of tasks in medical imaging, from image acquisition and reconstruction to analysis and interpretation. For instance, Computed Tomography(CT), Magnetic Resonance Imaging, Positron Emission Tomography (PET), Mammography, Ultrasound, and X-ray, haved be used for early detection, diagnosis, and treatment of diseases. In the clinic, medical image interpretation in the clinic has relied on human experts, such as radiologists and physicians. However, due to the wide range of pathologies and the risk of human fatigue, researchers and doctors have started to explore the potential of computer-assisted interventions. While progress in computational medical image analysis has not been as rapid as in medical imaging technologies, the situation is improving with the introduction of machine learning techniques.

Machine learning techniques, such as deep learning, have shown promise in assisting human experts in medical image interpretation. By training algorithms on large datasets of medical images, these techniques can help identify patterns and features that are difficult for human experts to detect. As a result, they have the potential to improve diagnostic accuracy and reduce the risk of errors.

As the field of machine learning continues to evolve, it is likely that we will see more applications of these techniques in medical imaging. While they will not replace the need for human experts, they can provide valuable assistance and help improve patient outcomes.

As the very first blog on Medical CV/Medical Image processing, I am trying to introduce a paper working on retinal image synthesis, The authors of this paper have combined multiple classical deep learning techniques that were developed before 2021.

For those who are new to the field of deep learning and medical computer vision, the content of the paper is easily understandable. The authors have used these techniques to synthesize retinal images, which has the potential to aid in the diagnosis and treatment of various eye diseases.

Overall, this paper highlights the potential of deep learning techniques in medical image processing and provides a valuable contribution to the field. As a newcomer to this field, it is an excellent resource for gaining a better understanding of the applications of deep learning in medical computer vision.

## A novel retinal image generation model with the preservation of structural similarity and high-resolution

The paper can be found in [10.1016/j.bspc.2022.104004](https://doi.org/10.1016/j.bspc.2022.104004). 

In this paper, the proposed a new retinal image generation model call **RetiGAN** based on the adversarial learning. The goal of this model is to **generate high-resolution synthetic images** that preserve the structual similarity of the original images. To achieve this, they embed the VGG network into their RetiGAN to guarantee the high-level semantic information can be extracted and used in the content loss to guide the model to retain the semantic contents of the original image. To solved the problem of blurring and incpomplete edge, the embed the smoothed images into the training set to improve the edge sharpness of the generated images.

In general, the RetiGAN can be divied into four modules:

1. U-Net: for the Vessel tree segmentation
2. Generator $G$: learns to generate plausible retinal image
3. Discriminator $D$: learns to distinguish the generator's fake image from real image
4. VGG modules: perform high-level feature extraction on the generated retinal image and the original image. In this way, the global semantic features of the retinal image can be well preserved.

Basically, the idea/architecture of the $G$ and $D$ are from the [pix2pixHD](https://tcwang0509.github.io/pix2pixHD/)

### U-Net

![U-Net](https://s3.cklau.cc/outline-socialquest/uploads/6c09ef1a-2e2c-4019-afa7-f595e19d1402/a4e972d5-373e-4af3-b932-f32defa55951/Screenshot%202023-01-30%20at%2011.17.49%20AM.png)

The U-Net network is based on a fully convolutional neural network, whose characteristic is that a small amount of training images can be used to obtain a good segmentation effect, very suitable for the field of medical images. The architecture of U-Net is similar to the *encoder-decoder* architecture, where the left-side of the "U" is the encoder block, and the right-side is the decoder block[^1]. 

* Encoder: is a 4-layer architecture:
  * extracts a meaningful feature map from the input image
  * each layer includes two convolution layers and one max-pooling for the down-sampling
* Decoder: is a 4-layer architecture:
  * up-sampling the feature map
  * each layer includes two convolution layers
  * for each layer, it concatenates the corresponding encoder's features (using `torchvision.transforms.CenterCrop` to maintain the size)

In this article, they use U-Net as the tool to separate the background and the vessel tree, as the vessel tree is treated as the input for the generator $G$. 

```python
# code example for the U-Net
class DualConv(nn.Module):
    def __init__(self, in_channel, out_channel):
        super(DualConv, self).__init__()
        self.conv = nn.Sequential(
            nn.ReflectionPad2d(padding=2),
            nn.Conv2d(in_channel, out_channel, kernel_size=3, padding=0),
            nn.InstanceNorm2d(out_channel, affine=False),
            nn.ReLU(inplace=True),
            nn.Conv2d(out_channel, out_channel, kernel_size=3, padding=0),
            nn.InstanceNorm2d(out_channel, affine=False),
            nn.ReLU(inplace=True)
        )
        
    def forward(self, x):
        x = self.conv(x)
        return x

class Encoder(nn.Module):
    # 3 is for RGB, 1 is for grayscale
    def __init__(self, channels = [3, 64, 128, 256, 512, 1024]):
        super(Encoder, self).__init__()
        self.encblocks = nn.ModuleList([DualConv(channels[i], channels[i+1]) for i in range(len(channels) - 1)])
        self.maxpool2d = nn.MaxPool2d(2)
        
    def forward(self, x):
        output = []
        for encblock in self.encblocks:
            x = encblock(x)
            output.append(x)
            x = self.maxpool2d(x)
        return output
        
class Decoder(nn.Module):
    def __init__(self, channels=[1024, 512, 256, 128, 64], mode="trans"):
        super().__init__()
        self.channels = channels
        if mode == "bilinear":
            self.upsampling = nn.ModuleList([nn.Sequential(nn.Upsample(scale_factor=2, mode="bilinear", align_corners=True), 
                                                            nn.Conv2d(channels[i], channels[i+1], kernel_size=1)) for i in range(len(channels)-1)])
        else:
            self.upsampling = nn.ModuleList([nn.ConvTranspose2d(channels[i], channels[i+1], kernel_size=2, stride=2) for i in range(len(channels)-1)])
        self.decblocks = nn.ModuleList([DualConv(channels[i], channels[i+1]) for i in range(len(channels)-1)]) 

    def forward(self, x, encoder_features):
        for i in range(len(self.channels)-1):
            x = self.upsampling[i](x)
            enc_ftrs = self.crop(encoder_features[i], x)
            x = torch.cat([x, enc_ftrs], dim=1)
            x = self.decblocks[i](x)
        return x

    def crop(self, enc_ftrs, x):
        _, _, H, W = x.shape
        enc_ftrs   = torchvision.transforms.CenterCrop([H, W])(enc_ftrs)
        return enc_ftrs

class UNet(nn.Module):
    def __init__(self, enc_channels=[3, 64, 128, 256, 512, 1024], dec_channels=[1024, 512, 256, 128, 64], num_class=1, mode="trans"):
        super(UNet, self).__init__()
        self.encoder = Encoder(channels=enc_channels)
        self.decoder = Decoder(channels=dec_channels, mode=mode)
        self.output = nn.Sequential(nn.Conv2d(dec_channels[-1], num_class, 1), nn.Sigmoid())

    def forward(self, x):
        enc_out = self.encoder(x)
        out = self.decoder(enc_out[::-1][0], enc_out[::-1][1:])
        out = self.output(out)
        return out
```

### Generator $G$

The gneerator is is a standard encoder-decoder architecture, which can be seperated into three parts:

1. down-sampling module
2. residual blocks
3. up-sampling module

where it is the *GlobalGenerator* in pix2pixHD model, focusing on the coarse high-resolution image. In pix2pixHD, they have seconde generator called *LocalEnhancer*, focusing on the feature encoding and decoding enhancement. The *LocalEnhancer* is used to refine the image by adding more details to improve the image quality. The input of the *GlobalGenerator* in pix2pixHD is the downsampled label map $s_{\text{down}}$, and the output is the corse generated image $\hat{x}\_{\text{down}}$. With the addition operation with the feature map $Enc_{\text{L}}(s)$: $(Enc_{\text{L}}(s) + \hat{x}\_{\text{down}})$, the *LocalEnhancer* output the final $\hat{x}$.

In RetiGAN, the simply using the *GlobalGenerator* as the generator, since the retinal image are more simplier than the image using in pix2pixHD, where the fundus image are all indomain information, thus, using one generator can reduce model complexity.

```python
## ResBlock ##
class ResBlock(nn.Module):
    def __init__(self, in_channel):
        super(ResBlock, self).__init__()
        self.resblock = nn.Sequential(
            nn.Conv2d(in_channel, in_channel, kernel_size=3, stride=1, padding=1, padding_mode="reflect"),
            nn.InstanceNorm2d(in_channel),
            nn.ReLU(inplace=True),
            nn.Conv2d(in_channel, in_channel, kernel_size=3, stride=1, padding=1, padding_mode="reflect"),
            nn.InstanceNorm2d(in_channel)
        )
        
    def forward(self, x):
        out = x + self.resblock(x)
        return out

## Generator ##
class GlobalGenerator(nn.Module):
    def __init__(self, in_channel=3, out_channel=3, filters=64, n_enc=3, n_bottle=9, mode="trans"):
        super(GlobalGenerator, self).__init__()
        encoder = nn.ModuleList([
            nn.Conv2d(in_channels=in_channel, out_channels=filters, kernel_size=7, stride=1, padding=3, padding_mode="reflect"),
            nn.InstanceNorm2d(filters, affine=False),
            nn.ReLU(inplace=True)
        ])
        for i in range(n_enc):
            multiplier = filters * (2 ** i)
            encoder.append(nn.Conv2d(in_channels=multiplier, out_channels=multiplier * 2, kernel_size=3, stride=2, padding=1, padding_mode="reflect"))
            encoder.append(nn.InstanceNorm2d(multiplier * 2, affine=False))
            encoder.append(nn.ReLU(inplace=True))
        
        resblocks = nn.ModuleList([])
        for i in range(n_bottle):
            resblocks.append(ResBlock(multiplier * 2))
        
        decoder = nn.ModuleList([])
        #multiplier = multiplier * 2
        for i in range(n_enc):
            multiplier = int(filters * (2 ** (n_enc - i)))
            if mode == "trans":
                decoder.append(nn.ConvTranspose2d(in_channels=multiplier, out_channels=int(multiplier / 2), kernel_size=3, stride=2, padding=1, output_padding=1))
            elif mode == "shuffle":
                decoder.append(nn.Conv2d(in_channels=multiplier, out_channels=int(multiplier / 2) * (2 ** 2), kernel_size=3, stride=1, padding=1))
                decoder.append(nn.PixelShuffle(2))
            else:
                decoder.append(nn.Upsample(scale_factor=2, mode="bilinear", align_corners=True))
                decoder.append(nn.Conv2d(in_channels=multiplier, out_channels=int(multiplier / 2), kernel_size=1))
            decoder.append(nn.InstanceNorm2d(int(multiplier / 2), affine=False))
            decoder.append(nn.ReLU(inplace=True))
        decoder.append(nn.Conv2d(in_channels=int(multiplier / 2), out_channels=out_channel, kernel_size=7, stride=1, padding=3, padding_mode="reflect"))
        decoder.append(nn.Tanh())
        model = encoder + resblocks + decoder
        self.model = nn.Sequential(*model)
    
    def forward(self, x):
        out = self.model(x)
        return out

class LocalEnhancer(nn.Module):
    def __init__(self, in_channel=3, out_channel=3, filters=64, n_enc=3, n_bottle=9):
        super(LocalEnhancer, self).__init__()
        # G2 Encoder 
        encoder = nn.ModuleList([
            nn.Conv2d(in_channels=in_channel, out_channels=int(filters / 2), kernel_size=7, stride=1, padding=3, padding_mode="reflect"),
            nn.InstanceNorm2d(int(filters / 2), affine=False),
            nn.ReLU(inplace=True),
        ])
        encoder.append(nn.Conv2d(in_channels=int(filters / 2), out_channels=filters, kernel_size=3, stride=2, padding=1, padding_mode="reflect"))
        encoder.append(nn.InstanceNorm2d(filters, affine=False))
        encoder.append(nn.ReLU(inplace=True))
        self.encoder = nn.Sequential(*encoder)
        # G1 Encoder-Decoder
        self.generator = GlobalGenerator(in_channel=in_channel, out_channel=out_channel, filters=64, n_enc=3, n_bottle=9).model[:-3]
        
        # G2 ResBlock
        resblocks = nn.ModuleList([])
        for i in range(3):
            resblocks.append(ResBlock(filters))
        self.resblocks = nn.Sequential(*resblocks)
        # G2 Decoder
        decoder = nn.ModuleList([
            nn.ConvTranspose2d(in_channels=filters, out_channels=int(filters / 2), kernel_size=3, stride=2, padding=1, output_padding=1),
            nn.Conv2d(in_channels=int(filters / 2), out_channels=out_channel, kernel_size=7, stride=1, padding=3, padding_mode="reflect"),
            nn.Tanh()
        ])
        self.decoder = nn.Sequential(*decoder)
        # Downsampling for G1
        self.downsample = nn.AvgPool2d(3, stride=2, padding=1, count_include_pad=False)
    
    def forward(self, x):
        enc_out = self.encoder(x)
        gen_out = self.generator(self.downsample(x))
        res_out = self.resblocks(torch.add(enc_out, gen_out))
        out = self.decoder(res_out)
        return out
```


### Discriminator $D$

The basic idea of the discriminator is following this two equation $D(\hat{s}, \hat{x}) \mapsto \mathbf{0}$, and $D(s, x) \mapsto \mathbf{1}$, where $D$ measures the distance between fake image pairs with zero, and real image pairs with one.

In this paper (or in pix2pixHD), they adapted the discriminator architecutre proposed by [PatchGAN](https://arxiv.org/abs/1611.07004v3), where the PatchGAN discriminator takes in image patches rather than an entire image. These patches are typically small square regions of the input image, such as 70x70 or 256x256 pixels. The PatchGAN discriminator produces a matrix of scalar values that represent the probability of each patch being real or fake. By operating at the patch level, the PatchGAN discriminator is able to capture more fine-grained details of the image and provide more precise feedback to the generator. This can lead to higher quality image generation.

Instead of using one discriminator, they use two discriminator, $D_1$ is for the original size images and $D_2$ is for the down-sampled images.

```python
## PatchDiscriminator
class PatchDiscriminator(nn.Module):
    def __init__(self, in_channel=3, filters=64, n_blocks=3):
        super(PatchDiscriminator, self).__init__()
        self.model = nn.ModuleList([
            nn.Conv2d(in_channels=in_channel, out_channels=filters, kernel_size=4, stride=2, padding=2),
            nn.LeakyReLU(0.2, inplace=True)
        ])
        for i in range(n_blocks-1):
            multiplier = filters * (2 ** i)
            self.model.append(nn.Conv2d(multiplier, multiplier * 2, kernel_size=4, stride=2, padding=2))
            self.model.append(nn.InstanceNorm2d(multiplier * 2, affine=False))
            self.model.append(nn.LeakyReLU(0.2, inplace=True))
        
        self.model.append(nn.Conv2d(multiplier * 2, multiplier * 4, kernel_size=4, stride=1, padding=2))
        self.model.append(nn.Conv2d(multiplier * 4, 1, kernel_size=4, stride=1, padding=2))
    
        self.model = nn.Sequential(*self.model)
    
    def forward(self, x):
        out = self.model(x)
        return out

## MultiScaleDiscriminator
class MultiScaleDiscriminator(nn.Module):
    '''
    By default, there are three separate sub-discriminator(D1, D2, D3) to generate prediction
    They all have the same architectures but D2 and D3 operate on inputs downsampled by 2x and 4x, respectively
    '''
    def __init__(self, in_channel=3, filters=64, n_blocks=3, n_dim=3):
        super(MultiScaleDiscriminator, self).__init__()
        self.n_dim = n_dim
        self.downsample = nn.AvgPool2d(kernel_size=3, stride=2, padding=1, count_include_pad=False)
        model_template = PatchDiscriminator(in_channel=in_channel, filters=filters, n_blocks=n_blocks)
        for i in range(n_dim):
            setattr(self, "model{}".format(i), model_template)
        
    def forward(self, x):
        out = []
        for i in range(self.n_dim):
            model = getattr(self, "model{}".format(i))
            if i != 0:
                x = self.downsample(x)
            out.append(model(x))
        return out
```

### VGG (Perceptual Information Extraction)

The VGG architecture consists of a series of convolutional layers with small 3x3 filters, followed by max pooling layers. The number of filters in each convolutional layer is gradually increased as the network gets deeper. The final layers of the network consist of fully connected layers that perform the classification task.

VGG is often used in conjunction with perceptual loss in deep learning applications, particularly in image synthesis and style transfer tasks.

Perceptual loss[^2] is a type of loss function that is based on the idea of using a pre-trained deep neural network, such as VGG, to measure the similarity between two images. In the context of image synthesis, the goal is to generate an image that is visually similar to a target image. Perceptual loss can be used to measure the difference between the generated image and the target image in terms of their high-level features, such as texture, color, and object structure. 

```python
class Perception(nn.Module):
    '''
    Compute the perceptual information based on VGG pretained model 
    \begin{align*}
        \mathcal{L}_{\text{VGG}} = \mathbb{E}_{s,x}\left[\sum_{i=1}^N\dfrac{1}{M_i}\left|\left|F^i(x) - F^i(G(s))\right|\right|_1\right]
    \end{align*}
    '''
    def __init__(self):
        super(Perception, self).__init__()
        vgg19 = torchvision.models.vgg19(weights="DEFAULT").features
        self.models = nn.ModuleList([
            vgg19[:2],
            vgg19[2:7],
            vgg19[7:12],
            vgg19[12:21],
            vgg19[21:30]
        ])

        # no need to update the parameters
        for param in self.parameters():
            param.requires_grad = False

    def forward(self, x):
        out = []
        out.append(x)
        for model in self.models:
            x = model(x)
            out.append(x)
        return out
```

### Loss function

In general, there are two losses: *Generato Loss* $\mathcal{L}_G$ and *Discriminator Loss* $\mathcal{L}_D$. 

The *Generator Loss* includes these three sub-loss:
1. Adversarial loss: $\mathcal{L}_{\text{adv}}$: is used to train the generator network by making it generate synthetic data that can fool the discriminator network into thinking that it is real data. The adversarial loss is computed based on the output of the discriminator network.$\mathcal{L}\_{\text{adv}}= \left|\left|D(G(s)), 1\right|\right|\_2$
   
2. Feature Matching Loss $\mathcal{L}_{\text{FM}}$: In pix2pixHD, the authors found this to stabilize training. In this case, this forces the generator to produce natural statistics at multiple scales. This feature-matching loss is similar to StyleGAN’s[^3] perceptual loss. For some semantic label maps s and corresponding image $x$: $\mathcal{L}\_{\text{FM}} = \mathbb{E}\_{s,x}\left[\sum\_{i=1}^T\dfrac{1}{N\_i}\left|\left|D^{(i)}\_k(s, x) - D^{(i)}_k(s, G(s))\right|\right|\_1\right]$, where $T$ is the total number of layers, $N_i$ is the number of elements at layer $i$ and $D\_k^{(i)}$ denotes the $i$-th layer in discriminator $k$.
   
   
3. Peceptual Loss $\mathcal{L}\_{\text{VGG}}$: In pix2pixHD, the authors report minor performance improvements when adding perceptual loss, formulated as $\mathcal{L}\_{\text{VGG}} = \mathbb{E}\_{s,x}\left[\sum_{i=1}^N\dfrac{1}{M\_i}\left|\left|F^i(x) - F^i(G(s))\right|\right|\_1\right]$, where $F^i$ denotes the $i$th layer with $M_i$ elements of the VGG19 network.

Overall, $\mathcal{L}\_G = \lambda\_0\mathcal{L}_{\text{GAN}} + \lambda_1 \mathcal{L}\_{\text{FM}} + \lambda\_2 \mathcal{L}\_{\text{VGG}}$, where $\lambda\_i$ are the parameters.

The Discriminator Loss in this paper is similar to the PatchGAN’s. However, to solve the blurring and incomplete edges, they include an additional set of images $x_b$ , where $x_b$ are generated by removing precise edges in training images x (Canny edge detector & Gaussian filter). After the smoothed images x_b are included into the training set, the main task for the discriminator is not only to improve the ability of discriminating the generated from the real ones, but also to discriminate the smoothed and the clear ones.

$\mathcal{L}\_D = \mathbb{E}[logD(x)] + \mathbb{E}[log(1 - D(\hat{x}))] + \mathbb{E}[log(1 - D(\hat{x\_b}))]$

```python
## Perceptual Loss
class PerceptualLoss(nn.Module):
    """
    compute perceptual loss with VGG network from both real and fake images (updating the Generator)
    """
    def __init__(self, device="cpu"):
        super(PerceptualLoss, self).__init__()
        self.model = Perception().to(device)
        self.criterion = nn.L1Loss()
        self.LAMBDA = [1/32, 1/16, 1/8, 1/4, 1]
    
    def forward(self, predict, target):
        loss = 0.0
        for real, fake, weight in zip(self.model(target), self.model(predict), self.LAMBDA):
            loss += weight * self.criterion(real.detach(), fake)
        
        return loss

## Adversarial Loss 
class AdversarialLoss(nn.Module):
    """
    computes adversarial loss from nested list of fakes outputs from discriminator. (updating the Generator)
    """
    def __init__(self):
        super(AdversarialLoss, self).__init__()
        self.criterion = nn.MSELoss()

    def forward(self, predict, is_real=True):
        loss = 0.0
        target = torch.ones_like if is_real else torch.zeros_like
        for preds in predict:
            loss += self.criterion(preds, target(preds))
        
        return loss

class FeatureMatchLoss(nn.Module):
    '''
    Compute feature matching loss from nested lists of fake and real outputs from discriminator. (updating the Ganerator)
    https://proceedings.neurips.cc/paper/2016/file/8a3363abe792db2d8761d6403605aeb7-Paper.pdf
    \begin{align*}
        \mathcal{L}_{\text{FM}} = \mathbb{E}_{s,x}\left[\sum_{i=1}^T\dfrac{1}{N_i}\left|\left|D^{(i)}_k(s, x) - D^{(i)}_k(s, G(s))\right|\right|_1\right]
    \end{align*}
    '''
    def __init__(self):
        super(FeatureMatchLoss, self).__init__()
        self.criterion = nn.L1Loss()

    def forward(self, predict, target):
        loss = 0.0
        for real_feature, fake_feature in zip(target, predict):
            for real, fake in zip(real_feature, fake_feature):
                loss += self.criterion(real.detach(), fake)

        return loss

class GeneratorLoss(nn.Module):
    '''
    Combine the Adversarial-Loss, Feature Maching Loss, and Perceptual Loss together with different weights
    '''
    def __init__(self, LAMBDA0=1, LAMBDA1=100, LAMBDA2=10, n_dim=3):
        super(GeneratorLoss, self).__init__()
        SCALE = LAMBDA0 + LAMBDA1 + LAMBDA2
        self.LAMBDA = [LAMBDA0 / SCALE, LAMBDA1 / SCALE, LAMBDA2 / SCALE]
        self.n_dim = n_dim
        
        self.adv_loss = AdversarialLoss()
        self.per_loss = PerceptualLoss()
        self.fm_loss = FeatureMatchLoss()

    def forward(self, fake, real, predict, target):
        loss = self.LAMBDA[0] * self.adv_loss(predict=predict, is_real=True) + \
         self.LAMBDA[1] * self.per_loss(predict=fake, target=real) + \
         self.LAMBDA[2] * self.fm_loss(predict=predict, target=target) / self.n_dim
        return loss
```




[^1]: The U-Net is not a *encoder-decoder* architecture, as it does not contain a "latant" layer, however, the shapes are similar, to simply, I just call it as *encoder-decoder*.
[^2]: To see more about perceptual loss, you may check [Perceptual Losses for Real-Time Style Transfer and Super-Resolution](https://arxiv.org/abs/1603.08155)
[^3]: [StyleGAN, from 1 to 3](https://nvlabs.github.io/stylegan2/versions.html)