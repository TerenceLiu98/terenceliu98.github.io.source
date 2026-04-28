---
title: "Literature Review: Information-Theoretic Limits of Intrinsic LLM Iteration"
date: 2026-04-25
draft: true
math: true
---

## 0. Scope

This review supports two candidate papers from the [Dynamics in LLM](/scientia/dynamic-in-llm/) blog:

- **Path 1 — Workshop / short paper.** Theorem A (DPI on bounded state) + Theorem B (information conservation on accumulating history) + a small empirical signature on a multi-agent system (e.g., ecwu's Discussion Agent on QASPER). Target: NeurIPS / ICLR workshops on Foundation Model Agents, Safe & Trustworthy LLMs, ICLR Tiny Papers.
- **Path 2 — Full conference paper.** Same theorems with rate-explicit refinements (log-Sobolev for Regime A, surface-readout-convergence for Regime B), a full empirical ablation (single / coordinated / debate / debate+RAG / heterogeneous-model debate × ≥2 model families × ≥2 reasoning benchmarks). Target: NeurIPS, ICLR, ACL/EMNLP main.

The question is whether either path has a defensible novelty after the literature published through April 2026. The short answer: **path 1 is viable, path 2 needs careful re-scoping**, with one specific competing preprint as the bar.

The rest of this review is organised by cluster.

## 1. Iteration-axis attractors (the empirical scaffolding)

### 1.1 Wang et al., ACL 2025 — *Unveiling Attractor Cycles in Large Language Models* ([arXiv:2502.15208](https://arxiv.org/abs/2502.15208))

Successive paraphrasing collapses into a 2-period limit cycle across Llama-3 / Mistral / Qwen-2.5 / GPT-4o, EN+ZH, with 2-periodicity score $\tau \in [0.60, 0.92]$. Drives the cycle to **invertibility** of the per-step map. Cross-model ($\theta_A$ producing texts that $\theta_B$ scores low-perplexity), task-general (any invertible task: polish, clarify, translate-back), hard to break (temperature, prompt switching, model alternation all fail; only structural perturbation or max-perplexity selection works).

**Status for our paper:** core empirical anchor for Wang-style cycle behavior. Doesn't propose any information-theoretic limit; pure phenomenology + invertibility argument.

### 1.2 Perez et al., ICLR 2025 — *When LLMs Play the Telephone Game* ([arXiv:2407.04503](https://arxiv.org/abs/2407.04503))

Telephone-game transmission chains across 5 LLMs × 3 tasks (rephrase / take inspiration / continue) × 20 seeds, 50 steps. Aggregate properties (toxicity, positivity, Gunning–Fog, length) follow a linear recurrence $\text{prop}(T_{n+1}) = I + s \cdot \text{prop}(T_n)$, with attractor position $l = I/(1-s)$ and strength $1-|s|$. Looser tasks → stronger attractor. Toxicity contracts faster than length. Fine-tuning **moves** $l$ and $1-|s|$, doesn't remove the attractor.

**Status:** the empirical anchor for Perez-style fixed-point behavior in property space. Their linear-recurrence fit gives us a directly computable runtime statistic (attractor strength) that we can measure on any multi-turn transcript. Importantly, no Bayes-risk analysis — Perez never asks "is the attractor closer to or further from the truth," only "where does it sit and how strongly does it pull."

### 1.3 Carson, preprint Jan 2025 — *A Stochastic Dynamical Theory of LLM Self-Adversariality* ([arXiv:2501.16783](https://arxiv.org/abs/2501.16783))

Continuous-time limit of severity drift: $dx = \mu(x) dt + \sigma(x) dW_t$ with $\mu(x) = \alpha x(1-x) - \beta x^2 + \gamma$. Fokker–Planck for $P(x, t)$. Phase transition at $\alpha = \beta$, critical exponent for correlation length $\xi(\Delta) \sim |\Delta|^{-\nu}$. First-passage time PDE for "how many steps until severity breaches a harmful threshold."

**Status:** the SDE / criticality framing for severity drift. Most relevant to the *shadow hunch* (Fokker–Planck on iteration axis ↔ Fokker–Planck on depth axis), less directly relevant to Theorem A/B. Doesn't prove an information-theoretic bound on Bayes risk.

### 1.4 Zekri et al., ICLR 2025 — *Large Language Models as Markov Chains* ([arXiv:2410.02724](https://arxiv.org/abs/2410.02724))

Formalizes a finite-context LLM as a Markov chain on the token-window state space (size $O(T^K)$ for vocab $T$, context $K$). Proves existence and uniqueness of stationary distribution. Derives TV-distance convergence rate to stationarity and relates mixing time to spectral gap. Shows higher temperature → faster mixing → less coherent output. Provides pre-training and ICL generalization bounds.

**Status:** the cleanest formal backbone for "iterated generation has a stationary distribution." Wang/Perez/Carson are all consistent with this; Perez's linear recurrence is a projection, Carson's SDE is a continuous-time limit. **Crucially:** Zekri's chain is the bounded-state $T_n \to T_{n+1}$ kernel (token-window state). Their analysis does **not** cover accumulating-history kernels where the state grows unboundedly — that gap is exactly Regime B.

### 1.5 *Safety Alignment Depth* Markov chain perspective ([arXiv:2502.00669](https://arxiv.org/abs/2502.00669))

Uses Zekri-style Markov chain framing to study how deep into output tokens safety alignment must reach. Identifies an "ensemble width vs alignment depth" trade-off. Permutation-based augmentation tightens bounds.

**Status:** specialised application of Markov-chain framing to alignment, doesn't directly compete with our scope.

### 1.6 Bertrand et al., ICLR 2024 — *On the Stability of Iterative Retraining* ([OpenReview](https://openreview.net/pdf?id=JORAfH2xFd))

Training-axis recursion (model retrained on its own outputs mixed with real data). Proves existence of a fixed point in distribution space + stability under conditions on real-data ratio. Phase transition controlled by mixing weight.

**Status:** parallel work on a *different* iteration operator — not output iteration but parameter iteration. Same structural language (fixed points, stability, phase transitions). Confirms that attractor-style framing extends to retraining loops. Outside our paper's scope but worth citing as the "third leg."

### 1.7 Shumailov et al., Nature 2024 — *AI Models Collapse When Trained on Recursively Generated Data* ([arXiv:2305.17493](https://arxiv.org/abs/2305.17493))

Empirical: tails vanish before modes under recursive training. Mostly cited together with Bertrand for the parameter-axis story.

**Cluster verdict.** This cluster is dense and well-developed. Wang/Perez/Carson cover phenomenology at three resolutions; Zekri provides the bounded-state Markov-chain backbone. **No paper in this cluster proves either of our theorems**, and no paper distinguishes bounded-state from accumulating-history kernels. They are the *empirical scaffolding* our paper cites, not competitors.

## 2. Information-theoretic bounds on LLM reasoning (the closest theoretical neighborhood)

### 2.1 Gan et al., ICML 2025 — *Rethinking External Slow-Thinking: From Snowball Errors to Probability of Correct Reasoning* ([OpenReview](https://openreview.net/forum?id=lAjj22UxZy), [arXiv:2501.15602](https://arxiv.org/abs/2501.15602))

The reference paper the user picked. Single-chain CoT with implicit thoughts $t_l$ and observed responses $r_l$. Information loss $H(t_l \mid r_l)$ accumulates: $H_{<l}(t \mid r) = \sum_i H(t_i \mid r_i)$. Their **Theorem 3.3** uses Fano's inequality:
$$P(e_l) \ge \log^{-1}(|\mathcal{T}_l| - 1)\bigl[H_{<l}(t \mid r)/(l-1) - H_b(e_l)\bigr].$$
Lower-bounds error probability per reasoning step. Empirical on GSM8k with Llama-3.1-8B-Instruct, Qwen2.5-7B-Instruct, Skywork-o1-Open-Llama-3.1-8B. Compares BoN vs MCTS upper bounds (Theorem 4.6 etc.). Concludes: *external slow-thinking effectiveness is determined by total reasoning cost, not framework specifics*.

**Status — most directly comparable theoretical paper.** State variables are single-chain implicit thoughts; their bound is on Bayes-risk *lower bound* via Fano (we use DPI for *upper bound* on info, dual). Their snowball framework is fundamentally about a single chain. They do not handle:
- multi-agent / accumulating history kernels (no cross-agent Markov structure);
- explicit conservation results (only contraction-like accumulation);
- the regime distinction.

**Differentiation strategy.** Gan and our work are complementary: Gan is the lower-bound on error ("how bad does it have to get") for a single chain; we give an upper-bound on extractable information ("how good can it get") for any intrinsic kernel including multi-agent. Both can coexist in the same paper space without one subsuming the other.

### 2.2 Arbuzov et al., May 2025 — *Beyond Exponential Decay: Rethinking Error Accumulation in LLMs* ([arXiv:2505.24187](https://arxiv.org/abs/2505.24187))

The other reference paper. Position / synthesis paper. Challenges $(1-e)^n$ via key-token sparsity (5–10%) + stratified manifold + self-consistency. Light formal content (a refined two-rate error model). Mostly synthesizes existing empirical work (Fang, Liu et al., Pang, Li & Sarwate, Wang, Yao, Costello).

**Status.** Position paper format; informative as a model for how this kind of synthesis can land on arXiv. **Not** a competitor for theorem space — they don't claim novel theorems. Useful as evidence that this neighborhood is being actively re-thought.

### 2.3 Ton et al., 2024 — *Understanding Chain-of-Thought in LLMs through Information Theory* ([arXiv:2411.11984](https://arxiv.org/abs/2411.11984))

CoT step-wise information gain quantified via mutual information. Contemporary with Gan; similar single-chain scope.

### 2.4 *L2M* — *Mutual Information Scaling Law for Long-Context Language Modeling* ([arXiv:2503.04725](https://arxiv.org/abs/2503.04725))

Bipartite MI scaling law in natural language; lower bound on history-state dimension for effective long-context modeling. About representation capacity, not iteration dynamics; orthogonal.

### 2.5 *Demystifying Reasoning Dynamics with Mutual Information* ([arXiv:2506.02867](https://arxiv.org/abs/2506.02867))

Tracks MI between intermediate representations and the correct answer during reasoning. Finds "thinking-token MI peaks." Empirical / mechanistic. Doesn't prove a Bayes-risk bound.

### 2.6 *Revisiting LLM Reasoning via Information Bottleneck* ([arXiv:2507.18391](https://arxiv.org/abs/2507.18391))

Information bottleneck framing for reasoning. Different objective (compression vs prediction trade-off) but similar information-theoretic vocabulary.

**Cluster verdict.** This cluster is dense, very recent (most papers post-2024), and converging on information-theoretic vocabulary for LLM reasoning. **The single-chain case is well-covered** (Gan, Ton, MI peaks, IB). **The multi-chain / accumulating-history case is not.** Gan is the closest theoretical neighbor; we are not redundant with him because his state is single-chain implicit thoughts and his bound is Fano-based on error probability, while ours is DPI-based on extractable information across multi-agent kernels.

## 3. Multi-agent debate — empirical critiques

### 3.1 Du et al., ICML 2024 — *Improving factuality and reasoning... with multiagent debate* ([dl.acm](https://dl.acm.org/doi/10.5555/3692070.3692537))

The original positive result for multi-agent debate. Reports gains over single-agent CoT on various benchmarks.

### 3.2 Smit et al., ICML 2024 — *Should we be going MAD? A Look at Multi-Agent Debate Strategies for LLMs* ([arXiv:2311.17371](https://arxiv.org/abs/2311.17371))

Comprehensive critical review. Multi-agent debate **does not reliably outperform self-consistency** with comparable compute. Multi-Persona variants do better with HP tuning, suggesting MAD is "more sensitive to HP than inherently better."

### 3.3 Wang et al., 2024 — *Are More LLM Calls All You Need?* and other "single agent matches multi-agent" papers

Recurring empirical finding: a single well-prompted agent matches or beats multi-agent debate on most benchmarks; debate converges via *homogeneity*, not capability. Cited in our blog.

### 3.4 *Can LLM Agents Really Debate?* ([arXiv:2511.07784](https://arxiv.org/abs/2511.07784))

Controlled study of MAD on logical reasoning. Adds to the body of negative / null results.

**Cluster verdict.** Strong consensus in 2024–2026 that *intrinsic* multi-agent debate (homogeneous personas) does not robustly outperform single-agent baselines under matched compute. Our theorems are the **explanation** for this consensus — but the empirical observation is already established. We need to be careful not to oversell empirical novelty; our pitch must be theoretical.

## 4. The closest competitors — DPI applied to multi-agent

This is the most strategically important cluster. Two papers in 2026 already use information-theoretic DPI on multi-agent LLM systems.

### 4.1 [arXiv:2604.02460](https://arxiv.org/abs/2604.02460), April 2026 — *Single-Agent LLMs Outperform Multi-Agent Systems on Multi-Hop Reasoning Under Equal Thinking Token Budgets*

**This is the most direct competitor for path 1 / path 2.** Detailed analysis from their HTML version:

- Setup: Markov chain $Y \leftrightarrow C \leftrightarrow M$ where $Y$ is the answer, $C$ is the full context, $M = g(C)$ is inter-agent messages.
- Uses DPI: $I(Y; C) \ge I(Y; M)$, hence $H(Y \mid M) \ge H(Y \mid C)$.
- Combined with Fano: $P_e(M) \ge P_e(C)$ — error floor higher for multi-agent.
- **Critical assumption:** $M$ is a function of $C$ only — *no accumulating discussion history*.
- Treats multi-agent as a **one-shot decomposition** $C \to M_1, M_2, \dots$, not as iterated debate with a shared scratchpad.
- Empirical: Qwen3 / DeepSeek-R1-Distill-Llama / Gemini 2.5 across multi-hop reasoning, matched-token-budget comparison.
- Conclusion: SAS matches or outperforms MAS at equal token budget.

**Why this matters.** They've claimed the **easy half** of the territory: DPI applied to one-shot multi-agent decomposition. Our **Regime A** (bounded state, single-agent self-refine) overlaps somewhat with their bound (their $C$ is essentially our $T_n$). However:

- Our **Regime B** (accumulating-history multi-agent debate) is **explicitly not covered** by their assumption. Their $M = g(C)$ does not allow $M_n$ to feed back into $M_{n+1}$.
- Our **regime distinction** (bounded state contraction vs accumulating history conservation) is **not made anywhere in their paper**. They only have contraction.
- They do not state an information-conservation result like Theorem B.

**Differentiation strategy for path 1.** Frame our paper as the natural complement: "they cover one-shot decomposition; we cover iterated multi-agent with shared state and prove **conservation, not contraction** — same wall, opposite mechanism." This is a defensible narrative if we explicitly cite them and acknowledge the overlap on Regime A.

**Differentiation strategy for path 2.** Same complementarity, plus we add the rate-explicit refinements (log-Sobolev for Regime A, surface-readout-convergence for Regime B) that they don't provide, plus heterogeneous-model ablation that they don't run.

### 4.2 [arXiv:2602.03794](https://arxiv.org/abs/2602.03794), Feb 2026 — *Understanding Agent Scaling in LLM-Based Multi-Agent Systems via Diversity*

Theorem 4.3:
$$H(Y \mid X) - \mathbb{E}[I(\tilde Z_{1:K}; Y \mid X)] \le (1-\alpha)^K H(Y \mid X) \le e^{-\alpha K} H(Y \mid X).$$
Residual uncertainty about $Y$ decays geometrically in $K$, where $K$ is *effective channel count* (defined via entropy of cosine-similarity Gram matrix of agent embeddings). Heterogeneous agents → larger $K$ → faster decay.

**Status.** Important but distinct: their dimension is $K$ (number of *distinct* agents at one shot), not $n$ (iterations). They're answering "how does *width* help" while we're answering "how does *depth* help." Both can sit in the same paper space.

**Differentiation:** their theorem applies to a single round of $K$ agents whose outputs are aggregated; ours applies to $n$ rounds of any number of agents whose state accumulates. The two scaling axes are orthogonal. We should cite them as "complementary scaling axis" rather than competitor.

### 4.3 [arXiv:2602.08003](https://arxiv.org/abs/2602.08003) — *Don't Always Pick the Highest-Performing Model: Information Theoretic View of LLM Ensemble Selection*

Information-theoretic error floor for ensembles via Gaussian-copula correlation modelling. Greedy MI-maximising selection. About *which models to ensemble*, not iteration dynamics. Orthogonal.

### 4.4 *Optimizing Multi-LLM Dialogues Through Information-Theoretic Control*

Adaptive contentiousness control using mutual information. Practical / applied; not a theorem paper.

**Cluster verdict.** **2604.02460 is the bar to clear.** It's a recent preprint (April 2026), well-positioned, and uses the same machinery (DPI). But its scope is genuinely narrower than ours — one-shot only. Our Theorem B and the regime distinction are sitting in a clean unfilled gap. Path 1 is viable if we frame this complementarity correctly; path 2 needs to add genuinely more (rate-explicit, heterogeneous ablation) to deserve the longer page count.

## 5. Self-correction — the empirical baseline

### 5.1 Huang et al., ICLR 2024 — *Large Language Models Cannot Self-Correct Reasoning Yet* ([arXiv:2310.01798](https://arxiv.org/abs/2310.01798))

Foundational negative result. Intrinsic self-correction degrades performance on GSM8K / CommonsenseQA / HotpotQA once oracle-label leakage is removed.

### 5.2 Kamoi et al., TACL 2024 — *When Can LLMs Actually Correct Their Own Mistakes?* ([TACL link](https://direct.mit.edu/tacl/article/doi/10.1162/tacl_a_00713/125177))

60+ paper meta-analysis. Pure self-critique is net-negative on hard reasoning without external grounding.

### 5.3 Madaan et al., NeurIPS 2023 — *Self-Refine*

The positive case. Self-refinement helps on **format / style / open-ended** tasks where the user's readout is the bottleneck — not on hard reasoning. This is exactly the "readout loophole" we describe.

### 5.4 Optimal Self-Consistency ([arXiv:2511.12309](https://arxiv.org/abs/2511.12309), Nov 2025)

Self-consistency convergence rate $m = (\sqrt{p_1} - \sqrt{p_2})^2$ (margin between top-1 and top-2). Power-law / exponential decay variants. Practical algorithm Blend-ASC.

**Status.** Highly relevant rate analysis for the *bounded-state* Regime A — they're computing exactly the kind of rate constant we want for our rate-explicit refinement. Need to cite and possibly use their margin definition for our log-Sobolev constant story.

**Cluster verdict.** Empirical baseline is strong and well-cited. Our theorems are the formal explanation; the loophole story matches Madaan. No conflict.

## 6. Adjacent — multi-turn jailbreak, model collapse, contraction theory

### 6.1 Russinovich et al., USENIX Security 2025 — *Crescendo* ([arXiv:2404.01833](https://arxiv.org/abs/2404.01833))

Multi-turn jailbreak via gradual benign ramp. 98% success vs GPT-4. Empirical attacker-side observation that iteration reshapes the attractor — relevant to safety section of our blog, less directly to the paper.

### 6.2 *Multi-Turn Jailbreaks Are Simpler Than They Seem* ([arXiv:2508.07646](https://arxiv.org/abs/2508.07646))

Finds many multi-turn jailbreaks reduce to a simpler attack structure. Relevant tangent.

### 6.3 Anil et al., 2024 — *Many-shot jailbreaking*

Power-law erosion of refusal as shot count grows. Iteration-axis attractor in the "harmful" basin.

### 6.4 Qi et al., 2025 — *Safety Alignment Should Be Made More Than Just A Few Tokens Deep*

Safety lives in the first few tokens; reverts toward base-model attractor afterwards.

### 6.5 Wolf et al., 2024 — *Fundamental Limitations of Alignment*

Any finitely-aligned model admits a bounded-length prompt restoring base behavior.

### 6.6 Liang & Mitra, COLT 2025 — *Dependence of Samples along Langevin Dynamics via Φ-Mutual Information* ([proceedings](https://proceedings.mlr.press/v291/liang25b.html))

Strong DPI along Langevin trajectories under Φ-Sobolev. **Φ-mutual information between iterates decays exponentially when target is strongly log-concave.** Directly relevant if we want to import log-Sobolev machinery for the rate-explicit Regime A version.

**Status.** Toolkit paper for path 2's rate-explicit refinement of Theorem A.

**Cluster verdict.** Lots of evidence that iteration in LLMs reshapes / displaces attractors (especially adversarially) — supports the *practical* bullets in our blog's "What This Means" section but not directly the theorems.

## 7. Gap analysis

What the existing literature **does** cover:

| Coverage | Papers |
|---|---|
| Single-chain CoT info loss bounds | Gan 2025, Ton 2024 |
| One-shot multi-agent DPI bound | 2604.02460 (April 2026) |
| Width-axis (K agents) MI decay | 2602.03794 (Feb 2026) |
| Bounded-state Markov chain stationary distribution | Zekri 2024 |
| Iteration-axis empirical attractors | Wang 2025, Perez 2025, Carson 2025 |
| Self-correction empirical degradation | Huang 2024, Kamoi 2024 |
| Self-consistency convergence rate | arXiv:2511.12309 (Nov 2025) |
| Iterated retraining stability (training axis) | Bertrand 2024, Shumailov 2024 |
| Long-context MI scaling (representation axis) | L2M 2025 |

What the literature **does not** cover:

1. **Information conservation under accumulating-history kernels.** No paper states $I(A^*; H_n \mid q) = I(A^*; T_0 \mid q)$ for multi-agent debate with shared scratchpad. 2604.02460 explicitly restricts to one-shot decomposition.
2. **The bounded-vs-accumulating regime distinction.** No paper points out that contraction (DPI) and conservation are *the same wall, two mechanisms*. This is conceptual framing that the field is missing.
3. **Rate-explicit Regime B.** No paper analyses *how fast surface readouts approach the Bayes-optimal readout of $T_0$* under accumulating-history kernels. 2511.12309 does the rate for self-consistency but not for accumulating debate.
4. **Heterogeneous-model ablation as a Regime B escape.** No paper has run the cleanest possible experimental falsification: 4 personas × 1 model vs 4 personas × 4 models, controlled for everything else. ecwu's `factory.py` already supports this trivially.
5. **The connection between LLM-self-reported convergence and Perez attractor strength.** No paper has put these two quantities on the same scatter plot.

## 8. Path 1 viability — workshop / short paper

**Verdict: viable, but framing matters.**

**What we have:**
- Theorem A (DPI on bounded state) — partially redundant with 2604.02460's one-shot bound; we should explicitly position it as a textbook special case, not a contribution.
- **Theorem B (information conservation on accumulating history) — genuinely novel** as far as the published literature shows. This is the contribution.
- **Regime distinction and "same wall, two mechanisms" framing** — novel. Pedagogically valuable.
- A cheap empirical signature: dump `DiscussionState` from ecwu's framework on QASPER, show LLM-self-reported convergence ↑ while Bayes-risk proxy (F1 vs gold) flat. This is path 1's empirical anchor.

**What we need:**
- A short (4–8 page) write-up centered on Theorem B and the regime distinction.
- An honest "Related Work" section that places 2604.02460, 2602.03794, and Gan ICML 2025 as parallel theoretical neighbors with disjoint scope.
- One MVP empirical figure: LLM-self-reported convergence vs offline-measured attractor strength on a real multi-agent system. ~30 papers from QASPER, no model retraining, total compute ≪ 1 GPU-day.

**Risk:** a reviewer claiming Theorem B is "an obvious corollary of DPI on $H_n$." This is technically correct — the proof is two lines. **Reply preparation:** the contribution is not the math (which is straightforward) but the *framing*: pointing out that the multi-agent literature has been confusing "no info destroyed" with "info gained," and giving the formal language to disambiguate. The Smit 2024 + 2604.02460 + Wang 2024 cluster is exactly the audience that needs this disambiguation. Cite them prominently.

**Suggested venues (sorted by deadline window):**
- **NeurIPS 2026 workshops** (papers due Aug-Sep 2026): Foundation Model Agents, Safe & Trustworthy LLMs, Workshop on Mathematical Foundations of LLMs.
- **ICLR 2027 Tiny Papers track** if they keep it.
- **ICML 2026 workshops** are already past.
- **AISTATS 2027** main if we want a short paper at a stats venue.

**Effort estimate:** 2 weeks writing + 1 week empirical + 1 week iteration. Realistic 4–6 week total to submission-ready.

## 9. Path 2 viability — full conference paper

**Verdict: viable but requires meaningful additions beyond Path 1.**

The two theorems alone are not enough to fill 8–9 pages at NeurIPS / ICLR. Path 2 needs *all* of:

1. **Rate-explicit Regime A.** Concrete log-Sobolev / Poincaré constant for self-refinement kernels under low-temperature decoding. Reuse Liang & Mitra COLT 2025 machinery if applicable. This is a real theorem with measurable predictions.
2. **Rate-explicit Regime B.** The harder one. State and prove a quantitative bound on how fast surface readouts ($\sigma$-algebra of "extract last sentence" or "extract boxed answer") approach the Bayes-optimal readout of $T_0$. This is the *novel* technical contribution for path 2; nobody has done it. Likely involves a mixing-time argument on a different operator (the readout-projection of $K_\theta$ on $H_n$).
3. **Empirical: heterogeneous-model ablation.** 4-persona × 1 model vs 4-persona × 4 models on at least 2 benchmarks (QASPER + GSM8K?) × 2 model families. Predict (and test) that homogeneous configurations plateau at $T_0$ Bayes risk while heterogeneous configurations break the bound.
4. **Empirical: rate-explicit verification.** Fit Liang–Mitra-style $\Phi$-MI decay rate on actual self-refine transcripts; show it matches the log-Sobolev constant from Regime A theorem.
5. **Connection to existing observations.** Show that Wang's $\tau$, Perez's $1-|s|$, and ecwu's self-reported convergence are all reading out facets of the same attractor structure, with Theorems A/B explaining which facets are tight bounds and which are loose.

This is **3–4 months of work** for one person, possibly more depending on (2) — the rate-explicit Regime B theorem is the riskiest item. If (2) doesn't crystallise, downgrade to path 1 + an extended journal version.

**Risk profile.** The big risk for path 2 is that 2604.02460 gets upgraded into a NeurIPS submission for the same cycle, with extended scope toward iteration. We should monitor that paper's revision history.

**Suggested venues (sorted by deadline window):**
- **NeurIPS 2026 main** (deadline ~May 2026): too tight for path 2 unless we already have (1)–(5); likely path 1 submission to workshops only.
- **ICLR 2027 main** (deadline ~Sep 2026): realistic if we start path 2 now.
- **ACL 2027 Rolling Review**: realistic with empirical framing.
- **AISTATS 2027 main**: likely fit for the theorem-heavy version.

## 10. Recommendation

**Do path 1 first.** Specifically:

1. **Week 1–2:** Write the short paper. Center it on Theorem B and the regime distinction. Frame Theorem A as "for completeness, this is the textbook bound for Regime A; we extend to Regime B."
2. **Week 2–3:** Run the MVP experiment on ecwu's Discussion Agent + QASPER. Goal: one figure showing self-reported convergence vs Bayes-risk-proxy vs Perez-style attractor strength on the same x-axis (rounds).
3. **Week 4:** Submit to nearest workshop (NeurIPS 2026 workshops in Aug–Sep window).

**Do not skip to path 2 unless** the rate-explicit Regime B theorem becomes plausible after a serious week of attempting it. If you can prove it cleanly, path 2 becomes the right move — *but the path 1 short paper is still worth submitting first* as a stake in the ground, because 2604.02460 is publicly available and somebody else may write Theorem B independently in the next 6 months.

**A failure mode to avoid.** Do not write path 2 without first having path 1's empirical figure. The empirical falsification of LLM self-reported convergence is the most immediately publishable observation in this whole stack, and it requires almost no machinery. Get it out the door first.

## 11. Open questions before drafting

Three things to clarify with collaborators / further reading before drafting either path:

1. **Has the 2604.02460 first author already extended to iterated multi-agent in their next preprint?** Watch arXiv listings monthly. If yes, our window narrows.
2. **Does ecwu's `DiscussionState` have a hook for dumping intermediate rounds without modifying his code?** Need to verify before committing to him as the testbed. (Earlier code reading suggests yes — `DiscussionState` is a Pydantic model that should serialize cleanly.)
3. **Does QASPER's gold-standard answers satisfy the $A^*$-as-random-variable framing?** The theorem requires $A^*$ to be a meaningful random variable on the joint $(q, A^*)$ space. QASPER answers are mostly extractive, which fits well; abstractive sub-questions might need separate treatment.

These are tractable in a day's work each.

## Appendix — reference index

Papers to cite (alphabetical):

- Anil et al., 2024 — Many-shot jailbreaking
- Arbuzov et al., 2025 — Beyond Exponential Decay ([arXiv:2505.24187](https://arxiv.org/abs/2505.24187))
- Bertrand et al., 2024 — Stability of Iterative Retraining (ICLR)
- Carson, 2025 — Stochastic Dynamical Theory of Self-Adversariality ([arXiv:2501.16783](https://arxiv.org/abs/2501.16783))
- Du et al., 2024 — Multiagent Debate (ICML)
- Gan et al., 2025 — Snowball Errors ([arXiv:2501.15602](https://arxiv.org/abs/2501.15602), ICML)
- Huang et al., 2024 — LLMs Cannot Self-Correct Reasoning Yet (ICLR)
- Kamoi et al., 2024 — When Can LLMs Self-Correct (TACL)
- Liang & Mitra, 2025 — Φ-Mutual Information along Langevin (COLT)
- Madaan et al., 2023 — Self-Refine (NeurIPS)
- Optimal Self-Consistency ([arXiv:2511.12309](https://arxiv.org/abs/2511.12309))
- Perez et al., 2025 — Telephone Game ([arXiv:2407.04503](https://arxiv.org/abs/2407.04503), ICLR)
- Qi et al., 2025 — Shallow Safety Alignment
- Russinovich et al., 2025 — Crescendo (USENIX Security)
- Shumailov et al., 2024 — Recursive Generation Collapse (Nature)
- Smit et al., 2024 — Should we be going MAD (ICML)
- Ton et al., 2024 — CoT through Information Theory ([arXiv:2411.11984](https://arxiv.org/abs/2411.11984))
- Wang et al., 2025 — Attractor Cycles in Paraphrase ([arXiv:2502.15208](https://arxiv.org/abs/2502.15208), ACL)
- Wolf et al., 2024 — Fundamental Limitations of Alignment
- Zekri et al., 2024 — LLMs as Markov Chains ([arXiv:2410.02724](https://arxiv.org/abs/2410.02724), ICLR)
- [arXiv:2602.03794](https://arxiv.org/abs/2602.03794) — Agent Scaling via Diversity (Feb 2026)
- [arXiv:2602.08003](https://arxiv.org/abs/2602.08003) — Information-Theoretic Ensemble Selection
- [arXiv:2604.02460](https://arxiv.org/abs/2604.02460) — Single-Agent vs Multi-Agent under Token Budget (April 2026) **— closest competitor**
