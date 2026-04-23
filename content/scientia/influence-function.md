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

# Instance-Based Interpretability — Influence Function (IF)

Modern machine-learning models are notoriously hard to interpret. While many post-hoc methods focus on *features* (e.g. LIME, SHAP, Grad-CAM), an equally natural question is: **which training examples are responsible for a particular prediction?** The *Influence Function* (IF) provides a principled, calculus-based answer to this question, by asking how the model would change if a particular training point were perturbed, up-weighted, or removed.

## Brief History of IF

The history of the influence function lies at the intersection of classical statistics and modern machine learning. It originates from the field of robust statistics, where it was developed to study the sensitivity of statistical estimators to small changes in the data.

The concept of the IF was first introduced by Frank R. Hampel {{< cite "hampel1974influence" >}} in the 1970s, where it was used to study how a single data point (or a small perturbation in the data) affects the behavior of a statistical estimator. This work became foundational in robust statistics, as it provided a way to analyze the robustness of estimators against outliers or small changes in the dataset. Hampel's influence function provided a systematic way to quantify how an infinitesimal contamination of the data at a single point could impact an estimator. Mathematically, it defined the response of an estimator to a small perturbation in the underlying distribution, laying the groundwork for evaluating and designing robust estimators.

During the 1970s and 1980s, the influence function became a critical tool in robust statistics, with contributions from researchers such as Peter J. Huber {{< cite "huber1983minimax" >}}. It was used extensively to analyze the sensitivity of M-estimators, a class of robust statistical estimators designed to minimize a modified loss function that reduces sensitivity to outliers. These developments allowed statisticians to better understand the trade-offs between robustness and efficiency, leading to practical applications such as outlier detection, data cleaning, and the evaluation of statistical methods' stability under small perturbations.

In the 1990s and 2000s, the influence function began to find applications in computational statistics and machine learning. It was used to understand the sensitivity of estimators in resampling methods such as cross-validation and bootstrapping {{< cite "efron1994introduction" >}}. Additionally, it became a theoretical tool for evaluating the robustness of statistical models in applied settings, including regression analysis and model diagnostics. The influence function provided insights into how removing or altering individual data points could impact statistical estimators, enabling practitioners to identify problematic or influential observations.

The influence function experienced a resurgence in the 2010s with its adaptation to machine learning and modern computational models. In 2017, Koh and Liang's work {{< cite "koh2017understanding" >}} extended the classical influence function to modern machine learning, including neural networks. They demonstrated how influence functions could trace predictions of complex models back to individual training points, allowing researchers to debug models, explain predictions, and evaluate the impact of specific training data on the model's behavior. This work made the influence function computationally feasible in large-scale settings by approximating the inverse-Hessian–vector product, which had previously been a computational bottleneck.

## Mathematical Foundation

### The Classical (Statistical) Influence Function

In this section we introduce the foundation of the IF in mathematical terms. Let $\mathbf{z} = \{z\_i\}\_{i=1}^{n}$ represent a set of data points where $z\_i \mathop{\sim}\limits^{i.i.d.} P$. Let $T(P)$ be the parameter or estimator of interest, defined as a *functional* of the distribution $P$. The influence function quantifies the effect of adding a small perturbation $\epsilon$ to the distribution $P$, where the perturbed distribution is defined as:

$$P\_{\epsilon} = (1 - \epsilon)\,P + \epsilon \cdot \delta\_{z\_i}$$

where $P$ is the original distribution, $\delta\_{z\_i}$ is the Dirac delta distribution{{< sidenote >}}The Dirac delta distribution assigns probability $1$ to $z\_i$ and $0$ to every other point — a clean way to encode a single-point perturbation.{{</ sidenote >}} at $z\_i$, and $\epsilon$ is the weight of the perturbation, with $\epsilon \to 0$. Thus, the **Influence Function (IF)** of $z\_i$ is defined as the derivative{{< sidenote >}}Formally a Gâteaux derivative — the directional derivative of the functional $T$ in the direction of the contamination $\delta\_{z\_i} - P$.{{</ sidenote >}} of $T(P)$ w.r.t. $\epsilon$, evaluated at $\epsilon = 0$:

