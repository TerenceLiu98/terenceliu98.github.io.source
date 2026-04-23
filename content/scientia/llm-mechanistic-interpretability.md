---
title: "🧠 Four Eras of LLM Mechanistic Interpretability — and the Axis Nobody is Watching"
date: 2026-04-23T00:18:00+00:00
draft: false
math: true
comment: true
tags: ['Artificial Intelligence', 'XAI', 'interpretability', 'mechanistic interpretability', 'LLM']
series: ['XAI']
bibFile: /content/post/scientia/machine-learning/bib.json
---

## Before

Most interpretability blog posts walk the reader through a list of methods in roughly chronological order — Logit Lens first, then activation patching, then ACDC, then sparse autoencoders, then steering vectors. After reading them you know what each method is *called*, but you don't really know *what question each method commits to answering*. The literature is small enough that the methods recombine, and the chronological ordering flattens what is actually going on.

I think a much more useful organization is by **target**: which aspect of the model does each generation of methods promise to explain? Once you read the field this way, the existing eras line up onto three axes — **states, causality, dynamics** — and a fourth axis, **differential transition operators**, is sitting in plain sight, mostly because the people who would notice it (the interpretability crowd) and the people who already have the right tools (dynamical systems, optimal transport, information geometry) do not really read each other's papers.

This post is for someone who has read the IOI paper {{< cite "wang2023ioi" >}} and skimmed Logit Lens, but has never heard of Koopman operators or Fokker–Planck. The first three axes are a fast recap. The fourth one is where the most interesting unread literature lives, and where I think the next wave of mechanistic insight is going to come from.

## Axis 1 — States: what is linearly there, and at what depth?

The oldest interpretability tradition for transformers is **state readout**. Take the hidden activation at some intermediate layer $\ell$, project it back into vocabulary space, and read off what the model "thinks" it is going to say at that depth. nostalgebraist's Logit Lens is the canonical version: apply the unembedding matrix $W\_U$ directly to the residual stream $h\_\ell$, and look at the top-k tokens of $\text{softmax}(W\_U h\_\ell)$. The result is surprisingly informative — by mid-depth the residual stream's top tokens already concentrate on plausible continuations, which is itself a non-trivial fact about how the model builds answers.

The trouble is that Logit Lens implicitly assumes the basis at every layer is *the same* basis the unembedding was trained on. That is only approximately true. **Tuned Lens** {{< cite "belrose2023tunedlens" >}} fixes this with a small affine probe $A\_\ell$ trained per layer so that $\text{softmax}(W\_U A\_\ell h\_\ell)$ matches the final-layer distribution; the lens becomes calibrated rather than naive. Linear probing is the same family of idea pushed further: train a small classifier on top of $h\_\ell$ to recover any property you care about — sentiment, syntax, factual recall, position, the answer to a multiple-choice question — and ask at which depth the property becomes linearly decodable.

Together these methods answer one question well: **what does the model represent, and where in the stack?** They are silent on a second, harder question: **how is that representation built?** A linear probe at layer 12 tells you that subject information is there; it does not tell you which earlier layers wrote it, what computation produced it, or how stable the encoding is under perturbation.

## Axis 2 — Causality: which components are necessary?

The intervention era is the response to that gap. The unifying move is **counterfactual ablation**: run the model on a clean prompt $x$, run it again on a corrupted prompt $x'$ that differs in exactly one feature, then *patch* some component (a head's output, an MLP block, a single residual position) from one run into the other and see if the prediction follows the patch. If patching head $\ell.h$ from the clean run into the corrupted run recovers the clean prediction, that head is *causally responsible* for the behavior under study.

Activation patching gives you per-component effect sizes. **Attribution patching** linearizes the patch using a first-order gradient approximation, so that you do not need to actually rerun the model once per intervention — a huge speedup that turns a quadratic-cost search into a single backward pass. **ACDC** (Automated Circuit DisCovery) {{< cite "conmy2023acdc" >}} automates the obvious next step: greedily prune the model's computation graph until only the components whose removal hurts the metric remain, and report the resulting sparse subgraph as a "circuit." Feature circuits push the same idea down to SAE features rather than whole heads or MLPs.

The intervention era is what lets us actually make claims like *"this head copies the indirect object"* or *"this MLP stores the capital-of-country fact."* It is the most causally honest axis we have. The cost is twofold: (a) every claim is per-task — one circuit per behavior, and the search is expensive per hypothesis; and (b) the output is a *graph of components*, not a description of the *transition* connecting them. Patching tells you head 9.6 matters for IOI; it does not give you an operator that maps "subject is in residual stream" to "indirect object will be next token."

