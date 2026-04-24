---
title: "🧠 Four Axes of LLM Mechanistic Interpretability"
date: 2026-04-23T00:18:00+00:00
draft: false
math: true
comment: true
tags: ['Artificial Intelligence', 'XAI', 'interpretability', 'mechanistic interpretability', 'LLM']
series: ['XAI']
bibFile: /content/post/scientia/machine-learning/bib.json
---

## TL;DR

* Mechanistic interpretability of transformers has matured along three axes: **states** (Logit / Tuned Lens, probing), **causality** (activation patching, ACDC, feature circuits), and **contrastive states** (RepE, CAA, steering vectors). Most interpretability blogs cover the first three.
* A fourth lineage exists in the dynamical-systems community, e.g., block-Jacobian spectra, mean-field / Vlasov limits, phase portraits, Langevin / Fokker–Planck fits, Koopman / DMD, and Liang–Kleeman information flow. This lineage studies the residual stream **unconditionally**, i.e., as background structure, not under task contrasts.
* The missing fourth axis is **differential transition operators**, i.e., how the layer-$\ell$ update map $f\_\ell$ changes between two task conditions. Object from Axis 4. Framing from Axes 2 and 3. Nobody has bridged them.
* There is no unified pathway-share metric, i.e., one number per layer comparable across tasks and scales that says how much work goes through attention vs MLP. Such a metric lives on the transition $f\_\ell$, not on the state $h\_\ell$.
* Audience: someone who has read the IOI paper and Logit Lens, but not the dynamics literature.

## Before

Most interpretability blog posts walk through methods in chronological order, e.g., Logit Lens first, then activation patching, then ACDC, then sparse autoencoders, then steering vectors. After reading them you know what each method is called, but you don't really know what question each method is trying to answer. The literature is small enough that the methods recombine, and the chronological reading flattens the actual structure.

A more useful organization is by **target**, i.e., which aspect of the model does each generation of methods try to explain. Once organized this way, the existing eras line up onto three axes (states, causality, dynamics), and a fourth axis (differential transition operators) is sitting in plain sight. The reason it is sitting in plain sight is that the interpretability crowd and the dynamical-systems crowd do not really read each other's papers.

This post is for someone who has read the IOI paper {{< cite "wang2023ioi" >}} and skimmed Logit Lens, but has never heard of Koopman operators or Fokker–Planck. The first three axes are a fast recap. The fourth one is the dynamics literature, plus the gap that I want to highlight.

## States

The oldest interpretability tradition for transformers is **state readout**. Take the hidden activation at intermediate layer $\ell$, project it back into vocabulary space, and read off what the model "thinks" it is going to say at that depth. nostalgebraist's [Logit Lens post on LessWrong (2020)](https://www.lesswrong.com/posts/AcKRB8wDpdaN6v6ru/interpreting-gpt-the-logit-lens) is the canonical version: apply the unembedding matrix $W\_U$ directly to the residual stream $h\_\ell$, and look at the top-k tokens of $\text{softmax}(W\_U h\_\ell)$. The result is informative: by mid-depth the residual stream's top tokens already concentrate on plausible continuations.

The problem is that Logit Lens implicitly assumes the basis at every layer is the same basis the unembedding was trained on, which is only approximately true. **Tuned Lens** {{< cite "belrose2023tunedlens" >}} fixes this with a small affine probe $A\_\ell$ trained per layer, such that $\text{softmax}(W\_U A\_\ell h\_\ell)$ matches the final-layer distribution. The lens becomes calibrated rather than naive.

![Fig. 2 — Logit Lens vs Tuned Lens.](/images/scientia/mi-logit-vs-tuned-lens.svg) Linear probing is the same family of idea pushed further: train a small classifier on top of $h\_\ell$ to recover any property you care about, e.g., sentiment, syntax, factual recall, position, or the answer to a multiple-choice question, and ask at which depth the property becomes linearly decodable.

These methods answer one question well: what does the model represent, and where in the stack? They do not answer a second question: how is that representation built? A linear probe at layer 12 tells you that subject information is there. It does not tell you which earlier layers wrote it, or how stable the encoding is.

## Causality