\begin{equation}
    \textbf{IF}(z\_i;\,T,\,P) \;=\; \lim\_{\epsilon \to 0} \frac{T(P\_{\epsilon}) - T(P)}{\epsilon}
\end{equation}

The mathematical definition of the IF is analogous to the derivative of a function:

$$\frac{df}{dx} = \lim\_{h \to 0} \frac{f(x + h) - f(x)}{h}$$

where $\epsilon$ plays the role of $h$, representing the tiny change in the distribution. Just as the derivative measures the rate of change of $f(x)$, the IF measures the rate of change of the estimator $T(P)$ w.r.t. small perturbations in $P$.

### Deriving IF from an Estimating Equation

To compute the IF, we assume that the parameter $\theta = T(P)$ is defined through an estimating equation
$$\mathbb{E}\_P\bigl[\psi(z;\theta)\bigr] = 0,$$
where $\psi(z;\theta)$ is the *score function* (or estimating function) that defines the relation between the data and the parameter. For a maximum-likelihood estimator, $\psi(z;\theta) = \nabla\_{\theta} \log p(z;\theta)$; for an M-estimator minimizing a loss $L$, $\psi(z;\theta) = \nabla\_{\theta} L(z;\theta)$.

When the data distribution is perturbed, the estimating equation becomes
\begin{equation}
    \mathbb{E}\_{P\_{\epsilon}}\bigl[\psi(z;\theta\_{\epsilon})\bigr] = 0.
\end{equation}

Expanding the expectation under the contamination model gives
$$(1-\epsilon)\,\mathbb{E}\_P\bigl[\psi(z;\theta\_{\epsilon})\bigr] + \epsilon\,\psi(z\_i;\theta\_{\epsilon}) = 0.$$

We Taylor-expand $\psi$ around the unperturbed solution $\theta$:
$$\psi(z;\theta\_{\epsilon}) \;\approx\; \psi(z;\theta) + \frac{\partial \psi(z;\theta)}{\partial \theta}\,(\theta\_{\epsilon} - \theta).$$

Substituting and using $\mathbb{E}\_P[\psi(z;\theta)] = 0$, while dropping terms of order $O(\epsilon\,(\theta\_{\epsilon}-\theta))$ and higher, yields
$$\mathbb{E}\_P\!\left[\frac{\partial \psi(z;\theta)}{\partial \theta}\right](\theta\_{\epsilon} - \theta) + \epsilon\,\psi(z\_i;\theta) \;\approx\; 0,$$
so that
\begin{equation}
    \theta\_{\epsilon} - \theta \;\approx\; -\,\epsilon \left(\mathbb{E}\_P\!\left[\frac{\partial \psi(z;\theta)}{\partial \theta}\right]\right)^{-1} \psi(z\_i;\theta).
\end{equation}

Dividing by $\epsilon$ and letting $\epsilon \to 0$ recovers the classical influence function:
\begin{equation} \label{eq:if-classical}
    \textbf{IF}(z\_i;\,\theta,\,P) \;=\; -\left(\mathbb{E}\_P\!\left[\frac{\partial \psi(z;\theta)}{\partial \theta}\right]\right)^{-1}\!\psi(z\_i;\theta).
\end{equation}

The matrix $\mathbb{E}\_P[\partial\psi/\partial\theta]$ is the population analogue of the Hessian of the loss; for a maximum-likelihood estimator it equals the negative Fisher information. The IF therefore says: *the leading-order effect of contaminating the distribution at $z\_i$ is to push the estimator in the direction of the score $\psi(z\_i;\theta)$, pre-conditioned by the inverse curvature.*

### From Statistics to Empirical Risk Minimization

For a deep-learning model the objective is to minimize the empirical risk (ERM):
$$\hat{\theta} \;=\; \arg\min\_{\theta}\; \frac{1}{n}\sum\_{j=1}^{n} L(z\_j,\,\theta),$$
where $\hat{\theta}$ is the optimum, $z\_j = (x\_j, y\_j)$ is a training sample, and $L(\cdot)$ is the loss function. Since $\hat{\theta}$ is the optimum, the first-order optimality condition gives
\begin{equation}
    \nabla\_{\theta}\,\hat{\mathcal{R}}(\hat{\theta}) \;=\; \frac{1}{n}\sum\_{j=1}^{n} \nabla\_{\theta} L(z\_j,\,\hat{\theta}) \;=\; 0.
