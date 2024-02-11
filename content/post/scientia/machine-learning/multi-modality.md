---
title: "🧑🏿‍💻 Multimodal Representation Leraning from both Text and Image"
date: 2024-02-08T00:15:00+00:00
draft: false
math: true
toc: true
comment: true
tags: ['Artificial Intelligence', 'text-image', 'multi-modality', 'long-read']
series: ['Multi-Modality']
bibFile: /content/post/scientia/machine-learning/bib.json
---

## Before

For a long time, the machine learning model (deep learning model) cannot understand more than one modality, i.e., whether they knows how to do the text-based task or they know how to play with the image. As artificial intelligence, the researchers would like to the models have the cability of manipulating the multimodal data as the natural intelligence is not limited to just a single modality. Such that the AI shell read and write text while they could also see images and watch videos and hear the audio.

However, different data mode has different representation, especially for the machine, i.e., different mode of data has different representation. Some of the modality can be approximated by the others, e.g. audio can be transformed into images via the Fourier Transformation [^1].


Usually, the multimodal learning includes these five aspects {{< cite "baltrusaitis_multimodal_2017" >}}:

1. Representation: It is important for us to know how to represent each unimodality or multimodality
2. Translation: This is the mapping from one data mode to another, e.g. using spectrogram to transform audio to image
3. Alignment or Registration: This is the direct relation between elements from two or more different modalities. If they are in the same modality, we would call it *registration*.
4. Fusion: It is to join information from two or more modalities to perform a downstream task.
5. Co-learning: Transforming knowledge from different modalities


For this series, we are not shaped by the five main aspects, instead, we would organized by modalities. In this post, we are focusing on the Text and Image, with such amounts of researchs and works, First, we would introduce the big short from OpenAI: CLIP {{< cite "radford_learning_nodate" >}} as it can be seen as one of the milstones of multimodality studies. After the CLIP models, there are multiple different kinds of multimodal-based models, e.g. ALBEF{{< cite "li2021align" >}}, BLIP {{< cite "ramesh_hierarchical_2022" >}}, VLMO {{< cite "bao2022vlmo" >}}, and Flamingo {{< cite "alayrac2022flamingo" >}}. I chose BLIP {{< cite "li_blip_nodate" >}} as it can be seen as the supplimentary of the CLIP model, as it not only consider the representation, but also the understanding of the multimodal data.

## CLIP: Learning Transferable Visual Models From Natural Language Supervision

CLIP's key contribution is its ability to map text and image into a shared embedding space based on the seperated text/image encoder. This shared multimodal embedding space makes text-to-image and image-to-text tasks so much easier. Not meaning that it can directly used in these tasks, but providing a idea that how to do the multimodal representation.

{{< image
  class="semwebdemostyle"
  src="https://s3.cklau.cc/outline/uploads/b6880a0c-d8fc-4d04-9621-1e308a59ebb4/64cc5e48-d9a3-46aa-95b2-b6e0e9467fb3/image.png"
  link="/post/scientia/machine-learning/multi-modality"
  alt="ALT"
  caption="Fig. 1. The architecture of CLIP model"
  attr="OPENAI"
  attrlink="https://openai.com"
  width="100%"
>}}

*Fig. 1.* shows the approach of CLIP model. Text and image are encoded by two different encoders $f_{\theta_i}$ and $g_{\theta_t}$, let $\mathbf{x} \in \mathbb{R}^{N \times H \times W \times C}$ as one batch of image, $\mathbf{y} \in \mathbb{R}^{N \times S}$ as one batch of text data,  the embedding of $\mathbf{x}$ and $\mathbf{y}$ then can be denoted as:

$$\begin{aligned} \mathbf{f} &= f_{\theta_i}(\mathbf{x}) \in \mathbf{R}^{N \times D_i} \Rightarrow \mathbf{f}^e = L_i(\mathbf{f})  \cr  \mathbf{g} &= g_{\theta_t}(\mathbf{y}) \in \mathbf{R}^{N \times D_t} \Rightarrow \mathbf{g}^e = L_t(\mathbf{g}) \end{aligned}$$