The intervention era is the response to the gap above. The unifying move is **counterfactual ablation**: run the model on a clean prompt $x$, run it again on a corrupted prompt $x'$ that differs in one feature, then patch some component (e.g., a head's output, an MLP block, a single residual position) from one run into the other and see if the prediction follows the patch. If patching head $\ell.h$ from the clean run into the corrupted run recovers the clean prediction, that head is causally responsible for the behavior.

Activation patching gives per-component effect sizes. **Attribution patching** linearizes the patch with a first-order gradient approximation, such that you do not need to rerun the model once per intervention. **ACDC** (Automated Circuit DisCovery) {{< cite "conmy2023acdc" >}} automates the next step: greedily prune the model's computation graph until only the components whose removal hurts the metric remain, and report the resulting sparse subgraph as a "circuit". Feature circuits push the same idea down to SAE features rather than whole heads or MLPs.

The intervention era is what lets us make claims like "this head copies the indirect object" or "this MLP stores the capital-of-country fact". It is the most causally honest axis we have. The cost is twofold: (a) every claim is per-task, i.e., one circuit per behavior, and the search is expensive per hypothesis; and (b) the output is a graph of components, not a description of the transition connecting them. Patching tells you head 9.6 matters for IOI. It does not give you an operator that maps "subject is in residual stream" to "indirect object will be next token".

## Contrastive States

The third axis takes a more pragmatic stance. Instead of asking which components compute a behavior, it asks: does the activation difference between behaviors live in a low-dimensional subspace, and can we move along that subspace to control the behavior?

The recipe is the same across this whole literature. Collect activations on contrastive prompt pairs, e.g., "happy" vs "sad", "truthful" vs "deceptive", or "refuses" vs "complies". Take the mean activation difference $\Delta h\_\ell = \mathbb{E}[h\_\ell \mid +] - \mathbb{E}[h\_\ell \mid -]$. Use that vector as both an analysis object (a direction in activation space tagged with semantic meaning) and a manipulation handle (add or subtract a scaled copy at inference time, and watch the behavior change). **Representation Engineering** {{< cite "zou2023repe" >}}{{< sidenote >}}A bit of a name collision with "representation learning". They are not the same thing, despite the vocabulary overlap.{{</ sidenote >}} formalizes this for high-level concepts like honesty and emotion. **Contrastive Activation Addition (CAA)** is the same idea localized to a single layer. The broader **steering-vector** literature treats it as a general control surface for safety-relevant behaviors.

This axis is appealing because it links state geometry to behavior with one cheap forward pass. The limitation is built in: it operates at the state level, not at the transition level. A steering vector tells you which direction in $\mathbb{R}^{d}$ correlates with the contrast. It does not tell you how the update map differs between the two conditions. If two behaviors share the same mean shift but differ in how the residual stream evolves around that shift, e.g., different curvature, different mixing rates, or different attention routing, the steering vector cannot see it.

So Axes 1 and 3 both target **state**. Axis 1 asks what is decodable from the state. Axis 3 asks what direction in state-space shifts behavior. Axis 2 is the **causality** axis. None of the three speak to how the state moves.

## Dynamics: An Unread Lineage

The residual stream is a trajectory:

$$h\_{0} \to h\_{1} \to \dots \to h\_{L}, \quad h\_{\ell+1} = h\_{\ell} + f\_{\ell}(h\_{\ell}),$$

where $f\_{\ell}$ is whatever the $\ell$-th block computes (attention + MLP, with a residual bypass). This is a discrete-time dynamical system, and dynamical-systems people have a lot to say about discrete-time dynamical systems.

![Fig. 3 — Residual-stream trajectory and Fokker–Planck potential landscape.](/images/scientia/mi-residual-trajectory.svg) Five threads worth knowing about:

* **Block-Jacobian spectra.** Li and Papyan {{< cite "li2023residual" >}} compute the Jacobian of one transformer block, $J\_\ell = \partial h\_{\ell+1}/\partial h\_\ell$, and characterize its eigenvalue distribution across depth. They call the phenomenon *residual alignment*, i.e., the residual updates align with a shrinking set of singular directions as depth grows. Early layers behave like contraction, mid layers expand a few subspaces, late layers re-collapse onto a low-dimensional output manifold. This gives a depth-dependent operator picture rather than a state picture.

* **Mean-field / Vlasov limits.** Castin et al. take the infinite-token limit of self-attention and derive a continuity equation for the empirical distribution of token representations, such that the residual stream becomes a flow on a measure space. The transformer becomes a discretization of a particular partial differential equation. This is the cleanest theoretical entry point for asking "what does attention do to a distribution of tokens?"

