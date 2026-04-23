---
title: "🧑🏿‍💻 Train A Language Model From Scratch"
date: 2024-12-27T00:15:00+00:00
draft: false
math: true
comment: true
tags: ['Artificial Intelligence', 'language model', 'LLM']
series: ['LLM']
bibFile: /content/post/scientia/machine-learning/bib.json
---

## Beginning 

You may think that the training a language model from scratch can seem like a daunting task, but it is a rewarding journey that deepens your understanding of machine learning and natural language processing. In this guide, we will explore the fundamental steps required to build a language model, from data preparation to model training and evaluation. Whether you're a beginner or an experienced practitioner, this process will provide valuable insights into the inner workings of large language models.

## Starting from the tasks

When training a language model, various tasks are employed to help the model learn and generalize effectively. These tasks are tailored to different stages of the training process, such as pretraining, supervised fine-tuning (SFT), and reinforcement learning with human feedback (RLHF). Below are some of the most widely used tasks, along with detailed explanations:

- **Masked Language Modeling (MLM):**  
Starting from the MLM, which is widely used in the word embedding training, proposed by Google in 2017 {{< cite "devlin2019bert" >}}. In short, it is a pretraining task where certain tokens in the input sequence are randomly masked, and the model is trained to predict these masked tokens based on their surrounding context. This task enables the model to learn bidirectional representations of text, making it effective for understanding the relationships between words in a sentence. For example, in the sentence "The [MASK] is blue," the model learns to predict the masked word "sky." Models like BERT and RoBERTa heavily rely on MLM for pretraining. The `DataCollatorForLanguageModeling` in the Hugging Face Transformers library is often used to implement this task, where it handles token masking dynamically during training.

- **Causal Language Modeling (CLM):**  
  CLM, also known as autoregressive modeling, involves predicting the next token in a sequence based on the previous tokens. This task is unidirectional, meaning the model only considers past context when generating the next word. For instance, given the input "The cat is," the model predicts the next word, such as "sleeping." CLM is the backbone of models like GPT and GPT-2, which are designed for text generation tasks. The `DataCollatorForLanguageModeling` can be used for CLM, depending on the implementation.

- **Supervised Fine-Tuning (SFT):**  
  SFT is a critical step after pretraining, where the model is fine-tuned on labeled datasets for specific downstream tasks. These tasks can include text classification, summarization, or question answering. For example, in summarization, the model is trained to generate concise summaries of input documents. During SFT, the model learns to adapt its pretrained knowledge to domain-specific requirements. The `DataCollatorForSeq2Seq` is often used for tasks like summarization, as it handles input-output pairs efficiently.

- **Reinforcement Learning with Human Feedback (RLHF):**  
  RLHF is used to align the model's outputs with human preferences and ethical considerations. This process involves three main steps:  
  1. **Supervised Fine-Tuning:** A base model is fine-tuned on a dataset of human-labeled examples.  
  2. **Reward Model Training:** A separate reward model is trained to score the quality of the model's outputs based on human feedback.  
  3. **Policy Optimization:** The language model is further fine-tuned using reinforcement learning, guided by the reward model.  
  RLHF is particularly useful for tasks like conversational AI, where the model needs to generate responses that are both helpful and aligned with user expectations.

By combining these tasks, we can train language models that are not only powerful but also versatile and aligned with human expectations. Each task plays a unique role in shaping the model's capabilities, from understanding context to generating coherent and meaningful text.

## What about the Data Format

The format of the training data plays a crucial role in determining the effectiveness of the language model. Different formats are used depending on the task and the stage of training, such as pretraining, fine-tuning, or reinforcement learning. Below, we discuss some commonly used data formats, including the Alpaca format and Vicuna's multi-round chat format.

### Alpaca Format

The Alpaca format is designed for instruction-tuning tasks, where the model is fine-tuned to follow instructions and generate helpful responses. This format typically consists of a JSON structure with fields such as `instruction`, `input`, and `output`. Here's an example:

```json
{
  "instruction": "Summarize the following text.",
  "input": "Artificial intelligence is a branch of computer science that aims to create machines that can perform tasks that typically require human intelligence.",
  "output": "Artificial intelligence is a field focused on creating machines capable of human-like intelligence."
}
```

- **Instruction:** Specifies the task the model should perform.  
- **Input:** Provides additional context or data required to complete the task. This field can be empty for tasks that don't require extra input.  
- **Output:** Contains the expected response or result for the given instruction and input.

