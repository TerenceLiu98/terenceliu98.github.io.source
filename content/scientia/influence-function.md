---
title: "🧮 Interpretability of Machine Learning Algorithm"
date: 2024-12-27T00:15:00+00:00
draft: false
math: true
comment: true
tags: ['Artificial Intelligence', 'XAI', 'interpretability']
series: ['XAI']
bibFile: /content/post/scientia/machine-learning/bib.json
---

# Instance-Based Interpretability - Influence Function(IF)

## Brief History of IF 

The history of the influence function lies at the intersection of classical statistics and modern machine learning. It originates from the field of robust statistics, where it was developed to study the sensitivity of statistical estimators to small changes in the data. 

The concept of the IF was first introduced by Frank R. Hampel {{< cite "hampel1974influence" >}} in 1970s , where it is used to study how a single data point (or a small pertubation in the data) affects the behaviour of a statistical estimator. This work became foundational in robust statistics, as it provided a way to analyze the robustness of estimators against outliers or small changes in the dataset. Hampel's influence function provided a systematic way to quantify how an infinitesimal contamination of the data at a single point could impact an estimator. Mathematically, it defined the response of an estimator to a small perturbation in the underlying distribution, laying the groundwork for evaluating and designing robust estimators.

During the 1970s and 1980s, the influence function became a critical tool in robust statistics, with contributions from researchers such as Peter J. Huber {{< cite "huber1983minimax" >}}. It was used extensively to analyze the sensitivity of M-estimators, a class of robust statistical estimators designed to minimize a modified loss function that reduces sensitivity to outliers. These developments allowed statisticians to better understand the trade-offs between robustness and efficiency, leading to practical applications such as outlier detection, data cleaning, and the evaluation of statistical methods' stability under small perturbations.

In the 1990s and 2000s, the influence function began to find applications in computational statistics and machine learning. It was used to understand the sensitivity of estimators in resampling methods such as cross-validation and bootstrapping {{< cite "efron1994introduction" >}}. Additionally, it became a theoretical tool for evaluating the robustness of statistical models in applied settings, including regression analysis and model diagnostics. The influence function provided insights into how removing or altering individual data points could impact statistical estimators, enabling practitioners to identify problematic or influential observations.

The influence function experienced a resurgence in the 2010s with its adaptation to machine learning and modern computational models. In 2017, Koh and Liang's work {{< cite "koh2017understanding" >}} extended the classical influence function to modern machine learning, including neural networks. They demonstrated how influence functions could trace predictions of complex models back to individual training points, allowing researchers to debug models, explain predictions, and evaluate the impact of specific training data on the model's behavior. This work made the influence function computationally feasible in large-scale settings by approximating the inverse Hessian matrix, which had previously been a computational bottleneck.

## Mathematic Foundation

In this section, we will introduce the foundation of IF in mathematical aspect. Let $\mathbf{z} = \{z\_i\}\_{i=1}^{n}$ represent a set of data point where $z\_i \mathop{\sim}\limits^{i.i.d} P$. Let $T(P)$ be the parameter or estimator of interest, defined as a function of the distribution $P$. The influence function quantifies the effect of adding a small perturbation $\epsilon$ to the distribution $P$, where the pertubed distribtuion is defined as: 

$$P\_{\epsilon} = (1 - \epsilon)P + \epsilon \cdot \delta\_{z\_i}$$

where $P$ is the original distribution, $\delta\_{z\_i}$ is dirac delta distribution {{< sidenote >}}where the dirac delta distribution assigns probability $1$ to $z\_i$ while $0$ to all other elements. As the retriction of we only focus on the single datapoint or perturbation{{</ sidenote >}} at $z\_i$  and $\epsilon$ si the weight of the pertubation, with $\epsilon \to 0$. Thus, the **Influence Function(IF)** of $z\_i$ is defined as the derivative{{< sidenote >}}Gateaux derivative{{</ sidenote >}} of $T(P)$ w.r.t $\epsilon$, evaluate at $\epsilon = 0$:

\begin{equation}
    \textbf{IF}(z\_i;T,P) = \lim\_{\epsilon \to 0} \frac{T(P\_{\epsilon}) - T(P)}{\epsilon}
\end{equation}

The mathematical definitiion of IF is analogous to the derivative of a function, where:

$$\frac{df}{dx} = \lim\_{h \to 0} \frac{f(x + h) - f(x)}{h}$$

where $\epsilon$ plays the role of $h$, reprensenting the tiny change in the distribution. Just as the derivative measures the rate of change of $f(x)$, the IF measures the rate of change of the estimator $T(P)$ w.r.t small pertubations in $P$.

To compute the IF, we assume that the parameter $\theta = T(P)$ is defined throught an estimating equation: $\mathbb{E}\_P [\psi(z;\theta)] = 0$, where $\psi(z; \theta)$ is the score function or estimatiing function that defines the relation between the data and the parameter. $\mathbb{E}\_P$ is the expectation w.r.t the original distribution $P$. Similarly, when the data distribution is pertubed, the expectataion in the estimating equation changes to: 

\begin{equation}
    \mathbb{E}\_{P\_{\epsilon}} [\psi(z;\theta\_{\epsilon})] = 0
