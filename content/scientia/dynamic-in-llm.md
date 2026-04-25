---
title: "🌀 Dynamics in LLM: Basins on the Second Time Axis"
date: 2026-04-24T00:18:00+00:00
draft: false
math: true
comment: true
tags: ['Artificial Intelligence', 'XAI', 'interpretability', 'dynamical systems', 'LLM']
series: ['XAI']
bibFile: /content/post/scientia/machine-learning/bib.json
---

## TL;DR

* Last post I argued the residual stream of a transformer is a dynamical system, with depth as time and basins of an effective potential $U(h)$ as high-confidence answers. That is **one** time axis.
* Three recent papers basically show there is a **second** time axis with the same kind of structure, i.e., what happens when the LLM eats its own output. Wang et al. {{< cite "wang2025attractor" >}} find that successive paraphrasing locks into a 2-period cycle. Perez et al. {{< cite "perez2025telephone" >}} find that telephone-game chains land on fixed-point attractors for properties such as toxicity, positivity, length. Carson {{< cite "carson2025severity" >}} goes one level up in formalism: model severity under iterated reasoning as an SDE, get a Fokker–Planck equation, find a phase transition between self-correcting and runaway regimes.
* Hunch: output-space attractors are basically shadows of residual-stream basins. Carson's iteration-axis Fokker–Planck is literally the same object as the depth-axis Fokker–Planck from last post — same PDE, different time variable — which turns the "shadow hunch" from wishful thinking into a formal parallel. I still do not have a proof that they are projections of the same operator, but the gap is now much narrower.
* Two clean theorems make the no-free-lunch part formal. **Bounded-state** systems (single-agent self-refine) hit a DPI wall — information about the answer strictly contracts. **Accumulating-history** systems (multi-agent debate, plan-execute-review, ecwu's Discussion Agent) hit the same wall from the other side — information is *conserved*, never grows. Same conclusion both ways: intrinsic iteration cannot beat first-sample Bayes risk against ground truth.
* The practical bite: agentic loops, synthetic-data pipelines, brainstorming with LLMs — all of them live inside the attractor, not inside the model. Throwing more iterations at a biased LLM does not explore more of text space, it just pulls you deeper into the basin.
* The missing move, same as last post: do any of this **contrastively** (two tasks, two languages, pre-vs-post fine-tuning). Nobody has run differential attractor analysis, and it is the obvious next step.

## Before

In the [previous post](/scientia/llm-mechanistic-interpretability/) I went through four eras of transformer interpretability and argued that the **dynamics** axis (block-Jacobian spectra, Koopman / DMD, Vlasov / Fokker–Planck, Liang–Kleeman flow) is the one most interpretability readers have not read. The picture out of that literature is: forward depth is integration time, the residual stream flows downhill on a potential $U(h)$, and the equilibrium distribution at any depth is Boltzmann, $p_{eq}(h) \propto e^{-U(h)/T}$. High-confidence answers are basin minima of $U$.

Fine. That is depth as time. But there is another, equally obvious time axis that almost nobody treats as a dynamical system, i.e., the **iteration** axis you get when you feed the model its own output back as input. Two papers in 2025, from very different communities, treat exactly this axis as a dynamical system and find attractors. I think they are worth stitching together, and back to the residual-stream picture.

## Two Time Axes, Not One

Forget the internals for a moment. Fix an LLM and a task prompt, define

$$P(T) \;=\; \mathrm{LLM}_\theta(\text{task},\, T),$$

and feed it back on itself:

$$T_0 \to T_1 \to T_2 \to \dots,\qquad T_{n+1} = P(T_n).$$

This is a discrete-time dynamical system on the text space $\mathcal{T}$, with exactly the same structural form as the depth recursion $h_{\ell+1} = h_\ell + f_\ell(h_\ell)$ from last post. The only thing that changed is what plays the role of state (text instead of $\mathbb{R}^d$) and what plays the role of the map ($P$ instead of $f_\ell$). Everything from the dynamics lineage — fixed points, limit cycles, Jacobian spectra, Koopman modes, potential landscapes — applies.

![Fig. 1 — Two time axes of an LLM as a discrete-time dynamical system: depth inside one forward pass, and iteration across successive generations.](/images/scientia/iterated-two-time-axes.svg)

Three concrete choices of $P$ recover the three papers. Wang's $P$ is a paraphrase function under a fixed prompt (same model, same task, fed back). Perez's $P$ is an agent in a transmission chain, with task $\in \{\text{rephrase, take inspiration, continue}\}$. Carson does not fix a specific $P$ but considers a scalar summary of the trajectory (severity $x \in [0,1]$) and takes the $\Delta t \to 0$ limit, so $P$ becomes an SDE rather than a discrete map.

## Wang & Perez 2025: Cycles in Text Space, Fixed Points in Property Space

Two papers from different communities, complementary observations of the same iteration-axis operator at different resolutions.

### Wang: paraphrase chains fall into 2-cycles

Take a sentence, paraphrase it, paraphrase the paraphrase, repeat 15 times. You would expect the trajectory to fan out, because paraphrasing has huge combinatorial freedom in principle. In practice it collapses into a **2-period cycle**, i.e., $T_i$ is textually very close to $T_{i-2}$, $T_{i-4}$, and so on, while $T_i$ and $T_{i-1}$ alternate between two structurally similar but distinct clusters.

Wang et al. {{< cite "wang2025attractor" >}} quantify this with a 2-periodicity degree

$$\tau \;=\; 1 - \frac{1}{M-2}\sum_{i=3}^{M} d(T_i,\,T_{i-2}),$$

where $d$ is normalized Levenshtein. Across Llama-3, Mistral, Qwen-2.5, GPT-4o in both English and Chinese, $\tau$ sits in $[0.60, 0.92]$.

The mechanism: paraphrasing is approximately **invertible** — a paraphrase preserves meaning, so you can in principle recover the original from the paraphrase. That constrains $P$ so $P^{-1}$ roughly exists, which forces trajectories to carry bidirectional predictability. Wang et al. confirm this by measuring *reverse perplexity* $\hat{\sigma}(T_i \mid T_{i+1})$, which also collapses as iteration proceeds. Bidirectional predictability on a discrete state space is exactly the footprint of a low-order periodic orbit — cycles are what invertible discrete maps tend to settle on.

Three findings push this past single-model artifact:

* **Cross-model.** A perplexity model (e.g., Llama-3-8B) applied to paraphrases *generated by a different LLM* still drops with iteration. The attractor is not confined to one model's parameter space. Multiple LLMs gravitate toward what looks like a shared statistical optimum.
* **Task general.** The 2-cycle shows up for every invertible task they try, i.e., polish, clarify, translate-and-back, informal-to-formal. It is the invertibility, not the specific task, that drives the cycle.
* **Hard to break.** Random prompt switching, alternating models, temperature 1.5, synonym-level perturbation — none of these break the 2-cycle. Only *structural* disruption (word swapping) or max-perplexity sample selection reduces $\tau$. History conditioning $T_{n+1} = \tilde{P}(T_n, T_{n-1})$ gives a 3-cycle, i.e., a bigger cycle rather than freedom.

The clean takeaway: **invertibility of the per-step transformation is enough to lock iterated LLM generation into a low-order cycle**, and escape requires breaking invertibility, not just adding noise.

### Perez: telephone games land on fixed-point attractors

Perez et al. {{< cite "perez2025telephone" >}} ask a cousin question. Run 50-step transmission chains with tasks rephrase / take inspiration / continue, starting from 20 different human-generated seed texts, across five LLMs. Do not look at the text directly, look at aggregate **properties**: toxicity, positivity, reading difficulty (Gunning–Fog), length.

They borrow the framing from *cultural attraction theory* (CAT): a cultural attractor is a content state that iterated transmission biases a chain toward, regardless of where it starts. Their estimation is simple, i.e., fit a linear recurrence

$$\text{prop}(T_{n+1}) \;=\; I + s \cdot \text{prop}(T_n),$$

which has a unique fixed point at $l = I/(1-s)$ whenever $|s| < 1$. Attractor position is $l$, attractor strength is $1 - |s|$ on a $[0, 1]$ scale.

Two results matter for us:

* **Task constraint controls strength.** Looser tasks have stronger attractors, i.e., *take inspiration* > *continue* > *rephrase*. Tighter tasks hold the output close to the input, so the model's internal bias has less room to pull.
* **Properties are not equal.** Toxicity has a much stronger attractor than length, across models and tasks. The iteration dynamics are not isotropic in property space — some directions contract much faster than others.

Fine-tuning shifts both the position $l$ and the strength $1-|s|$. Alignment does not remove the attractor; it relocates it.

### One operator, two observables

Wang sees the **full text trajectory** under an approximately invertible map and finds a 2-cycle. Perez sees a **scalar projection** under a non-invertible asymmetric contraction and finds a fixed point. They are not in tension; they are looking at the same iteration-axis operator at different observation resolutions, and the next section unpacks why these necessarily look different.

![Fig. 2 — Three archetypes of iterated attractors: a 2-period limit cycle in text space (Wang 2025), a fixed-point attractor in property space (Perez 2025), and a stochastic drift with phase transition in severity space (Carson 2025).](/images/scientia/iterated-attractor-archetypes.svg)

## Carson 2025: Severity as a Critical SDE

Carson {{< cite "carson2025severity" >}} does not stop at a linear recurrence. Take the same kind of scalar summary Perez uses — call it **severity** $x(t) \in [0, 1]$ (toxicity, bias level, whatever) — and take the $\Delta t \to 0$ limit under a near-Markov assumption. What you get is a stochastic differential equation

$$dx \;=\; \mu(x)\,dt + \sigma(x)\,dW_t,$$

with a parametric drift

$$\mu(x) \;=\; \underbrace{\alpha x(1-x)}_{\text{self-reinforcement}} \;-\; \underbrace{\beta x^2}_{\text{alignment damping}} \;+\; \underbrace{\gamma}_{\text{baseline}},$$

and a density $P(x,t)$ governed by the Fokker–Planck equation

$$\partial_t P \;=\; -\partial_x\!\bigl[\mu(x) P\bigr] \;+\; \tfrac{1}{2}\,\partial_x^2\!\bigl[\sigma^2(x) P\bigr].$$

Three things drop out of this once you have it written down.

* **Phase transition.** The ratio of $\alpha$ (self-reinforcement, logistic) to $\beta$ (alignment damping, quadratic) controls a critical transition. For $\alpha < \beta$ the stationary distribution $P_{\text{ss}}$ is unimodal near $x=0$ (subcritical, self-correcting). For $\alpha > \beta$ the distribution concentrates away from zero, and a runaway regime opens up. The critical threshold is $x_c = (\alpha - \beta)/(\alpha + \beta)$.
* **First-passage times.** With a harmful threshold $x_{\text{harm}} \in (0,1)$, the expected time to breach it satisfies a standard PDE in $\mu/\sigma^2$, so "how many reasoning steps before this chain goes toxic?" is a computable quantity rather than a hope.
* **Scaling laws near criticality.** Correlation length $\xi(\Delta)$ and relaxation time $\tau(\Delta)$ are predicted to diverge as $|\Delta|^{-\nu}$ and $|\Delta|^{-z\nu}$ near $\Delta = \alpha - \beta = 0$. These exponents are measurable from simulated or real CoT logs and give a non-trivial test of the framework.

The practical bite: alignment is not a binary. It moves $\alpha$ and $\beta$. You can be in the subcritical basin of parameter space where RLHF is enough to keep severity bounded, or in the supercritical basin where a long enough chain of thought will drift to $x \approx 1$ with probability one. Whether an agent is safe under iteration is a question about where its $(\alpha, \beta, \gamma)$ sits relative to a phase boundary.

## Cycles, Fixed Points, SDEs — Why Three Pictures?

The three papers look different on the surface (limit cycle, fixed point, stochastic drift) but the differences are explainable by what you observe and at what time resolution.

* Wang looks at the **full text**, where $P$ is approximately invertible, and invertibility on a discrete space tends to force periodic orbits, because an invertible map cannot contract onto a single point without losing the information needed to invert it.
* Perez looks at **scalar properties** under a linear approximation, and that map is *not* invertible (projection destroys information) and *not* symmetric. An asymmetric contraction on $\mathbb{R}$ has a unique fixed point, not a cycle.
* Carson looks at the **same kind of scalar** as Perez, but takes the continuous-time limit and keeps noise. That gives an SDE / Fokker–Planck picture where the Perez-style fixed point reappears as the peak of $P_{\text{ss}}(x)$, but now with a *parameter space* around it containing a phase transition, escape rates, and scaling exponents.

Stacked up, they are the same iteration-axis operator observed three ways: whole state with memory of direction (Wang), scalar projection in discrete time (Perez), scalar projection in continuous time with explicit noise (Carson). The specific attractor type — cycle, fixed point, bimodal stationary density — is determined by the projection and the time resolution, not by a disagreement between the papers. Iterated LLM generation lives on **low-dimensional attractor manifolds**; what you see depends on where you stand.

## Related Dynamical-Systems Framings

A few 2024–2025 papers fit the same operator-level picture from different angles and are worth reading as context, even though none of them bridges the depth axis and the iteration axis directly.

Zekri et al. {{< cite "zekri2024markov" >}} formalize a finite-context LLM as a finite-state Markov chain on the token-window space, derive TV-distance convergence rates to the stationary distribution under repeated sampling, and relate mixing time to the chain's spectral gap. This is the cleanest formal backbone for saying "iterated generation has a stationary distribution, and the rate of collapse onto it is governed by a contraction coefficient." Wang, Perez and Carson are all consistent with this; Perez's linear recurrence is a projection of it, Carson's SDE is its continuous-time limit.

Bertrand et al. {{< cite "bertrand2024stability" >}} give the same kind of analysis for iterated **training** rather than iterated inference. The iteration operator there is a different object (it maps distributions to new model weights via a training step), but structurally identical: fixed points in distribution space, stability conditions, phase transitions controlled by real-data weight. This is the missing third leg — there is an attractor structure on the *parameter* side of the recursion too, not just the output side.

What is still missing, as far as I can tell, is an operator linking these three pictures: (i) residual-stream Fokker–Planck at depth, (ii) iteration-axis Markov / SDE at inference, (iii) training-axis Wasserstein flow at retraining. The shadow hunch below is about (i) ↔ (ii); Bertrand is about (ii) ↔ (iii); nothing I have seen connects all three.

## Are These the Same Basins from Last Time?

Here is the connection I actually want to flag, i.e., the thing this blog exists to point out. I have no proof, just an argument at the level of a hunch, so please read it that way.

**Hunch.** *Under low-temperature decoding, iteration-axis attractors are shadows of residual-stream attractors.*

Sketch. Under greedy or low-temperature decoding, $P$ is approximately

$$P(T) \;\approx\; \arg\max_{T' \in \mathcal{T}} p_\theta(T' \mid T),$$

i.e., the argmax of the conditional distribution. A fixed point $T^{\ast}$ of $P$ satisfies $T^{\ast} = \arg\max_{T'} p_\theta(T' \mid T^{\ast})$, so $T^{\ast}$ is a mode of its own conditional distribution. Under the Fokker–Planck view from last post, modes of the output distribution correspond to basin minima of the effective potential $U(h)$ on the residual stream. If the map from input text to final-layer residual state is smooth enough (this is the assumption), output-space fixed points of $P$ are traces of residual-stream basin minima of $U$. Limit cycles are pairs of basin minima that route into each other under the full forward-pass operator.

Carson's paper makes this parallel uncomfortably literal. The depth-axis picture from last post is a Fokker–Planck equation for $p(h, \ell)$ with an effective potential $U(h)$. Carson's iteration-axis picture is a Fokker–Planck equation for $P(x, t)$ with an effective potential $V(x) = -\int \mu(x)\,dx$. Two axes, same PDE, same objects (drift, diffusion, stationary distribution, first-passage time). If the shadow hunch holds, there should be a projection $\pi: \mathcal{H} \to [0,1]$ (severity read-out from residual state) such that Carson's $(\mu, \sigma^2, V)$ is what you get by pushing the depth-axis $(U, T)$ forward through $\pi$ and composing across iterations. That is a concrete, checkable object, not a philosophical claim.

This is still heuristic. Temperature, beam search, padding, tokenization all break the clean argmax story, and the map from depth FP to iteration FP involves an integral over the full forward pass that nobody has written down. But the hunch now has a testable form on each axis:

* **Wang-style test.** The two clusters $T_{2n}$ vs $T_{2n+1}$ should sit in two different basins of $U(h)$ in the final-layer residual stream. Run Logit / Tuned Lens on those two clusters, look at the Jacobian spectrum of the last few blocks, do Koopman / DMD on the residual streams conditioned on cluster.
* **Carson-style test.** The severity drift $\mu(x)$ and diffusion $\sigma(x)$ fit to iterated CoT should be predictable from a residual-stream read-out of severity, not just measured post-hoc from text. If they do not line up, the axes are not projections of one operator and the hunch is wrong. If they do, you have a working bridge between interpretability and iteration safety.

Neither test has been run. Both are weeks of work, not months.

## The Missing Contrastive Piece

I will not rehash the whole argument from last post. Short version: the dynamics lineage (last post Axis 4) studies the residual stream **unconditionally**, i.e., as background. The missing piece is a *contrastive* analysis — how does the per-layer operator $f_\ell$ change between two task conditions?

Same gap on the iteration axis. Wang, Perez and Carson all vary conditions (models, tasks, languages, fine-tuning) and notice the attractor moves, but none of them estimates a **differential attractor** directly, i.e., $\Delta l = l_A - l_B$ between two conditions, or $\Delta \tau$ in 2-periodicity, or $\Delta \mu(x), \Delta \sigma(x)$ between two fine-tuned checkpoints in Carson's SDE, or a Koopman operator fitted under contrast. Perez is one regression away from doing it. Carson is one SDE fit per condition away. It is the same move I was asking for last post, just on the iteration axis instead of the depth axis.

## A One-Page Proof: Intrinsic Iteration Cannot Beat Bayes

The empirical result that intrinsic self-correction degrades reasoning ({{< cite "huang2024selfcorrect" >}}, {{< cite "kamoi2024selfcorrection" >}}) has not, as far as I can tell, been written down as a clean theorem. It is a one-page information-theoretic statement. Stating it makes precise what those papers are observing, and what loophole the rare positive results (e.g., {{< cite "madaan2023selfrefine" >}}) are exploiting.

A subtlety up front. The natural impulse is to write down a Markov chain $A^{\ast} \to T_n \to T_{n+1}$ and call data-processing inequality. That works for **bounded-state** systems, where each step overwrites the previous output (single-agent self-refine, verifier-rerank against $\theta$). It does **not** work for **accumulating-history** systems, where the kernel sees the full transcript on every step (multi-agent debate with shared scratchpad, plan-execute-review with logs, ecwu's Discussion Agent — see [DiscussionState](https://github.com/ecwu/python-sciread/blob/main/src/sciread/agent/discussion/models.py#L138), which is append-only across rounds). In the accumulating case, $A^{\ast} \to T_n \to T_{n+1}$ is not a Markov chain, because $T_{n+1}$ is generated from the full history $H_n = (T_0, \dots, T_n)$ and can leak information about $A^{\ast}$ via earlier rounds that $T_n$ alone does not summarize.

The two regimes need separate statements. The conclusion (no information-theoretic free lunch) is the same, but the mechanism is different — *contraction* in the bounded case, *conservation* in the accumulating case.

**Setup.** Fix a model $\theta$ and a query $q$. Let $A^{\ast}$ denote the correct answer, modeled as a random variable on the joint probability space of $(q, A^{\ast})$. The model defines an initial kernel $p_\theta(T_0 \mid q)$. We consider intrinsic iteration, by which I mean any kernel $K_\theta$ derived from $\theta$ alone — self-critique, "let me reconsider", verifier-rerank against the same model, multi-agent debate among copies of $\theta$, chain-of-thought ensembling, plan-execute-review. The defining property is that the kernel does not depend on $A^{\ast}$ except through observed text and $q$.

### Regime A — Bounded state (single-agent self-refine)

Each step overwrites: $T_{n+1} \sim K_\theta(\cdot \mid q,\, T_n)$. By construction $A^{\ast} \to T_n \to T_{n+1}$ is a Markov chain conditional on $q$, since $K_\theta$ depends on $A^{\ast}$ only through $T_n$.

**Theorem A (DPI).** *For every $n \ge 0$,*

$$I(A^{\ast};\, T_{n+1} \mid q) \;\le\; I(A^{\ast};\, T_n \mid q). \qquad (*)$$

*Consequently, for any loss $\ell(\cdot, A^{\ast})$,*

$$\inf_{\hat{A}}\, \mathbb{E}\!\left[\ell\bigl(\hat{A}(T_{n+1}), A^{\ast}\bigr)\right] \;\ge\; \inf_{\hat{A}}\, \mathbb{E}\!\left[\ell\bigl(\hat{A}(T_n), A^{\ast}\bigr)\right]. \qquad (\dagger)$$

**Proof.** $(\ast)$ is the data-processing inequality for conditional mutual information (Cover & Thomas, Thm. 2.8.1). For $(\dagger)$: any predictor $\hat{A}$ that is $\sigma(T_{n+1})$-measurable can be lifted to a $\sigma(T_n)$-measurable predictor $\tilde{A}(T_n) \mathrel{:=} \mathbb{E}[\hat{A}(T_{n+1}) \mid T_n, q]$ for convex $\ell$ (Jensen), or one with weakly smaller risk in general by measurable selection (Bertsekas–Shreve, Lemma 7.27). The infimum on the left is taken over a smaller class. $\square$

Reading: each refinement step weakly **destroys** information about the answer. Bayes risk grows monotonically.

### Regime B — Accumulating history (multi-agent debate, plan-execute-review)

Now $T_{n+1} \sim K_\theta(\cdot \mid q,\, H_n)$ where $H_n = (T_0, T_1, \dots, T_n)$. The chain $A^{\ast} \to T_n \to T_{n+1}$ is no longer Markov, but the chain $A^{\ast} \to H_n \to H_{n+1}$ is, trivially (append-only). Run the conditional independence on this state.

Since $K_\theta$ does not access $A^{\ast}$, we have $T_{n+1} \perp A^{\ast} \mid (H_n, q)$. The chain rule then gives

$$I(A^{\ast};\, H_{n+1} \mid q) \;=\; I(A^{\ast};\, H_n \mid q) + \underbrace{I(A^{\ast};\, T_{n+1} \mid H_n, q)}_{=\,0}.$$

**Theorem B (information conservation).** *For every $n \ge 0$,*

$$I(A^{\ast};\, H_n \mid q) \;=\; I(A^{\ast};\, T_0 \mid q). \qquad (\star)$$

*Consequently, for any loss $\ell$, the Bayes risk of recovering $A^{\ast}$ from $H_n$ equals the Bayes risk of recovering it from the initial sample $T_0$.*

The conclusion is structurally identical to Regime A — no intrinsic loop can beat the first sample's Bayes risk against ground truth — but the mechanism is the opposite. Information does not contract; it **never enters**. Each new round $T_{n+1}$ contributes zero new bits about $A^{\ast}$ beyond what $T_0$ already contained, because $K_\theta$ has no channel to $A^{\ast}$. The history can rearrange and re-encode existing bits; it cannot conjure new ones.

This rules out a tempting move: arguing that multi-agent debate "escapes DPI" because no information is being destroyed. It is correct that no information is being destroyed — the bound is equality, not strict decrease — but that is not an escape, that is the **same wall** seen from the other side. In Regime A you cannot do better because the bound contracts. In Regime B you cannot do better because the bound never starts growing.

### What both regimes share

**Reading.** Intrinsic iteration cannot extract more correctness signal about $A^{\ast}$ than was present in the first sample $T_0$. The Bayes-optimal predictor reading the entire transcript is no better than the Bayes-optimal predictor reading $T_0$ alone. There is no information-theoretic free lunch from looping a model against itself, regardless of whether you overwrite state or keep a scratchpad.

**Where the loophole sits, and why Self-Refine sometimes works.** Both theorems bound **Bayes** risk, not the user's actual extractor. If the user reads the transcript with a fixed naive readout — "take the last sentence", "extract the boxed number" — there is no contradiction in later rounds being easier to read for that readout than $T_0$. Iteration can move information from latent positions to surface positions without creating it. This is exactly the regime where Self-Refine reports gains: open-ended generation with format-fix critiques on strong frontier models. It is not the regime in which Huang and Kamoi found degradation: hard reasoning, where the user's extractor is already close to optimal and any randomness added by $K_\theta$ strictly hurts.

**A rate-explicit version applies only to Regime A.** $(\ast)$ is a $\le$ inequality and allows mutual information to stay constant. In practice, every empirical result in this post — Wang's 2-cycle, Perez's contraction, Carson's stationary distribution, the Markov-chain framing of {{< cite "zekri2024markov" >}} — predicts a stronger statement in the bounded-state setting: mutual information **contracts** at a geometric rate,

$$I(A^{\ast};\, T_{n+1} \mid q) \;\le\; e^{-\lambda} \cdot I(A^{\ast};\, T_n \mid q),$$

where $\lambda > 0$ is the kernel $K_\theta$'s log-Sobolev (or Poincaré) constant, controllable from the kernel's spectral gap and the Doeblin minorization implied by low-temperature decoding. That is the version worth proving carefully for Regime A. Regime B has no analogous contraction rate — there is nothing to contract — so a rate-explicit theorem there has to take a different form, e.g., bounding *how fast surface readouts approach the Bayes-optimal readout* of $T_0$, which is a different object and a different proof.

**Why this matters for agentic loops.** Self-refinement is Regime A. Multi-agent debate, plan-execute-review with shared logs, chain-of-thought ensembling with retained context, ecwu's Discussion Agent, are all Regime B. The two theorems jointly say: none of these architectures can extract more correctness signal than was already in $T_0$. Diversity, calibration, format, *legibility* of the answer can all change. Bayes risk against an external truth cannot. If you want to do better than the first sample, your kernel must touch something $\theta$ does not already encode — external retrieval, a stronger verifier, a tool call, a human in the loop. Anything else just walks the attractor, whether by contracting toward it (Regime A) or by accumulating transcripts inside it (Regime B).

## What This Means if You Are Actually Using LLMs

The theory is cute but the practical consequences are the reason I care about this at all. Each of the four buckets below has a stack of empirical papers already in place — the attractor framing, plus the two theorems above, are the missing *reason* for results the field has been seeing piecemeal.

* **Agentic loops.** If your agent calls an LLM in a loop (self-refinement, self-critique, plan-execute-review, multi-agent debate), you are sampling from the attractor, not from the model. The accessible state space is bounded by the attractor, not by the model's parameters. Huang et al. {{< cite "huang2024selfcorrect" >}} show intrinsic self-correction degrades reasoning accuracy across GSM8K / CommonsenseQA / HotpotQA once oracle-label leakage is removed; Kamoi et al. {{< cite "kamoi2024selfcorrection" >}} meta-analyze 60+ papers and conclude that pure self-critique is net-negative without external grounding; Wang et al. {{< cite "wang2024multiagent" >}} find a single well-prompted agent matches or beats multi-agent debate on most benchmarks, with debate converging via homogeneity rather than capability. All three read naturally as attractor-collapse observations and as instances of the Regime A / Regime B no-free-lunch wall. Wrapping a biased model in more iterations does not reduce bias, it amplifies whatever direction the attractor pulls toward. If you want real diversity, inject **structural** perturbation between steps, not just temperature or prompt variation.
* **Synthetic data and model collapse.** Training on LLM-generated text means training on samples drawn from the attractor, which has lower diversity than the underlying model. Shumailov et al. {{< cite "shumailov2024collapse" >}} show tails vanish before modes under recursive training; Bertrand et al. {{< cite "bertrand2024stability" >}} give a **fixed-point** analysis of iterative retraining where stability requires the real-data weight to exceed a critical ratio; Dohmatob et al. {{< cite "dohmatob2024tale" >}} derive the scaling-law change as a Wasserstein-space fixed point. Gerstgrasser et al. {{< cite "gerstgrasser2024accumulating" >}} complicate the pure-replacement picture: *accumulating* real and synthetic data keeps the error floor bounded. Max-perplexity sample selection (Wang et al.) is one cheap countermeasure. Stacking generations without escape, or without mixing in real data, is not safe.
* **Brainstorming.** "Ask the LLM for 20 ideas" gives you 20 samples from a narrow distribution, not 20 independent ideas. Padmakumar & He {{< cite "padmakumar2024diversity" >}} measure the drop directly: InstructGPT co-writing collapses lexical and semantic diversity vs. base GPT-3 or solo humans, with RLHF identified as the cause. Doshi & Hauser {{< cite "doshi2024creativity" >}} confirm this at the population level: AI assistance raises per-story novelty yet reduces corpus-level semantic diversity. Kirk et al. {{< cite "kirk2024rlhfdiversity" >}} show RLHF sharply reduces output-distribution entropy — the alignment-diversity trade-off has a name now. If you want diversity, pair the LLM with something external that forces structural divergence: retrieval from heterogeneous sources, ensemble across different models, human-in-the-loop seeding. Intrinsic diversity is not enough.
* **Alignment under iteration.** Perez shows fine-tuning moves the attractor; Carson sharpens this into a phase-transition picture where alignment reshapes $(\alpha, \beta, \gamma)$ and can push the system across a boundary between self-correcting and runaway regimes. RLHF does change where iterated generation lands. It does **not** flatten the attractor, and it breaks on iteration timescales. Russinovich et al. {{< cite "russinovich2024crescendo" >}} show benign multi-turn ramps (*Crescendo*) break RLHF safety on all frontier models; Anil et al. {{< cite "anil2024manyshot" >}} show many-shot in-context iteration erodes refusal probability as a power law in shot count; Qi et al. {{< cite "qi2025shallow" >}} show safety alignment lives in the first few output tokens and reverts toward the base-model attractor past that prefix; Wolf et al. {{< cite "wolf2024limitations" >}} prove any finitely-aligned model admits a bounded-length prompt restoring any base behavior. These are all attractor-displacement-not-removal observations. If you care about a safety property, evaluate it under iteration, not just single-turn — and if you can, estimate $\mu(x)$ and $\sigma(x)$ and ask on which side of criticality you are.

None of these recommendations need interpretability, they follow from the attractor observations and the two theorems alone. But the shadow hunch, if it holds, would give a mechanistic reason for *why* the attractor sits where it does, which is the thing alignment actually needs to reason about.

## A Practitioner Vignette

The framing above is academic, but builders independently surface the same operator. Two posts by ecwuuuuu — a [survey of single / ReAct / coordinated multi-agent designs](https://ecwuuuuu.com/post/agentic-academic-literature-understanding-1-cn/) and a [discussion-based extension](https://ecwuuuuu.com/post/agentic-academic-literature-understanding-1.5-cn/) for academic-paper understanding — name two failure modes that map cleanly onto the dynamics above.

* **"Error accumulation"** in long single-agent reasoning chains is what Carson's supercritical regime looks like from the application layer, i.e., $\alpha > \beta$, severity drifts to 1, and the longer you let the chain run the further off the rails it goes. Calling it compounding error rather than "wrong side of $x_c$" obscures that this is a phase-diagram fact, not a tooling fact.
* **"Acquiescence bias"** — an agent folding its position when challenged — is the Wang 2-cycle in moral-debate clothing. Two copies of $\theta$ playing critic and defender of an approximately invertible map land on a low-order limit cycle; ecwuuuuu's patches (require citations, label support / challenge / clarify, score confidence) are attempts at exactly the structural perturbation Wang found is the *only* class of intervention that breaks the cycle. Temperature and prompt variation do not.

The proposed Discussion Agent itself is a textbook Regime B kernel — four personas drawn from the same model, append-only `DiscussionState`, no external grounding by default — so Theorem B applies verbatim, i.e., it cannot reduce Bayes risk against ground truth, only reshape the surface readout. Where the design *does* break the bound is exactly at the loophole clauses, i.e., when "cite evidence" means evidence external to $\theta$ (the paper itself, retrieval) and when convergence is measured rather than enforced. The 0–1 convergence score is, unintentionally, a runtime estimate of Perez's attractor strength $1 - |s|$ — and, given Theorem B, a strictly weaker calibration check than measuring whether external evidence has actually entered the chain.

This is the contrastive analysis the rest of the post keeps asking for, in miniature. Builders are running ablations across (single, coordinated, debate, debate + retrieval) without naming the operator they are perturbing. The differential attractor framing is what makes those ablations comparable.

## Closing

LLMs are discrete-time dynamical systems along at least two time axes. Depth — studied mostly unconditionally by the dynamics literature. Iteration — just now being studied in a similar unconditional mode by Wang, Perez, and Carson. Both axes show basin structure. Both have the same missing piece: a contrastive analysis of how the operator changes between task conditions.

If the shadow hunch holds even loosely, these are two views of the same operator, and the open problems on one axis are the same open problems on the other. The math is on the shelf at both scales — Fokker–Planck for the geometry, Theorem A / B for the information accounting. I have not seen anyone actually bridge them yet.

## Reference

{{< references >}}