where $D_i$ and $D_t$ are the dimension of the image and text embedding, respectively. linear projectors $L_i$ and $L_t$ are used for mapping two embedding into the same dimension. The dot product between the image and text embedding is used to calculate the similarity between the text and image, i.e., $\mathcal{F} = \mathbf{f} \cdot \mathbf{g}$, where $\mathcal{F} \in \mathbb{R}^{N \times N}$ is the similarity matrix and the $\mathcal{F} \circ I_N$ is the positive sample set {{% sidenote %}}where $I_N$ is the identity matrix, and $\mathcal{F} \circ I_N$ is the matrix's diagonal {{% /sidenote %}}, and the others are the negative samples (In total, there are $N^2 - N$ negatives samples). The pseudocode of the CLIP model is shown in Figure 2 (original papers). The idea of CLIP model is relative naive, as it is a classic negative sampling method called batch negative sampling. However, intuitively, it is hard for us to do the model explanation, i.e., why does it work? Still, we could explan that the corresponding text and image are sharing the same ontology, but this kind of explanation is not grounded. More or less, the main contribution is that they create a huge dataset with the text and image pairs, including 400 million (image, text) pairs collected form of a variety of publicly available sources on the Internet. With this dataset, they don't even need the pretrained encoder as the encoder can be trained simultaneously with the downstream alignment. 

### Implementation

Here is the simple implementation of CLIP:

<details>
  <summary>Implementation of Encoders</summary>

  ```python
  import torch 
  import torch.nn as nn
  from transformers import AutoConfig, AutoModel, AutoModelForImageClassification

  import numpy as np

  class TextEncoder(nn.Module):
      def __init__(self, model_name="FacebookAI/roberta-base":str, device="cpu":str, pretrained=True:bool, freeze=False:bool):
          super(TextEncoder).__init__()
          self.model = {True: AutoModel.from_pretrained(model_name), 
                        False: AutoModel.from_config(AutoConfig.from_pretrained(model_name))}
          self.out_dim = AutoConfig.from_pretrained(model_name).hidden_size # 768
          self.freeze = freeze
          if freeze:
              for name ,param in self.model.named_parameters():
                  param.requires_grad = False

      def forward(self, inputs):
          if self.freeze:
              self.model.eval()
          else:
              pass
          feature = nn.functional.normalize(torch.mean(self.model(**inputs).last_hidden_state, axis=1), dim=1)
          return feature

  class ImageEncoder(nn.Module):
      def __init__(self, model_name="google/vit-base-patch16-224":str, device="cpu":str, pretrained=True:bool, freeze=False:bool):
          super(TextEncoder).__init__()
          self.model = {True: AutoModelForImageClassification.from_pretrained(model_name), 
                        False: AutoModelForImageClassification.from_config(AutoConfig.from_pretrained(model_name))}
          self.out_dim = 1000 # ViT is trained with ImageNet
          self.freeze = freeze
          if freeze:
              for name ,param in self.model.named_parameters():
                  param.requires_grad = False

      def forward(self, inputs):
          feature = self.model(**inputs).logits
          feature = F.normalize(feature, dim=-1)
          return feature
  ```
</details>

<details>
  <summary>Implementation of Linear Projection</summary>
  
```python
  class LinearProject(nn.Module):
      def __init__(self, in_features, out_features):
          super(LinearProject).__init__()
          self.projection == nn.Sequential([
              nn.Linear(in_features, out_features), nn.GELU(), nn.LayerNorm(out_features)
          ])

      def forward(self, x):
          output = self.projection(x)
          return output
  ```
</details>

<details>
  <summary>Implementation of CLIP Model</summary>
  
  ```python
  class CLIPModel(nn.Module):
      def __init__(self, model_name = {"TEXT":"FacebookAI/roberta-base", "IMG":"google/vit-base-patch16-224"}:dict, 
                    device="cpu":str, pretrained=True:bool, freeze=False:bool, hidden_dim=256:int):
          super(CLIPModel).__init__()
          self.enc_t = TextEncoder(model_name=model_name["TEXT"], device=device, freeze=freeze)
          self.enc_i = ImageEncoder(model_name=model_name["IMG"], device=device, freeze=freeze)
          self.proj_t = LinearProject(self.enc_t.out_dim, hidden_dim)
          self.proj_i = LinearProject(self.enc_i.out_dim, hidden_dim)
          self.logit_scale = nn.Parameter(torch.ones([]))
          self.init_parameters()
      
      def init_parameters(self):
          # turn temperature into a learnable parameter
          nn.init.constant_(self.logit_scale, np.log(1 / 0.07))
      
      def criterion(self, text, image):
          CE = nn.functional.cross_entropy
          labels = torch.arange(text.shape[0], device=str(text.device), dtype=torch.long)
          logits_t = text @ image.T * self.logit_scale.exp()
          logits_i = image @ text.T * self.logit_scale.exp()
          loss = (CE(logits_t, labels) + CE(logits_i, labels)) / 2
          return loss

      def forward(self, text, image):
          feature_t, feature_i = self.proj_t(self.enc_t(text)), self.proj_i(self.enc_i(image))
          loss = self.criterion(feature_t, feature_i)
          return feature_t, feature_i, self.logit_scale, loss
  ```