This format is widely used in fine-tuning models like Alpaca and other instruction-following models. It ensures that the model learns to handle a variety of tasks in a structured manner.

### Vicuna's Multi-Round Chat Format

Vicuna's multi-round chat format is tailored for conversational AI models, where the goal is to train the model to handle multi-turn dialogues effectively. This format captures the back-and-forth nature of human conversations. An example of this format is as follows:

```json
{
  "conversation": [
    {"role": "user", "content": "What is the capital of France?"},
    {"role": "assistant", "content": "The capital of France is Paris."},
    {"role": "user", "content": "Can you tell me more about it?"},
    {"role": "assistant", "content": "Paris is known as the City of Light and is famous for its art, culture, and landmarks like the Eiffel Tower."}
  ]
}
```

- **Role:** Indicates whether the message is from the `user` or the `assistant`.  
- **Content:** Contains the text of the message.  

This format is particularly useful for fine-tuning models to generate coherent and contextually relevant responses in multi-turn conversations. It helps the model maintain context across multiple exchanges, making it suitable for chatbots and virtual assistants. However, I don't think the format are most important 


However, different formats can be leveraged by the `process` function, which means the format is not the first priority of in the training process, instead, the data itself is. Below is a example for converting vicuna format to alpaca.

```python
def vicuna_to_alpaca(conversation):
    user = [conv.get("user", "None") for conv in conversation]
    assistant = [conv.get("assistant", "None") for conv in conversation]
    instruct = [conv.get("instruction", "None") for conv in conversation]
    return instruct, user, assistant
```

## Data Filtering 

Although format might be important, data quality is much more vital for the training. As the raw corpora are riddled with inconsistencies, artifacts, and ethical pitfalls. Deduplication, for instance, goes beyond simple substring matching: advanced methods like MinHash or SimHash identify near-duplicates at scale, while fuzzy hashing detects paraphrased or lightly edited repetitions. Similarly, normalization involves granular steps: Unicode normalization (e.g., converting “café” and “café” to a consistent form), stripping non-linguistic markup (e.g., LaTeX, HTML tags), and handling whitespace irregularities (e.g., replacing multiple spaces or tabs with a single space). Tools like ftfy (“fixes text for you”) repair mojibake (garbled text from encoding errors). What's more, corpora can also contain toxicity and bias, and filtering these harmful contents requires multi-layered strategies. Model-based methods are now most widely used — like Google's Perspective API or HuggingFace's detoxify flag can help remove explicit hate speech, but nuanced toxicity (e.g., microaggressions, sarcasm) demands custom fine-tuning.

Different stages have different filtering priorities. For pretraining the goal is *coverage and quality at scale*, so most pipelines combine cheap rule-based filters (length thresholds, language ID, gibberish ratio, repetition ratio) with one or two model-based passes (perplexity scoring against a small reference LM, classifier-based quality scoring like the fastText classifier used in CCNet/RedPajama). For instruction-tuning the goal flips: the dataset is small enough that *each example matters*, so the filter cares about response correctness, helpfulness, and stylistic consistency — typically scored by a stronger LLM acting as judge. For preference data (used in RLHF/DPO), the priority is *agreement among annotators* and the *margin* between chosen and rejected responses; low-margin pairs are noisy and hurt more than they help.

A practical heuristic I keep coming back to: if you can describe the filter in one sentence, you should run it before training; if it takes a paragraph, it probably belongs in your eval suite instead.

```python
# A minimal pretraining filter chain that covers most of the obvious cases.
import re, ftfy

def basic_clean(text: str) -> str | None:
    text = ftfy.fix_text(text)
    text = re.sub(r"\s+", " ", text).strip()
    if len(text) < 200:                          # too short to learn anything
        return None
    if len(set(text.split())) / max(1, len(text.split())) < 0.3:
        return None                              # extremely repetitive
    if sum(c.isalpha() for c in text) / len(text) < 0.6:
        return None                              # mostly punctuation/digits
    return text
```

Finally, *domain mixing*. A pretraining corpus is a weighted mixture: web crawl, code, books, papers, encyclopedias, multilingual text. The mixing weights matter at least as much as the raw data — LLaMA-2 {{< cite "touvron2023llama2" >}} and many open replications spend significant effort here, often with separate sampling temperatures per source so that small but high-quality shards (e.g., Wikipedia, arXiv) are upsampled relative to their natural frequency.

