---
title: Projects
date: 2024-12-31T12:00:00+00:00
draft: false
comment: true
---

This is the page highlights the projects I have worked, is working on. Brief introduction and results are listed. 

> *The date is the last updated time. For each project’s precise started time, please check the GitHub repo timestamp or the publication accepted date*

---

## Retinal Fundus Image Synthesis

> * Repository: [https://github.com/TerenceLiu98/VSG-GAN](https://github.com/TerenceLiu98/VSG-GAN)
> 
> Related posts: 
> * [👨‍💻 Style Transfer and Synthesis (1/3): Style Transfer in Image Synthesis](scientia/dl-gan-1/)
> * [🥼 RetiGAN: A GAN-based model on retinal Image synthesis](/scientia/10.1016-j.bspc.2022.104004/)

VSG-GAN (Vessel and Style Guided Generative Adversarial Network) is a high-fidelity image synthesis method designed for semantic manipulation in retinal fundus images.

<center>
    <img src="https://32cf906.webp.li/2025/01/generator-vsggan.png" width="65%" alt="Generator of VSG-GAN">
</center>

The architecture of VSG-GAN involves extracting the vessel tree structure from an original retinal image using a segmentor. This structure, along with a random noise matrix, serves as input to the generator, which refines the image through successive stages to produce a high-quality synthetic retinal image. The discriminator then evaluates the realism of the generated image by comparing it with the original and smoothed versions, utilizing models like VGG-19 to guide the generation process based on high-level features. 

As of now, the code for VSG-GAN is cleaning up.

```
@article{liu2024vsg,
  title={VSG-GAN: A high-fidelity image synthesis method with semantic manipulation in retinal fundus image},
  author={Liu, Junjie and Xu, Shixin and He, Ping and Wu, Sirong and Luo, Xi and Deng, Yuhui and Huang, Huaxiong},
  journal={Biophysical Journal},
  year={2024},
  publisher={Elsevier}
}
```


## WGTOOLS (STALLED)

> * Repository: [https://github.com/TerenceLiu98/wgtools](https://github.com/TerenceLiu98/wgtools)

The project [**wgtools**](https://github.com/TerenceLiu98/wgtools) is an open-source repository developed to manage and simplify WireGuard VPN configurations. WireGuard is a fast, modern VPN protocol known for its simplicity, security, and performance. The **wgtools** repository appears to focus on providing utility scripts or tools that facilitate the deployment, configuration, and management of WireGuard setups, making it easier for users to handle the administrative overhead of setting up VPN connections.

### Key Features and Focus Areas
1. **Configuration Management**:
   - Automates the generation and organization of WireGuard configurations, including public/private keys and client configurations.
   - Simplifies the process of adding and removing peers from a WireGuard server.

2. **Cross-Platform**:
   - Likely to work across multiple platforms (Linux, macOS, and potentially Windows) where WireGuard is supported.

3. **Lightweight and Script-Based**:
   - The tools are lightweight and script-based, aligning with the simplicity philosophy of WireGuard itself.

### Potential Use Cases
- Quickly deploying a VPN server with multiple clients.
- Dynamically managing client connections for changing needs.
- Managing WireGuard configurations for a team or organization.

This project can be particularly helpful for users who want to harness the power of WireGuard without needing to dive deep into its configuration details. By automating tedious steps, **wgtools** makes WireGuard more accessible to a broader audience.


## MESOCP: Modern Elementary Statistics Online Computing Platform

> * Repository: [https://github.com/Bayes-Cluster/MESOCP](https://github.com/Bayes-Cluster/MESOCP)

MESOCP (Modern Elementary Statistics Online Computing Platform) is an interactive web-based platform designed to enhance the teaching and learning of elementary statistics. Developed using R and Shiny, it offers a suite of applications that facilitate statistical computations and visualizations, making statistical concepts more accessible to students and educators. The platform's development was presented in the paper "Online Statistics Teaching-assisted Platform with Interactive Web Applications using R Shiny" at the 6th International Symposium on Emerging Technologies for Education. For deployment, MESOCP provides Docker support, allowing users to run the application seamlessly on their own servers.  

```
@inproceedings{liu2021online,
  title={Online statistics teaching-assisted platform with interactive web applications using R shiny},
  author={Liu, Junjie and Deng, Yuhui and Peng, Xiaoling},
  booktitle={International Symposium on Emerging Technologies for Education},
  pages={84--91},
  year={2021},
  organization={Springer}
}
```

## Parallelized Multi-key RSA (PMKRSA) Scheme

> * Repository: NA

The standard RSA relies on multiple big-number modular exponentiation operations and a longer key-length is required for better protection. This imposes a hefty time penalty for encryption and decryption. In this study, we analysed and developed an improved parallel algorithm (PMKRSA) based on the idea of splitting the plaintext into multiple chunks and encrypt the chunks using multiple key-pairs. The algorithm in our new scheme is so natural for parallelised implementation that we also investigated its parallelisation in a GPU environment. In the following, the structure of our new scheme is outlined and its correctness is proved mathematically. Then, with the algorithm implemented and optimised on both CPU and CPU+GPU platforms, we showed that our algorithm shortens the computational time considerably, and it has a security advantage over the standard RSA as it is invulnerable to the common attacks. Finally, we also proved the feasibility of using our algorithm to encrypt large files through simulation. The results show that over the set of file size: 1 MB, 10 MB, 25 MB, 50 MB, 100 MB, the average encryption and decryption time of the CPU version is 0.2476 and 9.4476 s, and for the CPU+GPU version, it is 0.0009 and 0.0618 s, respectively.

```
@article{liu2022variant,
  title={A variant RSA acceleration with parallelisation},
  author={Liu, Jun-Jie and Tsang, Kang-Too and Deng, Yu-Hui},
  journal={International Journal of Parallel, Emergent and Distributed Systems},
  volume={37},
  number={3},
  pages={318--332},
  year={2022},
  publisher={Taylor \& Francis}
}
```