## Axis 3 — Contrastive representations: shifts as the manipulation handle

The third axis takes a more pragmatic stance. Instead of asking which components compute a behavior, it asks: **does the activation difference between behaviors live in a low-dimensional subspace, and can I move along that subspace to control the behavior?**

The recipe is the same across the whole literature. Collect activations on contrastive prompt pairs — *"happy" vs "sad", "truthful" vs "deceptive", "refuses" vs "complies"* — take the mean activation difference $\Delta h\_\ell = \mathbb{E}[h\_\ell \mid +] - \mathbb{E}[h\_\ell \mid -]$, and use that vector as both an **analysis object** (a direction in activation space tagged with semantic meaning) and a **manipulation handle** (add or subtract a scaled copy at inference time and watch the behavior change). **Representation Engineering** {{< cite "zou2023repe" >}}{{< sidenote >}}A bit of a name collision with "representation learning" — they are not the same thing, despite the vocabulary overlap.{{</ sidenote >}} formalizes this for high-level concepts like honesty and emotion; **Contrastive Activation Addition (CAA)** is the same idea localized to a single layer; the broader **steering-vector** literature treats it as a general control surface for safety-relevant behaviors.

This axis is appealing because it links **state geometry to behavior** with one cheap forward pass. But the limitation is built into the construction: it operates at the *state* level, not at the *transition* level. A steering vector tells you which direction in $\mathbb{R}^{d}$ correlates with the contrast; it does not tell you how the *update map* differs between the two conditions. If two behaviors share the same mean shift but differ in *how* the residual stream evolves around that shift — different curvature, different mixing rates, different attention routing — the steering vector simply cannot see it.

So Axes 1 and 3 really both belong to the same axis of interest: they target **state**. Axis 1 asks what is decodable from the state, Axis 3 asks what direction in state-space shifts behavior. Axis 2 is the **causality** axis. None of the three speak to *how the state moves*.

## Axis 4 — Dynamics: the literature interpretability never reads

This is where the post starts to earn its keep, because almost no interpretability blog mentions this lineage at all. The residual stream is, after all, a **trajectory**:

$$h\_{0} \to h\_{1} \to \dots \to h\_{L}, \quad h\_{\ell+1} = h\_{\ell} + f\_{\ell}(h\_{\ell}),$$

where $f\_{\ell}$ is whatever the $\ell$-th block computes (attention + MLP, with a residual bypass). That is a discrete-time dynamical system, and dynamical-systems people have a *lot* to say about discrete-time dynamical systems. There are at least five threads worth knowing about, none of them well-known to interpretability readers:

- **Block-Jacobian spectra.** Li et al. compute the Jacobian of one transformer block, $J\_\ell = \partial h\_{\ell+1}/\partial h\_\ell$, and characterize its eigenvalue distribution across depth. The spectrum shifts in a structured way: early layers behave like contraction, mid layers expand a few subspaces, late layers re-collapse onto a low-dimensional output manifold. This already gives you a depth-dependent **operator** picture rather than a state picture.

- **Mean-field / Vlasov limits.** Castin et al. take the infinite-token limit of self-attention and derive a continuity equation for the *empirical distribution* of token representations, treating the residual stream as a flow on a measure space. The transformer becomes a discretization of a particular partial differential equation. This is the cleanest theoretical entry point for asking "what does attention actually *do* to a distribution of tokens?"

- **Phase portraits.** Fernando and Guitchounts visualize forward dynamics as trajectories in low-dimensional projections of the residual stream, looking for fixed points, limit cycles, and saddle structure. The picture that emerges — depth as a slow flow toward attractor manifolds — is qualitatively different from the "the model thinks at layer 12" mental image you get from probing.

- **Stochastic / Fokker–Planck fits.** Sarfati et al. fit a Langevin-type model
$$dh = -\nabla U(h)\,d\ell + \sigma\,dW\_\ell$$
to the residual-stream evolution, recovering an effective potential $U(h)$ whose minima correspond to high-confidence answers. This is the only thread that explicitly treats forward depth as an **integration time**, with the corresponding free-energy / potential-landscape vocabulary that comes for free.

- **Operator-theoretic methods (Koopman, DMD).** Approaches in the spirit of ATO apply Dynamic Mode Decomposition to the layer-by-layer activations to extract a *linear* operator that best explains the (nonlinear) state evolution. The Koopman framing is powerful precisely because it converts a nonlinear dynamical question into a linear *spectral* one — modes, frequencies, decay rates — which is exactly the structure that interpretability is starving for.