## Tokenization

Once the data is clean, the next decision is *how to chop it into tokens*. The dominant choice today is **subword tokenization** — a vocabulary of ~32k–128k pieces, learned to balance compression (fewer tokens per sentence) against generalization (rare words still decompose into known pieces).

Two algorithms dominate:

- **Byte-Pair Encoding (BPE)** {{< cite "sennrich2016bpe" >}}: start from a character (or byte) vocabulary, then iteratively merge the most frequent adjacent pair until the vocabulary reaches the target size. GPT-2/3/4 and most open models use a byte-level variant, which guarantees the tokenizer never crashes on unseen Unicode.
- **Unigram / SentencePiece**: train a probabilistic language model over candidate subwords and prune to a fixed vocabulary by EM. Used by T5, ALBERT, and most multilingual models because it handles whitespace-free scripts (Chinese, Japanese, Thai) more naturally.

Two practical points that bite people:

1. **Train the tokenizer on the same distribution as the pretraining corpus.** A tokenizer trained mostly on English will fragment Chinese or code into far more tokens than necessary, which directly inflates training cost and hurts long-context behavior.
2. **Add special tokens *before* training, not after.** `<|im_start|>`, `<|endoftext|>`, `<pad>`, tool-call delimiters — if you bolt them on after pretraining, their embeddings start from random and the model needs many tokens of fine-tuning before it stops emitting them in weird places.

```python
from tokenizers import Tokenizer, models, trainers, pre_tokenizers, decoders

tok = Tokenizer(models.BPE())
tok.pre_tokenizer = pre_tokenizers.ByteLevel(add_prefix_space=False)
tok.decoder = decoders.ByteLevel()
trainer = trainers.BpeTrainer(
    vocab_size=64_000,
    special_tokens=["<|endoftext|>", "<|im_start|>", "<|im_end|>", "<pad>"],
    initial_alphabet=pre_tokenizers.ByteLevel.alphabet(),
)
tok.train(files=["corpus.txt"], trainer=trainer)
tok.save("tokenizer.json")
```

## Model Architecture

Almost every modern LLM is a decoder-only Transformer {{< cite "vaswani2017attention" >}} with a stack of identical blocks. The original "Attention Is All You Need" recipe — multi-head attention, LayerNorm, GELU, learned positional embeddings — has been quietly replaced piece by piece. The current "default" block, popularized by LLaMA, looks like:

- **Pre-norm** instead of post-norm — apply normalization *before* attention/FFN, which makes training much more stable at depth.
- **RMSNorm** instead of LayerNorm — drop the mean-subtraction term; cheaper, and empirically just as good.
- **Rotary Positional Embeddings (RoPE)** instead of learned/sinusoidal positions — encode position by rotating the query/key vectors, which extrapolates better to longer contexts.
- **SwiGLU** instead of GELU in the feed-forward — gated linear unit with SiLU activation, consistently a small but real win.
- **Grouped-Query Attention (GQA)** instead of full multi-head — share KV heads across query heads to shrink the KV cache (the bottleneck at inference time).

A single block, in PyTorch, is shorter than people expect:

```python
import torch, torch.nn as nn, torch.nn.functional as F

class RMSNorm(nn.Module):
    def __init__(self, dim, eps=1e-6):
        super().__init__()
        self.weight = nn.Parameter(torch.ones(dim))
        self.eps = eps
    def forward(self, x):
        return self.weight * x * torch.rsqrt(x.pow(2).mean(-1, keepdim=True) + self.eps)

class SwiGLU(nn.Module):
    def __init__(self, dim, hidden):
        super().__init__()
        self.w1 = nn.Linear(dim, hidden, bias=False)
        self.w2 = nn.Linear(hidden, dim, bias=False)
        self.w3 = nn.Linear(dim, hidden, bias=False)
    def forward(self, x):
        return self.w2(F.silu(self.w1(x)) * self.w3(x))

class Block(nn.Module):
    def __init__(self, dim, n_heads, hidden):
        super().__init__()
        self.norm1 = RMSNorm(dim)
        self.attn  = nn.MultiheadAttention(dim, n_heads, bias=False, batch_first=True)
        self.norm2 = RMSNorm(dim)
        self.ffn   = SwiGLU(dim, hidden)
    def forward(self, x, mask):
        h = self.norm1(x)
        a, _ = self.attn(h, h, h, attn_mask=mask, need_weights=False)
        x = x + a
        x = x + self.ffn(self.norm2(x))
        return x
```