</details>

### Applications

The first application of CLIP is classification. Since the CLIP model is relatively similar to the reitrival model, it can be easily implemented into the classification with zero-shot learning. The zero-shot learning is a task that the model can classify the unseen classes without any training data. See the second part of Figure 1, where for a given image, the model can classify the similarity between the given image and the prompted text, by calculating the similarity of image and each given sentence we could get the classification, vice versa. This can be seen as classification, or retrieval. 

The second application is the generation. The CLIP model can be used to generate the image from the given text. Although it cannot generate the image directly since it does not have any decoder, however, the CLIP can be seen as the backbone and provide the embedding for image or text generation. After the CLIP came out, OpenAI also released the DALL·E 2, where they provide a model called unCLIP {{< cite "ramesh_hierarchical_2022" >}}, it is a text-to-image generation model[^2].

### Full Text

<details>
  <summary>Full Text</summary>
  <iframe src="https://share.cklau.cc/generic/web/viewer_readonly.html?file=webdrive/QZJJSWF2/Radford%20et%20al.%20-%20Learning%20Transferable%20Visual%20Models%20From%20Natural%20L.pdf" width="100%" height="1000" frameborder="0" allowfullscreen></iframe>
</details>

## BLIP: Bootstrapping Language-Image Pre-training for Unified Vision-Language Understanding and Generation

Unlike the CLIP's siamese-shaped model, BLIP is a multimodal architecture that seperate the representation and generation into a two stage process. In the first stage, they generate the text embedding and image embedding, and for the second stage, they use the decoder that generates an image conditioned on the image embedding. This architecture is proposed based on these two research questions:

1. Most existing pre-trained models only perform well on comprehension-based tasks or generation-based tasks, and few models can **do both**.
2. Most existing pre-trained models extend the dataset using noisy image-text pairs collected from the network in order to improve performance. Although this improves performance, it is obvious that this **noisy supervision** signal is definitely not optimal[^3].

Based on these two research gap, they proposed the Multimodel mixture of Encoder-Decoder(MED) architecture, shown in Fig. 2.

{{< image
  class="semwebdemostyle"
  src="https://s3.cklau.cc/outline/uploads/b6880a0c-d8fc-4d04-9621-1e308a59ebb4/093cd5d4-5ce9-486f-87ed-5036f208a9f7/image.png?"
  link="/post/scientia/machine-learning/multi-modality"
  alt="ALT"
  caption="Fig. 2. The Architecture of 'Multimodel mixture of Encoder-Decoder' (MED) architecture"
  attr="Salesforce Research"
  attrlink="https://blog.salesforceairesearch.com/blip-bootstrapping-language-image-pretraining/"
  width="100%"
>}}

The three tasks are proposed for the training: 

1. Image-text contrastive (ITC) learning: on the very left side of *Fig. 2.* is a Image Encoder, where it adapts the ViT{{< cite "dosovitskiy2020image" >}} for the image representation. The second part is the Text Encoder, where it adapts the BERT{{< cite "devlin2018bert" >}} for the text representation. The ITC learning is to maximize the similarity between the image and text embedding, and minimize the similarity between the negative samples. The idea of the ITC is the same as CLIP where using the contrastive learning to align the text and image embedding. 
2. Image-text matching (ITM) learning: The third modules is Image-graouded Text Decoder, where it is a transformer-based decoder with cross-attention layer to include the image embedding, and the mixed embedding are used for the ITM learning to check whether the text and image are aligned.
3. Language modeling (LM) learning: The last part is the Image-grounded text decoder. This decoder uses causal self-attention to replace the self-attetion layer in the BERT, and the image embedding also injected with the cross attention block for the text generation.

To leverage the multi-task learning process, all the blocks with the same color are shareing the same parameters. This MED architecture shares some common modules with the ALBEF{{< cite "li2021align" >}} and VLMO {{< cite "bao2022vlmo" >}} where the ITC is adapted from the CLIP while the ITM can be seen as the refinement ore the constrastive learning, as it take the hardest negative samples (from the ITC) as the negative samples in ITM; and the LM is for the text generation, which is the same as the VLMO.