- **Information-theoretic flow (Liang–Kleeman).** The Liang–Kleeman framework quantifies the *causal influence* of one variable on another in a dynamical system, with units of bits per time step, and importantly without conflating correlation with causation. Applied to the residual stream, it would say not just "head 9.6 matters" but "head 9.6 transmits $X$ bits per layer to position $i$ about feature $Y$." Almost nobody in the interpretability literature has actually done this at scale, which is itself notable.

The crucial caveat — and this is the thing most interpretability readers miss when they finally do read these papers — is that **this entire lineage studies *unconditional* dynamics**. It characterizes the flow on average, or in expectation over the data distribution, or as a property of the trained network independent of any task. It is **background structure**, not task-specific structure. The Jacobian spectrum of layer 9 is a property of the network; the IOI circuit is a property of the network *under a particular task contrast*. These are different objects, and so far they live in different papers, written by different communities.

## The Gap — Differential Transition Operators

Put the four eras side by side:

| Axis | Object of study | Granularity | Conditional on task? |
|---|---|---|---|
| 1. States (Logit / Tuned Lens, probes) | $h\_\ell$ | per layer | partly — probes are |
| 2. Causality (patching, ACDC, feature circuits) | components | per head/MLP | yes — one circuit per task |
| 3. Contrastive states (RepE, CAA, steering) | $\Delta h\_\ell$ | per layer/region | yes |
| 4. Dynamics (Jacobians, Koopman, Vlasov, L-K) | transition $f\_\ell$ | per layer | **no — unconditional** |

The diagonal entry is empty. There is no body of work that asks *"how does the transition operator $f\_\ell$ change between two task conditions?"* Axis 4 has the right object (the *transition*); Axes 2 and 3 have the right framing (*contrastive, conditional*). Nobody has explicitly put them together.

That combination — call it **differential transition operators** — would let you say things like:

> "Under the IOI task vs. its negative control, the layer-9 transition operator gains a rank-2 component that routes from position 7 to the residual at position 11, with information flow of $X$ bits per layer."

That is a statement about *how the computation differs* between two conditions, not about *which components fire* (Axis 2) or *what direction the state shifts* (Axis 3) or *how the network flows on average* (Axis 4). It is a fourth, genuinely new axis.

The striking thing is how much of the existing toolbox already supports this. Block-Jacobian spectra trivially differ across conditions; you just have to compute them under a contrast pair. Koopman/DMD on residual streams admit a natural decomposition into *condition-specific* modes. Liang–Kleeman is *defined* contrastively. The ingredients are sitting on the shelf. Almost nobody is mixing them.

## A Cross-cutting Sidebar: Attention vs MLP, and Why Scale Changes the Answer

A natural objection at this point is: *"but the IOI circuit is almost entirely attention heads, so why bother with transition operators when components already explain the behavior?"*

The reply is that IOI is GPT-2 small — 117M parameters, 12 layers, with a task picked specifically because it has a clean attention-routing structure. The folklore that

> **attention = routing/copying/induction,** and **MLP = key–value memory**

is a useful heuristic at that scale, but it starts to break down well before you reach 1B parameters: gated-FFN and MoE architectures push MLPs into routing-like behavior, attention picks up more pure memorization (especially in long-context retrieval), and the cleanly separable "pathway-share" you can compute on GPT-2 small becomes much fuzzier as the model grows.

What we do *not* have today is a unified pathway-share metric — one number per layer, comparable across tasks and across model scales, that says *"of the work done at this layer, $\alpha$ went through attention and $1-\alpha$ through the MLP."* That metric is naturally a **transition** quantity, not a **state** quantity: it lives on $f\_\ell$, not on $h\_\ell$. Which is another way of saying that the missing fourth axis is missing for a concrete and operational reason, not just a taxonomical one.

## Closing

If you have spent your time reading the canonical interpretability blogs — Logit Lens, IOI, ACDC, the SAE papers, the steering-vector posts — your mental model of the field is probably organized by *method*. I think the more useful organization is by *what the method commits to explaining*: states, causality, contrastive states, or transitions. The first three are mature. The fourth — dynamics — has a deep, careful, mostly-unread literature attached to it, but that literature studies the network *unconditionally*, which is exactly the thing that interpretability does not need.

If I had to place one bet on what the next genuinely interesting interpretability tool will look like, it would be a Koopman-style (or Jacobian-spectrum, or Liang–Kleeman) analysis run **contrastively** across two task conditions, and reported as a per-layer, per-pathway *differential* operator. The math is sitting on the shelf. The question is whether anyone will pick it up before the next round of "we patched some heads on a new task" papers.

## Reference

{{< references >}}
