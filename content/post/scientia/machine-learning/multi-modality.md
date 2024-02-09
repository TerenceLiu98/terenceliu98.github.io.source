---
title: "👨🏿‍⚕️ Multimodal Representation Leraning from both Text and Image"
date: 2024-02-08T00:15:00+00:00
draft: false
math: true
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


For this series, we are not shaped by the five main aspects, instead, we would organized by modalities. In this post, we are focusing on the Text and Image, with such amounts of researchs and works, I decided to follow on the two papers: CLIP {{< cite "radford_learning_nodate" >}} and BLIP {{< cite "li_blip_nodate" >}}, some of their variants would be mentioned.

## CLIP: Learning Transferable Visual Models From Natural Language Supervision

CLIP's key contribution is its ability to map text and image into a shared embedding space based on the seperated text/image encoder. This shared multimodal embedding space makes text-to-image and image-to-text tasks so much easier. Not meaning that it can directly used in these tasks, but providing a idea that how to do the multimodal representation.

{{< image
  class="semwebdemostyle"
  src="https://s3.cklau.cc/outline/uploads/b6880a0c-d8fc-4d04-9621-1e308a59ebb4/64cc5e48-d9a3-46aa-95b2-b6e0e9467fb3/image.png"
  link="/post/scientia/machine-learning/multi-modality/clip"
  alt="ALT"
  caption="Figure 1: The architecture of CLIP model"
  attr="OPENAI"
  attrlink="https://openai.com"
  width="100%"
>}}

Figure 1 shows the approach of CLIP model. Text and image are encoded by two different encoders $f_{\theta_i}$ and $g_{\theta_t}$, let $\mathbf{x} \in \mathbb{R}^{N \times H \times W \times C}$ as one batch of image, $\mathbf{y} \in \mathbb{R}^{N \times S}$ as one batch of text data,  the embedding of $\mathbf{x}$ and $\mathbf{y}$ then can be denoted as:

$$\begin{aligned} \mathbf{f} &= f_{\theta_i}(\mathbf{x}) \in \mathbf{R}^{N \times D_i} \Rightarrow \mathbf{f}^e = L_i(\mathbf{f})  \cr  \mathbf{g} &= g_{\theta_t}(\mathbf{y}) \in \mathbf{R}^{N \times D_t} \Rightarrow \mathbf{g}^e = L_t(\mathbf{g}) \end{aligned}$$

where $D_i$ and $D_t$ are the dimension of the image and text embedding, respectively. linear projectors $L_i$ and $L_t$ are used for mapping two embedding into the same dimension. The dot product between the image and text embedding is used to calculate the similarity between the text and image, i.e., $\mathcal{F} = \mathbf{f} \cdot \mathbf{g}$, where $\mathcal{F} \in \mathbb{R}^{N \times N}$ is the similarity matrix and the $\mathcal{F} \circ I_N$ is the positive sample set, and the others are the negative samples (In total, there are $N^2 - N$ negatives samples). The pseudocode of the CLIP model is shown in Figure 2 (original papers). The idea of CLIP model is relative naive, as it is a classic negative sampling method called batch negative sampling. The main contribution is that they create a huge dataset with the text and image pairs, including 400 million (image, text) pairs collected form of a variety of publicly available sources on the Internet. With this dataset, they don't even need the pretrained encoder as the encoder can be trained simultaneously with the downstream alignment. 

### Applications

The first application of CLIP is classification. Since the CLIP model is relatively similar to the reitrival model, it can be easily implemented into the classification with zero-shot learning. The zero-shot learning is a task that the model can classify the unseen classes without any training data. See the second part of Figure 1, where for a given image, the model can classify the similarity between the given image and the prompted text, by calculating the similarity of image and each given sentence we could get the classification, vice versa. This can be seen as classification, or retrieval. 

The second application is the generation. The CLIP model can be used to generate the image from the given text. Although it cannot generate the image directly since it does not have any decoder, however, the CLIP can be seen as the backbone and provide the embedding for image or text generation. After the CLIP came out, OpenAI also released the DALL-E2, where they provide a model called unCLIP {{< cite "ramesh_hierarchical_2022" >}}

## Reference 

{{< references >}}



[^1]: For more information, pleace check [Spectrogram](https://en.wikipedia.org/wiki/Spectrogram) and [Mel Spectrogram](https://ieeexplore.ieee.org/document/9859621)