\end{equation}

To analyze $\theta\_{\epsilon}$, we expand the score function $\psi(\cdot)$ with Taylor expansion around $\theta$:

$$\psi(z; \theta\_{\epsilon}) \approx \psi(z; \theta\_{\epsilon}) + \frac{\partial \psi(z; \theta\_{\epsilon})}{\partial \theta}(\theta\_{\epsilon} - \theta)$$

By subsitute the taylor expansion form into the pertubed estimating equation, we can get:

$$(1 - \epsilon) \mathbb{E}\_{P} \left\[\psi(z; \theta) + \frac{\partial \psi(z; \theta\_{\epsilon})}{\partial \theta}(\theta\_{\epsilon} - \theta)\right\] + \epsilon \left\[\psi(z; \theta) + \frac{\partial \psi(z; \theta\_{\epsilon})}{\partial \theta}(\theta\_{\epsilon} - \theta)\right\] = 0$$

thus we can simplify by ignoring higher-order term (proportional to $\epsilon^2$) and using the fact that $\mathbb{E}\_P[\psi(z; \theta)] = 0$: 

\begin{equation}
    \begin{aligned}
        \epsilon \psi(z; \theta) + \mathbb{E}\_{P} \left\[\frac{\partial \psi(z; \theta\_{\epsilon})}{\partial \theta}(\theta\_{\epsilon} - \theta)\right\] &= 0 \\\\
        \theta\_{\epsilon} - \theta &= - \left\( \mathbb{E}\_{P} \left\[\frac{\partial \psi(z; \theta\_{\epsilon})}{\partial \theta}(\theta\_{\epsilon} - \theta)\right\]\right\)^{-1} \psi(z; \theta)
    \end{aligned}
\end{equation}

This expression represents the change in the parameter due to the perturbation, and the based on the IF's definition, the limiting change in $\theta$ per unit pertubation is:

\begin{equation} \label{eq:if-theta}
    \begin{aligned}
        \textbf{IF}(z; \theta, P) &= \lim\_{\epsilon \to 0} \frac{\theta_{\epsilon} - \theta}{\epsilon} \\\\
        &= - \left\( \mathbb{E}\_{P} \left\[\frac{\partial \psi(z; \theta\_{\epsilon})}{\partial \theta}(\theta\_{\epsilon} - \theta)\right\]\right\)^{-1} \psi(z; \theta)
    \end{aligned}
\end{equation}

For the Deep learning model, the objective is to minimize the empirical risk(ERM):

$$\hat{\theta} = \arg \min\_{\theta} \frac{1}{n} \sum\_{i=1}^{n} L(z\_i, \theta)$$

where $\hat{\theta}$ is the optimum, $z\_i = (x\_i, y\_i)$ is the training sample, and $L(\cdot)$ is the loss function. Since $\hat{\theta}$ is the optimum, based on the First-order Optimality Condition, we can get:

\begin{equation}
    \nabla\_{\theta} L(\hat{\theta}) =  \frac{1}{n} \sum\_{i=1}^{n} \nabla\_{\theta} L(z\_i, \hat{\theta})  = 0
\end{equation}

The research question is: the how wold the model's prediction change when the perturbation is applied to the training sample $z_i$? To answer this question, let's rewrite the objective function:

$$\hat{\theta} = \arg \min\_{\theta} \frac{1}{n} \sum\_{j=1}^{n} L(z\_j, \theta) + \epsilon L(z\_i, \theta)$$

where $\epsilon$ is a small scalar pertubation. The goal is to analyze how this pertubation impacts the optimal $\hat{\theta}$, leading to pertubed optimal $\hat{\theta}\_{\epsilon, i}$:


and the pertubed loss function becomes:

$$L\_{\epsilon}(\theta) = \frac{1}{n} \sum\_{i=1}^{n} \mathcal{l}(z\_i, \theta) + \epsilon \mathcal{l}(z\_i, \theta)$$

The goal is to measure how $\theta\_{\epsilon}$ changes with respect to $\epsilon$. With the suage of the first-order Taylor expansion, the change in $\theta$ can be approximated as: 

$$\delta \theta = \theta\_{\epsilon} - \theta \approx -\epsilon \mathbf{H}^{-1} \nabla\_{\theta} \mathcal{l}(z\_j, \theta)$$

where $\mathbf{H} = \frac{1}{n} \sum\_{i=1}^{n} \nabla^{2}\_{\theta}\mathcal{l}(z\_i, \theta)$ is the Hessian matrix of the loss function  and $\nabla\_{\theta}\mathcal{l}(z\_j, \theta)$ is the gradient of the loss for the training sample $z\_j$.  Thus, the influence of training sample $z\_j$ on the prediction for a test point $z\_test$ can be computed as:

\begin{equation}
    \textbf{IF}\_{\text{up, loss}}(z\_j, z\_test) = - \nabla\_{\theta} \mathcal{l}(z\_test, \theta)^T \mathbf{H}^{-1} \nabla\_{\theta}\mathcal{l}(z\_j, \theta)
\end{equation}

## Reference 

{{< references >}}