The full model is just `nn.Embedding` → `N × Block` → `RMSNorm` → tied output projection. Almost everything interesting about a 7B-vs-70B model comes from scale, data, and training procedure — not from architectural cleverness.

## Pretraining

Pretraining is conceptually simple — next-token prediction over the corpus — but the engineering is where the time goes. The loss is the standard cross-entropy

$$\mathcal{L}\_{\text{CLM}}(\theta) = -\sum\_{t=1}^{T} \log p\_{\theta}(x\_t \mid x\_{<t}),$$

averaged over a packed batch of sequences. A few choices that disproportionately matter:

- **Optimizer.** AdamW with $\beta\_1 = 0.9$, $\beta\_2 = 0.95$ (note the lower $\beta\_2$ — standard $0.999$ is too sluggish for LM pretraining), weight decay $0.1$, and gradient clipping at $1.0$.
- **Learning-rate schedule.** Linear warmup over the first ~1% of steps, then cosine decay to ~10% of peak. Peak LR scales roughly as $\sim 1/\sqrt{d\_{\text{model}}}$.
- **Batching.** Pack multiple short documents into one fixed-length sequence, separated by `<|endoftext|>`, to keep GPU utilization high. Mask the loss across document boundaries if you care about clean per-doc semantics.
- **Mixed precision.** BF16 is now the default — same dynamic range as FP32, half the memory, no loss-scaling gymnastics.
- **Distributed training.** ZeRO-3 (DeepSpeed) or FSDP (PyTorch native) shards optimizer state, gradients, and parameters across GPUs. Tensor/pipeline parallelism enter once the model itself doesn't fit on one device.

A skeleton training step, stripped down:

```python
from torch.utils.data import DataLoader

opt   = torch.optim.AdamW(model.parameters(), lr=3e-4, betas=(0.9, 0.95), weight_decay=0.1)
sched = torch.optim.lr_scheduler.CosineAnnealingLR(opt, T_max=total_steps)

for step, batch in enumerate(DataLoader(packed_dataset, batch_size=bsz)):
    with torch.autocast("cuda", dtype=torch.bfloat16):
        logits = model(batch["input_ids"])
        loss = F.cross_entropy(
            logits[:, :-1].reshape(-1, vocab),
            batch["input_ids"][:, 1:].reshape(-1),
            ignore_index=PAD_ID,
        )
    loss.backward()
    torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
    opt.step(); sched.step(); opt.zero_grad(set_to_none=True)
```