\end{equation}

The research question is: *how would the model's parameters (and therefore its predictions) change if we slightly up-weighted a single training sample $z\_i$?* To answer this, define the perturbed empirical risk
$$\hat{\theta}\_{\epsilon,\,z\_i} \;=\; \arg\min\_{\theta}\; \frac{1}{n}\sum\_{j=1}^{n} L(z\_j,\,\theta) \;+\; \epsilon\,L(z\_i,\,\theta).$$

Setting $\epsilon = -\tfrac{1}{n}$ corresponds to *removing* $z\_i$ from the training set, while $\epsilon = +\tfrac{1}{n}$ corresponds to duplicating it; for arbitrary small $\epsilon$ we obtain a continuous family of perturbed minimizers.

The first-order optimality condition for the perturbed problem reads
$$\frac{1}{n}\sum\_{j=1}^{n}\nabla\_{\theta} L(z\_j,\,\hat{\theta}\_{\epsilon,\,z\_i}) \;+\; \epsilon\,\nabla\_{\theta} L(z\_i,\,\hat{\theta}\_{\epsilon,\,z\_i}) \;=\; 0.$$

Expanding the gradient around $\hat{\theta}$ to first order in $(\hat{\theta}\_{\epsilon,\,z\_i} - \hat{\theta})$, using the unperturbed optimality condition, and dropping $O(\epsilon^{2})$ terms gives
$$\mathbf{H}\,(\hat{\theta}\_{\epsilon,\,z\_i} - \hat{\theta}) \;+\; \epsilon\,\nabla\_{\theta} L(z\_i,\,\hat{\theta}) \;\approx\; 0,$$
where
$$\mathbf{H} \;=\; \frac{1}{n}\sum\_{j=1}^{n} \nabla^{2}\_{\theta} L(z\_j,\,\hat{\theta})$$
is the Hessian of the empirical risk at $\hat{\theta}$ (assumed positive-definite).

### The Two Key Influence Quantities

Solving for the parameter change and dividing by $\epsilon$ yields the **influence on parameters**:
\begin{equation} \label{eq:if-up-params}
    \textbf{IF}\_{\text{up,\,params}}(z\_i) \;\equiv\; \left.\frac{d\hat{\theta}\_{\epsilon,\,z\_i}}{d\epsilon}\right|\_{\epsilon=0} \;=\; -\,\mathbf{H}^{-1}\,\nabla\_{\theta} L(z\_i,\,\hat{\theta}).
\end{equation}

In particular, the leave-one-out estimate of removing $z\_i$ is
$$\hat{\theta}\_{-z\_i} \;-\; \hat{\theta} \;\approx\; -\,\frac{1}{n}\,\textbf{IF}\_{\text{up,\,params}}(z\_i) \;=\; \frac{1}{n}\,\mathbf{H}^{-1}\,\nabla\_{\theta} L(z\_i,\,\hat{\theta}),$$
which lets us *predict* the effect of retraining without $z\_i$ at the cost of one Hessian-vector solve, instead of running a second training job.

By the chain rule, the change in the loss at a *test point* $z\_{\text{test}}$ when training point $z\_i$ is up-weighted is the **influence on loss**:
\begin{equation} \label{eq:if-up-loss}
    \textbf{IF}\_{\text{up,\,loss}}(z\_i,\,z\_{\text{test}}) \;=\; \left.\frac{d\,L(z\_{\text{test}},\,\hat{\theta}\_{\epsilon,\,z\_i})}{d\epsilon}\right|\_{\epsilon=0} \;=\; -\,\nabla\_{\theta} L(z\_{\text{test}},\,\hat{\theta})^{\top}\,\mathbf{H}^{-1}\,\nabla\_{\theta} L(z\_i,\,\hat{\theta}).
\end{equation}