* **Phase portraits.** Fernando and Guitchounts visualize forward dynamics as trajectories in low-dimensional projections of the residual stream, and look for fixed points, limit cycles, and saddle structure. The picture that emerges is depth as a slow flow toward attractor manifolds, which is qualitatively different from the "the model thinks at layer 12" mental image you get from probing.

* **Stochastic / Fokker–Planck fits.** Sarfati et al. fit a Langevin-type model
$$dh = -\nabla U(h)\,d\ell + \sigma\,dW\_\ell$$
to the residual-stream evolution, and recover an effective potential $U(h)$ whose minima correspond to high-confidence answers. The picture is: forward depth is **integration time**, i.e., each layer is one step of an SDE rather than an arbitrary computation; the residual stream **flows downhill on a potential landscape** $U(h)$; and the equilibrium distribution at any depth has the Boltzmann form $p(h) \propto e^{-U(h)/T}$, such that the model's softmax confidence corresponds to a temperature on the basins of $U$. The dual view is the Fokker–Planck equation
$$\partial\_\ell\,p(h, \ell) = \nabla \cdot \bigl(p\,\nabla U\bigr) + \tfrac{\sigma^{2}}{2}\nabla^{2} p,$$
which is the distributional view that Vlasov / mean-field analyses operate in. This is the only thread in the lineage that explicitly treats depth as integration time.

* **Operator-theoretic methods (Koopman, DMD).** Approaches in the spirit of ATO apply Dynamic Mode Decomposition to the layer-by-layer activations to extract a linear operator that best explains the (nonlinear) state evolution. The Koopman framing converts a nonlinear dynamical question into a linear spectral one, i.e., modes, frequencies, decay rates.

* **Information-theoretic flow (Liang–Kleeman).** The Liang–Kleeman framework quantifies the causal influence of one variable on another in a dynamical system, with units of bits per time step, and importantly does not conflate correlation with causation. Applied to the residual stream, it would say not just "head 9.6 matters" but "head 9.6 transmits $X$ bits per layer to position $i$ about feature $Y$". Almost nobody in the interpretability literature has done this at scale.

The important caveat is that this entire lineage studies **unconditional** dynamics. It characterizes the flow on average, in expectation over the data distribution, or as a property of the trained network independent of any task. It is background structure, not task-specific structure. The Jacobian spectrum of layer 9 is a property of the network. The IOI circuit is a property of the network under a particular task contrast. These are different objects, and so far they live in different papers, written by different communities.

## The Gap

![Fig. 1 — The four eras arranged by (object of study × task conditioning); the bottom-right cell is the gap.](/images/scientia/mi-four-axes-quadrant.svg)

Put the four eras side by side:

| Axis | Object of study | Granularity | Conditional on task? |
|---|---|---|---|
| 1. States (Logit / Tuned Lens, probes) | $h\_\ell$ | per layer | partly, probes are |
| 2. Causality (patching, ACDC, feature circuits) | components | per head/MLP | yes, one circuit per task |
| 3. Contrastive states (RepE, CAA, steering) | $\Delta h\_\ell$ | per layer/region | yes |
| 4. Dynamics (Jacobians, Koopman, Vlasov, L-K) | transition $f\_\ell$ | per layer | **no, unconditional** |

The diagonal entry is empty. There is no body of work that asks "how does the transition operator $f\_\ell$ change between two task conditions?" Axis 4 has the right object (the transition). Axes 2 and 3 have the right framing (contrastive, conditional). Nobody has explicitly put them together.

This combination, i.e., **differential transition operators**, would let you say things like:

> "Under the IOI task vs. its negative control, the layer-9 transition operator gains a rank-2 component that routes from position 7 to the residual at position 11, with information flow of $X$ bits per layer."

This is a statement about how the computation differs between two conditions, not about which components fire (Axis 2), what direction the state shifts (Axis 3), or how the network flows on average (Axis 4). It is a fourth axis.

The toolbox already supports it. Block-Jacobian spectra trivially differ across conditions, you just have to compute them under a contrast pair. Koopman / DMD on residual streams admits a natural decomposition into condition-specific modes. Liang–Kleeman is defined contrastively. The ingredients are sitting on the shelf.