{{< image
  class="semwebdemostyle"
  src="https://s3.cklau.cc/outline/uploads/b6880a0c-d8fc-4d04-9621-1e308a59ebb4/86de6bd9-f8c6-427f-bccb-f9fed8edb919/image.png"
  link="/post/scientia/machine-learning/multi-modality"
  alt="ALT"
  caption="Fig. 3. The CapFilt module for solving the noisy supervision signal"
  attr="Salesforce Research"
  attrlink="https://blog.salesforceairesearch.com/blip-bootstrapping-language-image-pretraining/"
  width="100%"
>}}

The second contribution of the paper is the pipeline of eliminating the noisy superivion signal, shown in *Fig. 3*. where the Image-grounded Text Encoder and Image-grounded Text Decoder are used as **Filter** and **Captioner**. The Filter is to remove the noisy image-text pairs while the Captioner is used for generating synthetic captions given a web images. The process of Capfilt is as follows: 1) The training set $D$ is formed with web image-text pairs and clean image-text pairs, denoted as $D_w = (I_w, T_w)$ and $D_h = (I_h, T_h)$, and $D = D_w + D_h$. 2) Fine-tune the two encoder with $D_h$. 3) The **Captioner** generates caption with $D_w$'s images. 4) The **Filter** is used to remove the noisy text {{% sidenote %}}not matter the given text is scraped from the web or synthesis from the captioner{{% /sidenote %}}. Thus, the model-based data cleansing is used to remove the noisy supervision signal and the cleansed data is used for the training of the next MED{{% sidenote %}} so call **bootstraping** {{% /sidenote %}}.

### Implementation

You may check [BLIP-official Code from GitHub](https://github.com/salesforce/BLIP). You may see that [`med.py`#97](https://github.com/salesforce/BLIP/blob/3a29b7410476bf5f2ba0955827390eb6ea1f4f9d/models/med.py#L97), they define the function `BertSelfAttention` to include the cross-attention layer into the BERT's encoder.

### Applications

The BLIP model is used for multiple downstream tasks: Image-text retrieval (with Image Encoder and Text Encoder), Image Captioning(with Image-grounded Text Decoder), Visual Question Answering(with Image Encoder), Natural Language Visual Reasoning(with Image Encoder and Text Encoder), and Visual Dialog(with Image Encoder and Image-grounded text Encoder). The detailed can be seen in the original paper.

### Full Text

<details>
  <summary>Full Text</summary>
  <iframe src="https://share.cklau.cc/generic/web/viewer_readonly.html?file=webdrive/H479RWE4/Li%20et%20al.%20-%20BLIP%20Bootstrapping%20Language-Image%20Pre-training%20fo.pdf" width="100%" height="1000" frameborder="0" allowfullscreen></iframe>
</details>

### Related Researches

BLIP's Group allow continue their work on the multimodal representation learning, they proposed BLIP2{{< cite "li2023blip" >}} and InstructBLIP{{< cite "dai2023instructblip" >}}:

#### BLIP2: Bootstrapping Language-Image Pre-training with Frozen Image Encoders and Large Language Models

BLIP2 is a successor of BLIP, the overall framework is shown in *Fig. 4.*.  

{{< image
  class="semwebdemostyle"
  src="https://s3.cklau.cc/outline/uploads/b6880a0c-d8fc-4d04-9621-1e308a59ebb4/bb28c8e8-ffec-4dc8-8a70-2b57d88e8ae7/image.png"
  link="/post/scientia/machine-learning/multi-modality"
  alt="ALT"
  caption="Fig. 4. The overviewer of BLIP-2's framework"
  attr="Salesforce Research"
  attrlink="https://blog.salesforceairesearch.com/blip-2/"
  width="100%"
>}}

#### InstructBLIP: Towards General-purpose Vision-Language Models with Instruction Tuning


## Empirical Research



## Reference 

{{< references >}}



[^1]: For more information, pleace check [Spectrogram](https://en.wikipedia.org/wiki/Spectrogram) and [Mel Spectrogram](https://ieeexplore.ieee.org/document/9859621)
[^2]: We would talk about the "downstream" research in the ["Empirical Research"](#empirical-research) section.
[^3]: Remember that CLIP has a 400M dataset for the training process? They did not open-source it, leads they from OpenAI to "CloseAI" (of course, it is a business decision, but it may not be good for the research community).