The single most important habit during pretraining is to **plot the loss curve obsessively** and watch for the failure modes you've seen before: a sudden spike (lower the LR or skip the bad batch and resume), a slow drift upward (data ordering or numerical issue), a plateau that won't break (LR too low, or you've actually saturated this dataset).

## Supervised Fine-Tuning

After pretraining you have a model that *completes* text. SFT is what turns it into a model that *responds* to text. The loss is still next-token prediction, but applied only to the assistant's reply — the prompt tokens are masked out so the model isn't penalized for "predicting" the user's message.

```python
def sft_loss(logits, labels, prompt_lens):
    # mask out prompt tokens by setting their label to -100 (ignored by F.cross_entropy)
    labels = labels.clone()
    for i, p in enumerate(prompt_lens):
        labels[i, :p] = -100
    return F.cross_entropy(logits[:, :-1].reshape(-1, vocab),
                           labels[:, 1:].reshape(-1),
                           ignore_index=-100)
```

Practical rules of thumb for SFT:

- **A few thousand to a few tens of thousands of examples is usually enough.** More is not always better — once the model has learned the format, additional low-quality data hurts.
- **Use a much smaller LR than pretraining** (typically $1e\text{-}5$ to $5e\text{-}5$) and a *very* short warmup. SFT moves the model in distribution-space; aggressive updates erase pretraining knowledge ("catastrophic forgetting").
- **Train for 1–3 epochs.** Beyond that the model starts to memorize the SFT set and loses generality.
- **Always keep a held-out eval set drawn from the *same distribution as your real users*** — public benchmarks are useful but rarely predict deployment behavior.

## Preference Alignment: from RLHF to DPO

SFT teaches the model *one way* to respond. Preference alignment teaches it *which of two responses is better*, which is a much weaker but much cheaper supervision signal — humans are far better at picking the preferred answer than at writing the ideal one.

Classical **RLHF** {{< cite "ouyang2022instructgpt" >}} is the three-step pipeline already sketched in the task list: (1) SFT, (2) train a reward model $r\_{\phi}(x, y)$ on preference pairs $(x, y\_w \succ y\_l)$ with the Bradley–Terry loss
$$\mathcal{L}\_{\text{RM}}(\phi) = -\mathbb{E}\_{(x, y\_w, y\_l)}\left[\log \sigma\bigl(r\_{\phi}(x, y\_w) - r\_{\phi}(x, y\_l)\bigr)\right],$$
and (3) fine-tune the policy $\pi\_{\theta}$ with PPO against $r\_{\phi}$ while penalizing KL drift from the SFT reference $\pi\_{\text{ref}}$. It works, but it is finicky: PPO is unstable, the reward model can be hacked, and you end up serving four models at training time (policy, reference, reward, value).

**Direct Preference Optimization (DPO)** {{< cite "rafailov2023dpo" >}} is the recipe most teams now reach for first. The insight is algebraic: under the standard KL-regularized RL objective, the optimal policy has a closed-form relationship to the reward model, which means you can re-parameterize away the reward model entirely and optimize the policy directly on preference pairs:
$$\mathcal{L}\_{\text{DPO}}(\theta) = -\mathbb{E}\_{(x, y\_w, y\_l)}\!\left[\log \sigma\!\left(\beta \log\frac{\pi\_{\theta}(y\_w \mid x)}{\pi\_{\text{ref}}(y\_w \mid x)} - \beta \log\frac{\pi\_{\theta}(y\_l \mid x)}{\pi\_{\text{ref}}(y\_l \mid x)}\right)\right].$$

No reward model, no rollouts, no PPO — just two forward passes (policy and frozen reference) on the same preference pair. The single hyperparameter $\beta$ controls how strongly the policy is allowed to drift from $\pi\_{\text{ref}}$ (smaller $\beta$ = more aggressive). DPO is not a strict superset of RLHF — it can't easily incorporate online exploration or non-pairwise rewards — but for the common case of "I have a preference dataset, make my model better" it is dramatically simpler and usually competitive.

A handful of DPO variants are worth knowing about: **IPO** (avoids overfitting when preferences are deterministic), **KTO** (works with binary thumbs-up/down instead of pairs), **ORPO** (folds SFT and preference loss into one stage so you don't need a separate reference model), and **SimPO** (reference-free, length-normalized). They mostly differ in how they handle the reference policy and how they normalize for response length.

## Evaluation

Loss curves go down. Benchmarks go up. Neither tells you whether the model is actually useful. A reasonable evaluation stack has three layers:

1. **Automatic, broad-coverage benchmarks** — MMLU, GSM8K, HumanEval, IFEval, MT-Bench. Cheap, reproducible, and easy to over-fit to. Track them, but never *only* them.
2. **Task-specific evals you wrote yourself** — a few hundred prompts that look like your actual product traffic, scored either by a stronger LLM judge or by a rubric. This is where regressions actually show up.
3. **Human evaluation on a small, representative slice.** Slow and expensive, but the only signal that captures what users will actually feel. Use it to *calibrate* your LLM-judge scores, not to replace them.

For pretraining specifically, perplexity on a held-out shard of the same distribution is the cleanest signal of "is the model still learning?" Cross-distribution perplexity (e.g., perplexity on code when training on web) is a useful early-warning for over-specialization.

## Closing Thoughts

Building a language model from scratch is less a single algorithm and more a stack of decisions, each of which is individually boring but collectively determines whether the final model is any good. The dominant lesson of the last five years is that the *boring* parts — data quality, tokenization, evaluation discipline — usually matter more than the exciting parts (architecture tweaks, novel objectives). The architectural recipe converged to a small handful of choices; the post-training recipe is converging on DPO-family methods; what's left to differentiate models is mostly data and care.

If you're doing this for the first time, my suggestion is to start small — a 100M-parameter model on a few billion tokens — and run the *entire* pipeline end-to-end (clean → tokenize → pretrain → SFT → DPO → eval) before scaling any single stage. The bugs you find at small scale are the same bugs you would have found at large scale, except they cost you a weekend instead of a quarter.

## Reference

{{< references >}}