## Attention vs MLP, and Scale

A natural objection: "but the IOI circuit is almost entirely attention heads, so why bother with transition operators when components already explain the behavior?"

IOI is GPT-2 small, i.e., 117M parameters and 12 layers, with a task picked specifically because it has a clean attention-routing structure. The folklore that

> attention = routing/copying/induction, and MLP = key–value memory

is a useful heuristic at that scale, but it starts to break down before 1B parameters. Gated-FFN and MoE architectures push MLPs into routing-like behavior. Attention picks up more pure memorization, especially in long-context retrieval. The cleanly separable "pathway-share" you can compute on GPT-2 small becomes much fuzzier as the model grows.

What we do not have today is a unified pathway-share metric, i.e., one number per layer comparable across tasks and across model scales that says "of the work done at this layer, $\alpha$ went through attention and $1-\alpha$ through the MLP". Such a metric is naturally a **transition** quantity, not a **state** quantity. It lives on $f\_\ell$, not on $h\_\ell$. The missing fourth axis is missing for an operational reason, not just a taxonomical one.

## Closing

If you have spent your time reading the canonical interpretability blogs (Logit Lens, IOI, ACDC, the SAE papers, the steering-vector posts), your mental model of the field is probably organized by method. A more useful organization is by what the method tries to explain: states, causality, contrastive states, or transitions. The first three are mature. The fourth (dynamics) has a deep, careful, mostly-unread literature attached to it, but that literature studies the network unconditionally, which is exactly the thing interpretability does not need.

The next interpretability tool worth building, in my opinion, is a Koopman-style (or Jacobian-spectrum, or Liang–Kleeman) analysis run **contrastively** across two task conditions, and reported as a per-layer, per-pathway differential operator. The math is on the shelf.

## Further Reading (Community Posts)

A lot of useful mechanistic-interpretability material lives outside conventional venues, e.g., LessWrong, the Alignment Forum, Anthropic's transformer-circuits.pub, and Neel Nanda's blog. Some posts I keep coming back to:

* **nostalgebraist (2020), [*Interpreting GPT: the Logit Lens*](https://www.lesswrong.com/posts/AcKRB8wDpdaN6v6ru/interpreting-gpt-the-logit-lens).** The original Logit Lens post. Read this first if you have not. Most of Axis 1 is a refinement of the empirical observation made here.
* **[*SAE Training Dataset Influence in Feature Matching and a Hypothesis on Position Features*](https://www.lesswrong.com/posts/ATsvzF77ZsfWzyTak/dataset-sensitivity-in-feature-matching-and-a-hypothesis-on-1).** A reminder that which dataset you train your SAE on changes which features it discovers, i.e., SAE features are not a property of the model alone, but of the (model, dataset) pair. Worth reading because even "model-internal" objects are silently conditioned on data, which is the contrast / conditioning move I am pushing for in Axis 4.
* **Elhage et al., [*A Mathematical Framework for Transformer Circuits*](https://transformer-circuits.pub/2021/framework/index.html) (Anthropic, 2021).** The bilinear / rank decomposition that makes the QK-OV picture of attention legible. Most subsequent circuit papers borrow this scaffolding.
* **Olsson et al., [*In-context Learning and Induction Heads*](https://transformer-circuits.pub/2022/in-context-learning-and-induction-heads/index.html) (Anthropic, 2022).** The induction-head story. A worked example of "we found the mechanism" at small scale, and a useful baseline for asking when that picture stops working at larger scale.
* **Neel Nanda, [*A Comprehensive Mechanistic Interpretability Explainer & Glossary*](https://www.neelnanda.io/mechanistic-interpretability/glossary).** Probably the best entry point if you are landing in this field cold.
* **Neel Nanda, [*How To Become A Mechanistic Interpretability Researcher*](https://www.lesswrong.com/posts/jP9KDyMkchuv6tHwm/how-to-become-a-mechanistic-interpretability-researcher) (2025).** A staged curriculum and career guide rather than a technical post. If you are reading this blog because you want to *do* mech-interp and not just understand the literature, this is the practical companion piece, i.e., what to learn, in what order, how to find mentorship, how to ship work.

If you only have time for one of these, read nostalgebraist's Logit Lens post. Most of Axis 1 is downstream of it.

## Reference

{{< references >}}