This single scalar — a quadratic form between the test-loss gradient, the inverse Hessian, and the training-loss gradient — is the centerpiece of {{< cite "koh2017understanding" >}}. A *negative* value indicates that up-weighting $z\_i$ would *decrease* the test loss (i.e. $z\_i$ is helpful for predicting $z\_{\text{test}}$), while a *positive* value indicates a harmful training point.

A closely related quantity considers *perturbing the features* of $z\_i = (x\_i, y\_i)$ to $(x\_i + \delta, y\_i)$ rather than re-weighting it. A first-order analysis yields
$$\textbf{IF}\_{\text{pert,\,loss}}(z\_i,\,z\_{\text{test}}) \;=\; -\,\nabla\_{\theta} L(z\_{\text{test}},\,\hat{\theta})^{\top}\,\mathbf{H}^{-1}\,\nabla\_{x}\nabla\_{\theta} L(z\_i,\,\hat{\theta}),$$
which is the basis of the *training-set attack* construction in Koh & Liang.

### From Single Points to Groups

The framework extends linearly: the influence of a *group* $\mathcal{G} \subseteq \{1,\dots,n\}$ is, to first order,
$$\textbf{IF}\_{\text{up,\,loss}}(\mathcal{G},\,z\_{\text{test}}) \;\approx\; \sum\_{i \in \mathcal{G}} \textbf{IF}\_{\text{up,\,loss}}(z\_i,\,z\_{\text{test}}).$$
This additivity is exact only at first order; for large or correlated groups the linear estimate can drift substantially from the true leave-group-out behavior, and the deviation itself is sometimes informative (e.g. when uncovering coalitions of mislabeled examples).

## Practical Computation

The naïve cost of $\textbf{IF}\_{\text{up,\,loss}}$ is dominated by forming and inverting $\mathbf{H} \in \mathbb{R}^{p \times p}$, which is $O(np^{2} + p^{3})$ — hopeless for modern networks where $p$ runs into the millions or billions. Two observations make the computation tractable:

1. **We never need $\mathbf{H}^{-1}$ explicitly — only the inverse-Hessian–vector product (iHVP) $\mathbf{s} = \mathbf{H}^{-1}\,\nabla\_{\theta} L(z\_{\text{test}},\,\hat{\theta})$.** Once $\mathbf{s}$ is computed, the influence of *every* training point is just an inner product $-\mathbf{s}^{\top}\nabla\_{\theta} L(z\_i,\,\hat{\theta})$.
2. **Hessian-vector products $\mathbf{H}\mathbf{v}$ can be computed in roughly the cost of one backward pass**, using the Pearlmutter trick: $\mathbf{H}\mathbf{v} = \nabla\_{\theta}\bigl(\nabla\_{\theta} L \cdot \mathbf{v}\bigr)$ where $\mathbf{v}$ is treated as a constant during the outer gradient.

Two iterative iHVP solvers dominate practice:

- **Conjugate Gradient (CG):** solves $\mathbf{H}\mathbf{s} = \nabla\_{\theta} L(z\_{\text{test}})$ via repeated HVPs. Convergence depends on the conditioning of $\mathbf{H}$, and for non-convex losses one typically adds a damping term $\mathbf{H} + \lambda \mathbf{I}$ to keep the system positive-definite.
- **Stochastic Neumann series (LiSSA-style):** uses the identity $\mathbf{H}^{-1} = \sum\_{k=0}^{\infty}(\mathbf{I} - \mathbf{H})^{k}$ (valid when $\|\mathbf{H}\| \le 1$, which can be enforced by scaling) and truncates after a few hundred recursive HVPs estimated on mini-batches. This is the variant used in Koh & Liang's experiments for ImageNet-scale models.

For very large models (e.g. modern transformers) even iHVPs are expensive, and recent work has explored block-diagonal or Kronecker-factored approximations of the Hessian, as well as decompositions that share work across many test points. The general pattern is the same: precompute a single iHVP per query and amortize the inner product across the training set.

## Why the Theory Bends in Deep Learning

The derivation of $\textbf{IF}\_{\text{up,\,loss}}$ relies on three assumptions that are never exactly satisfied for modern neural networks:

