---
title: "👨🏿‍⚕️ Multimodal Representation Leraning from both Text and Image"
date: 2024-02-08T00:15:00+00:00
draft: true
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

<center>{{< figure src="https://s3.cklau.cc/outline/uploads/b6880a0c-d8fc-4d04-9621-1e308a59ebb4/01a358bb-57e0-4803-ac14-248e8666b209/Screenshot%202024-02-08%20at%204.27.08%20PM.png" width="50%" title="图1" >}}</center>

## Reference 

{{< bibliography cited >}}



[^1] For more information, pleace check [Spectrogram](https://en.wikipedia.org/wiki/Spectrogram) and [Mel Spectrogram](https://ieeexplore.ieee.org/document/9859621)
