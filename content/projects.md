---
title: Projects & Related Publications
date: 2024-12-31T12:00:00+00:00
draft: false
comment: true
math: true
---


{{< research_card
    title="VSG-GAN: A High Fidelity Image Synthesis Method with Semantic Manipulation in Retinal Fundus Image"
    conference="Biophysical Journal, 2024"
    authors="Junjie Liu, Shixin Xu, Ping He, Sirong Wu, Xi Luo, Yuhui Deng, Huaxiong Huang"
    pdf="https://www.cell.com/biophysj/abstract/S0006-3495(24)00139-5"
    doi=" 10.1016/j.bpj.2024.02.019"
    github="https://github.com/TerenceLiu98/VSG-GAN"
>}}

<center>
    <img src="https://32cf906.webp.li/2025/01/generator-vsggan.png" width="65%" alt="Generator of VSG-GAN">
</center>

In recent years, advancements in retinal image analysis, driven by machine learning and deep learning techniques, have enhanced disease detection and diagnosis through automated feature extraction. However, challenges persist, including limited data set diversity due to privacy concerns and imbalanced sample pairs, hindering effective model training. To address these issues, we introduce the vessel and style guided generative adversarial network (VSG-GAN), an innovative algorithm building upon the foundational concept of GAN. In VSG-GAN, a generator and discriminator engage in an adversarial process to produce realistic retinal images. Our approach decouples retinal image generation into distinct modules: the vascular skeleton and background style. Leveraging style transformation and GAN inversion, our proposed hierarchical variational autoencoder module generates retinal images with diverse morphological traits. In addition, the spatially adaptive denormalization module ensures consistency between input and generated images. We evaluate our model on MESSIDOR and RITE data sets using various metrics, including structural similarity index measure, inception score, Fréchet inception distance, and kernel inception distance. Our results demonstrate the superiority of VSG-GAN, outperforming existing methods across all evaluation assessments. This underscores its effectiveness in addressing data set limitations and imbalances. Our algorithm provides a novel solution to challenges in retinal image analysis by offering diverse and realistic retinal image generation. Implementing the VSG-GAN augmentation approach on downstream diabetic retinopathy classification tasks has shown enhanced disease diagnosis accuracy, further advancing the utility of machine learning in this domain.

{{< /research_card >}}

{{< research_card
    title="Online Statistics Teaching-assisted Platform with Interactive Web Applications using R Shiny"
    conference="The 6th International Symposium on Emerging Technologies for Education, 2021"
    authors="Junjie Liu, Yuhui Deng, Xiaoling Peng"
    pdf="https://link.springer.com/chapter/10.1007/978-3-030-92836-0_8"
    doi=" 10.1007/978-3-030-92836-0_8"
    github="https://github.com/Bayes-Cluster/MESOCP"
>}}

The study of uncertainty is one of the essential parts of statistics, but not easy for students to understand especially in elementary statistical classes. With the rise of new technologies and media, it is worthwhile to think about how to promote innovation in class teaching combining these new technologies with online platforms. In this article, we develop a collection of dynamic interactive web-based applications with Shiny package based on our textbook “Modern Elementary Statistics”. The online and interactive teach-assisted platform seeks to facilitate conceptual understanding of the main aspects of elementary statistics, such as data description, statistical distributions, statistical inferences, and regression analysis. As the platform is affiliated with the textbook, it can ease the teaching and learning of important theorems and techniques for introductory probability and statistics.

{{< /research_card >}}

{{< research_card
    title="Analysis of main risk factors causing stroke in Shanxi Province based on machine learning models"
    conference="Informatics in Medicine Unlocked, 2021"
    authors="Junjie Liu, Yiyang Sun, Jing Ma, Jiachen Tu, Yuhui Deng, Ping He, Rongshan Li, Fengyun Hu Huaxiong Huang, Xiaoshuang Zhou, Shixin Xu"
    pdf="https://www.sciencedirect.com/science/article/pii/S2352914821001933"
    doi=" 10.1016/j.imu.2021.100712"
>}}

The study analyzes stroke risk factors in Shanxi Province using machine learning models on community and hospital data. Hypertension, physical inactivity, and overweight are identified as key factors. Random forest and logistic regression quantify stroke risks, providing insights for prevention. Results emphasize geographic and lifestyle-specific variations in stroke risks.

{{< /research_card >}}

{{< research_card
    title="A variant RSA acceleration with parallelisation"
    conference="International Journal of Parallel, Emergent and Distributed Systems, 2021"
    authors="Junjie Liu, Shixin Xu, Ping He, Sirong Wu, Xi Luo, Yuhui Deng, Huaxiong Huang"
    pdf="https://arxiv.org/abs/2111.11924"
    doi=" 10.1080/17445760.2021.2024535"
>}}

The standard RSA relies on multiple big-number modular exponentiation operations and a longer key-length is required for better protection. This imposes a hefty time penalty for encryption and decryption. In this study, we analysed and developed an improved parallel algorithm (PMKRSA) based on the idea of splitting the plaintext into multiple chunks and encrypt the chunks using multiple key-pairs. The algorithm in our new scheme is so natural for parallelised implementation that we also investigated its parallelisation in a GPU environment. In the following, the structure of our new scheme is outlined and its correctness is proved mathematically. Then, with the algorithm implemented and optimised on both CPU and CPU+GPU platforms, we showed that our algorithm shortens the computational time considerably, and it has a security advantage over the standard RSA as it is invulnerable to the common attacks. Finally, we also proved the feasibility of using our algorithm to encrypt large files through simulation. The results show that over the set of file size: 1 MB, 10 MB, 25 MB, 50 MB, 100 MB, the average encryption and decryption time of the CPU version is 0.2476 and 9.4476 s, and for the CPU+GPU version, it is 0.0009 and 0.0618 s, respectively.

{{< /research_card >}}

