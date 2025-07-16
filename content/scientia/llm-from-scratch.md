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

Although format might be important, data quality is much vital for the training. As the raw corpora are riddled with inconsistencies, artifacts, and ethical pitfalls. Depulication, for instance, goes beyond simple substring matching: advanced methods like MinHash or SimHash identify near-duplicates at scale, while fuzzy hashing detects paraphrased or lightly edited repetitions. Similarly, normalization involves granular steps: Unicode normalization (e.g., converting “café” and “café” to a consistent form), stripping non-linguistic markup (e.g., LaTeX, HTML tags), and handling whitespace irregularities (e.g., replacing multiple spaces or tabs with a single space). Tools like ftfy (“fixes text for you”) repair mojibake (garbled text from encoding errors). What's more, corpora can also contains toxicity and bias, to filtering these harmful content requires multi-layered strategies. Model-based methods is now most widely used, like Google's perspective API or Huggingface's detoxify flag can help remove explicit hate speech, but nuanced toxicity (e.g., microaggressions, sarcasm) demands custom fine-tuning.

Different steps has different filtering process. For instance, instruct-tuning process