1. **Strict convexity of the empirical risk** — required so that $\mathbf{H}$ is positive-definite and the implicit-function step is valid. Deep networks are highly non-convex; in practice one adds damping $\lambda$ or restricts the analysis to the final layer (where the loss is usually convex).
2. **$\hat{\theta}$ is a true minimizer** — the first-order condition $\nabla\hat{\mathcal{R}}(\hat{\theta}) = 0$ is used in the Taylor expansion. Neural-network checkpoints are early-stopped and only approximately stationary, which introduces a non-trivial residual.
3. **Linearity in $\epsilon$** — the influence is a *first-order* approximation, accurate when the perturbation is small. Large groups, mislabeled points, or training points whose removal qualitatively changes the loss landscape (e.g. samples near a decision boundary in an under-parameterized region) can violate this assumption.

Empirically, the influence-function estimate of the leave-one-out retraining effect can be noisy for deep non-convex models, especially when measured as a Pearson correlation against ground-truth retraining. Despite this, the *ranking* of training points by influence remains useful for many downstream tasks: identifying mislabeled examples, surfacing memorization, attacking and defending against poisoning, and explaining individual predictions in terms of supportive vs. opposing training data.

## Beyond Attribution: Influence as a Training Signal

The framework above is *diagnostic* — we train a model, then ask which samples mattered. A complementary line of work *folds influence back into training itself*, using the scalar $\textbf{IF}\_{\text{up,\,loss}}$ as a data-importance weight. A recent example is **KD-AIF** (Knowledge Distillation with Adapted Weight) by Wu et al. {{< cite "wu2025knowledge" >}}, published in *Statistics* (2025), which targets the question *which teacher-labeled examples should a student trust most?* in the knowledge-distillation setting.

The setup is familiar: a large teacher produces soft labels on a (possibly unlabeled) corpus, and a smaller student is trained to match them. The usual distillation loss treats every teacher-labeled example uniformly, even though some are mislabeled, near a decision boundary, or genuinely uninformative for the student. KD-AIF replaces the uniform weighting by an influence-derived coefficient: compute $\textbf{IF}\_{\text{up,\,loss}}(z\_i,\,z\_{\text{val}})$ for each (teacher-labeled) training point against a small clean validation set, then up-weight training points whose influence is most beneficial and down-weight (or drop) harmful ones. The influence scores are re-estimated periodically so the weighting tracks the student's evolving loss landscape.

Two things are notable about this recipe:

- **It closes the loop from interpretability to optimization.** The same quantity that Koh & Liang used to *explain* predictions is used here to *steer* learning — arguably the most useful thing an attribution signal can do.
- **It reframes the "four principles" (sustainability, accuracy, fairness, explainability) in concrete terms.** Down-weighting influential-but-harmful samples is simultaneously a regularizer (accuracy), a mechanism for surfacing group disparities (fairness), an auditable record of *why* a student disagrees with a teacher (explainability), and a way to compress knowledge into smaller models (sustainability). Empirically, Wu et al. report gains over vanilla distillation on CIFAR-100, CIFAR-10-4k, SVHN-1k, and GLUE, with the strongest lift in the semi-supervised regime where label noise is highest.

This "influence-as-training-signal" pattern is likely to generalize well beyond distillation — RLHF reward-model training, synthetic-data curation for LLM pre-training, and active learning are all settings where a per-sample importance score with calculus-level justification is more principled than the heuristic curricula in common use today. The open problem is computational: for a billion-parameter student one cannot afford Koh-Liang-style iHVPs per example per epoch, and scalable surrogates (last-layer approximations, EK-FAC, TRAK-style projected gradients) are an active area of research.

## Closing Thoughts

The influence function turns the question *"why did the model predict $\hat{y}$ on $x\_{\text{test}}$?"* into a calculus problem on the empirical-risk landscape. It replaces the impossibly expensive counterfactual — *retrain the model without each training point* — with a single inverse-Hessian–vector product followed by cheap inner products. It is one of the few interpretability tools with a clean, derivation-first connection to the classical statistical theory of robustness, and it scales (with care) to modern deep models. Its failure modes — non-convexity, sub-optimality of $\hat{\theta}$, and the linearity of the first-order expansion — are also the entry points for the next generation of attribution methods.

## Reference

{{< references >}}
