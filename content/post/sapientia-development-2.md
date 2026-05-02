---
title: "🤓 Humans do Marginalia, AIs doe Zettelkasten - 构建科研民工的第二大脑 (2)"
date: 2026-05-02T00:12:00+01:00
draft: false
math: true
tags: ['vibe-coding', '开发日记', '第二大脑', 'note-taking']
series: ['vibe-coding', 'sapientia-development']
comment: true
---

## 前情提要

在上一篇文章里，我们分析了两种长期以来一直在竞争的个人知识管理范式：Marginalia 和 Zettelkasten。它们各自的优点和缺点都很明显，Marginalia 摩擦极低但缺合成层，Zettelkasten 真要做好成本极高但能长成一张由想法编织起来的网。我们提出了一个 thesis：**Humans do Marginalia, AIs do Zettelkasten**，人做 marginalia 该做的，AI 做 Zettelkasten 该做的。用户该干的事，跟打开 Acrobat 没什么两样——读、划线、在旁边写一两句感想，不学新方法论、不维护一套新系统，也不会被工具逼着给每条笔记起标题、编号；AI 在背后把那些人类长期撑不下来的活接过去：
- **把边注理解成原子想法**：从一句“诶？”或“重要”里抽出它真正指向的那个概念
- **把高亮颜色当语义信号**：哪里你停下来过、哪里被标成“待解决”、哪里你重读了三次 {{< sidenote >}}是产品的设计目标{{</ sidenote >}}
- **把跨论文的相似边注连成概念**：当 paper A 第 17 页的边注和 paper B 第 3 页的边注其实指向同一件事时，自动把这条边画上
- **把累积的 marginalia 长成 wiki 与图谱**：一个跟着阅读自动生长、不需要手动维护的个人知识库

## 设计选择

对各种相关的产品进行了调研以后，我发现了如下几类产品：

1. 以论文管理/阅读为中心的，比如 Zotero 的各种插件以及独立产品，包括 [Beaver](https://www.beaverapp.ai)、[LLM for Zotero](https://github.com/yilewang/llm-for-zotero)、[Zotero-GPT](https://github.com/MuiseDestiny/zotero-gpt)、[Moonlight](https://www.themoonlight.io/en)、[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)——这类产品大多围绕 PDF 阅读做 AI 加持，有的帮你跟论文对话，有的帮你生成 summary，有的（如 LLM Wiki）甚至做到了自动维护一个 wiki，但它们共同的局限是：**知识不积累**。对话结束，session 散了；summary 生成，放进抽屉，下次打开又是从零开始。Karpathy 的 LLM Wiki 是 Sapientia wiki 部分的方法论鼻祖——`purpose.md` 驱动、两步思维链摄入、四信号关联度——但它长在 Obsidian 上，复用了 Obsidian 的编辑器、文件系统和 wikilink 渲染，**给那些愿意自己拼插件的研究者准备的**，而不是一个开箱即用的产品。
2. 是以知识图谱和文献发现为中心的，比如 [Connected Papers](https://www.connectedpapers.com)、[Litmaps](https://www.litmaps.co)、[ResearchRabbit](https://www.researchrabbit.ai)——这类产品的能力在于帮你看到一个研究领域的"地形图"，哪些论文是核心节点、哪些是边缘发现、哪些之间有隐含的引用关系。它们解决的问题是"找论文"，不是"读论文"和"记住论文"，而且它们的图谱是基于 citation network 构建的——**论文和论文之间的关系**，而不是**概念和概念之间的关系**。Sapientia 需要的图谱恰恰反过来：它不在乎这篇论文引用了哪篇，它在乎的是这篇论文里的 "alignment" 和另一篇论文里的 "alignment" 到底是不是同一件事。
3. 是以 AI 助手/总结为中心的，比如 [SciSpace](https://typeset.io/)、[NotebookLM](https://notebooklm.google/)、[Elicit](https://elicit.com/)——你上传一篇论文，AI 给你摘要、帮你回答问题、甚至替你"读完"整篇文章。这类产品在 2025-2026 年的市场上非常流行，"让 AI 替你读论文"几乎成了一个默认叙事。但 Sapientia 的立场很明确：**AI 不替用户读论文**。这不是能力上的限制，是设计上的拒绝——一个会替你读论文的工具，最终给你的不是知识，而是一种"我读过了"的幻觉。AI 可以在后台做合成、在被召唤时帮忙、事后做总结，但深度阅读这件事只能由用户自己完成。

### karpathy's LLM-Wiki & Atomic

在所有调研过的产品里，对 Sapientia v2 设计影响最大的有两个，但它们打动我们的点完全不同。

#### Karpathy's LLM Wiki

Andrej Karpathy 在最近发布了一个叫 [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 的 gist，本质上是一套 prompt 模板 + 工作流，跑在他自己的 Obsidian 笔记库里。它的想法是：你给 LLM 一个 `purpose.md`（你的研究目标和关注点），然后 LLM 对你笔记库里每一条笔记做两步处理——先提取关键信息，再判断它跟你当前研究目标的关联度——最后把所有相关内容合成进你的 wiki。

LLM Wiki 打动我们的不是它的技术实现，而是它证明了一件事：**LLM 维护的 wiki 可以是有用的**。在那之前，"让 AI 帮你整理笔记"听起来要么是 ChatGPT 式的对话摘要，要么是 Notion AI 式的段落改写——都是一次性的、不积累的。LLM Wiki 第一次展示了一个持续生长、由 LLM 自主维护、有目的驱动的知识库长什么样。不过 all in AI-based wiki 之前，信息/知识的主导者在科研这里应该首先是人，而不是 LLM 或者 AI，从这一点出发，LLM-wiki 更多的是为 AI chatbot 提供 context，而不是为 human reader 提供 context。其次，LLM Wiki 的输入是 loose markdown 笔记，这些笔记的质量和格式参差不齐，AI 需要花很多精力去理解和纠正它们，而科研工作者的 context 一版是论文，而论文也可以理解成一种 loose 的八股文，而八股文是有相对固定的结构和格式的——标题、段落、图表、公式、引用等等，这些都可以被 AI 直接解析成结构化的 paper blocks，**不需要用户先把它们转成 markdown 笔记**。最后，LLM Wiki 的 wiki page 是用户的默认界面，这就有点问题了——用户打开 Obsidian，看到的第一件事是 AI 生成的 wiki page，而不是他真正想看的论文内容，这很容易让人觉得“AI 替我读完了论文”, 那我应该做什么呢？ 

Sapientia 从 LLM Wiki 那里继承的核心思路是：**purpose-driven 的合成 + 持续增量更新**。但在三件事上做了根本性的改变：(a) 输入从 loose markdown 变成 parsed paper blocks，用户不需要手动摘录，而是专注在 context 本身（无论是 PDF 亦或是 Markdown）；(b) wiki 从用户阅读页面变成 agent-facing memory，用户看到的始终是论文本身；(c) 整个东西从 Obsidian 插件 + 脚本变成一个开箱即用的产品。

#### Atomic

[Atomic](https://atomicapp.ai/) 是一个独立产品，它的核心想法极其干净：**search、wiki、graph、chat 不应该是四个独立的产品，它们应该是同一个知识底层的四个投影**。你在 Atomic 里存一条笔记（它叫 atom），这条笔记会被 chunk、embed、tag、link，然后：

- wiki 从 atoms 里自动合成，每条 claim 都链回 atom
- chat 从 atoms 里检索回答，而不是凭空编造
- canvas 把 atoms 之间的语义关系可视化
- search 搜的是 atoms，不是原始文档

这个架构的优雅之处在于：**你只需要维护一份知识，它自然地在不同形态之间流动**。没有 wiki 和 graph 数据不一致的问题，没有"我在 wiki 里写了但 search 搜不到"的断层。Atomic 还有一个很关键的细节：**citations 是信任边界**——wiki 里生成的每一条 claim 都必须能链回某条 atom，你不会看到 LLM 凭空总结出来的、找不到出处的段落。

但 Sapientia 不打算照搬 Atomic，原因很根本：**Atomic 是 knowledge-base-first，Sapientia 是 reading-first**。Atomic 的核心单元是一条 markdown note——你主动写下来的、脱离了任何具体文档的原子想法。它的默认工作流是：你先有了一个想法，你把它写下来，然后系统帮你处理它。Sapientia 的核心单元是一篇论文里的一个 concept——它从 paper blocks 里被 AI 提取出来，由 evidence 支撑，带着这篇论文特有的 `sourceLevelMeaning`{{< sidenote >}}即"这个概念在这篇论文里到底是什么意思"，比如 "alignment" 在 Paper A 里是让 LLM 输出匹配人类偏好，在 Paper B 里是对齐图像和文本的 embedding——名字一样，意思完全不同{{</ sidenote >}}，并且可以被用户的 marginalia 持续塑造。这就是 Sapientia 版本的 atom：**paper-local concept atom**，一个从论文的 parsed blocks 里长出来的、有根有据的概念单元。还有一个关键区别：Atomic 的 wiki 是它的主界面——你打开 Atomic，默认看到的就是合成好的 wiki page。同 LLM-wiki 中的分析一样，这样的设计对于一个 knowledge-base-first 的工具来说是合理的，但对于一个 reading-first 的工具来说就不太合适了。用户打开 Sapientia，看到的应该始终是论文本身，而不是 AI 生成的 wiki page；用户的默认行为应该是读、划线、写边注，而不是浏览 wiki 或 graph。AI 生成的 wiki 和 graph 是对用户阅读行为的自然反应和补充，而不是用户的默认界面。

不过 Atomic 教给 Sapientia 的最重要的一课不是任何具体 feature，而是一个架构原则：**substrate before surface**。wiki、graph、search、agent 不应该各自维护一套数据，它们应该共享同一份知识底层，然后各自作为这份底层的不同投影自然生长。这个原则直接变成了 Sapientia 设计原则的第三条。

## Sapientia 呢？

回到第一篇提出的 thesis：Humans do marginalia, AIs do Zettelkasten。 在一开始的时候，我会将这理解成 "用户在前端划线写笔记，AI 在后端生成 wiki 和图谱"。v1 跑通之后，我们意识到这个理解还不够 sharp。问题出在：**wiki page 和 concept graph 做出来以后，用户真的会去看吗？还是会变成又一个"AI 替你总结的页面"然后被无视？**

如果用户花更多时间在看 AI 生成的 summary 上，而不是在论文本身上，那 Sapientia 就已经偏了——它变成了又一个 SciSpace/Moonlight 式的"让 AI 替你读论文"的工具，而不是一个真正以阅读为中心、AI 作为辅助的工具。基于此，我想对 thesis 做一个更精确的表述：

> **Humans read papers. AI maintains the concept substrate. The interface reveals that substrate only when it helps the reading.**

这不是放弃 wiki 和图谱，而是重新定位它们。wiki 变成了 agent 的 memory，不是用户的阅读页面；graph 变成了 reasoning 的底层结构，不是用户默认看到的 dashboard；**用户看到的，始终是论文本身**——只不过当你在某个 block 上停顿、划线、或者写下"这里跟 Paper X 说的不一样"的时候，那个积累了一段时间的概念底层会安静地浮现出来，告诉你"这个概念在你读过的三篇论文里都出现过，证据在这里"。

1. Paper-first, not wiki-first. 论文永远是中心，用户的默认界面就是 PDF 阅读器，AI 生成的 wiki 和 graph 只是一个构建知识网络的工具，而不会打扰用户的沉浸式阅读。
2. Evidence-first, not claim-first. 每一个 synthetic 的 claim/concept 都必须链接会原文的具体 block，用户可以随时验证 AI 在说什么，建立对 AI 生成内容的信任， 而不是被 AI 的 summary 左右。 
3. Substrate before surface. wiki、graph、search、agent 不应该各自维护一套数据，它们共享同一份知识底层，用户的每一次阅读行为都在修改同一个 substrate，然后 wiki、graph、agent 自然地从这份 substrate 里长出来，不存在"wiki 里写了但 graph 里没有"的断层。
4. Graph should be felt before seen. 图谱的大部分价值是隐形的，它在 ranking concepts、在检索 evidence blocks、在帮 agent 回答、在通过共享概念连接不同的论文。用户不需要"看图谱"就能享受到图谱的好处。只有在用户主动想检查"我读过的论文里，这些概念之间到底是什么关系"的时候，类似于 [Conncted Paper](https://www.connectedpapers.com) 一样，paper-paper graph 才会被呈现，但是不同的是，Sapientia 呈现的不是基于 citation network 的 paper graph，而是基于 concept network 的 concept graph, 基于这个 graph，用户可以看到自己说关注的某一个主题在不同论文里是怎么被讨论的，哪些论文在这个主题上是核心节点，哪些论文之间有隐含的联系。
5. Marginalia shapes salience, not ontology. 论文内容决定了"有哪些概念"，用户的 marginalia 决定了"哪些概念重要"。一篇论文里出现了 "contrastive learning" 和 "batch size"，两个概念都被提取出来——但如果用户反复在 "contrastive learning" 上划线、写笔记，那它的 salience 就会升高，在 Concept Lens 和检索结果里排在前面。用户的行为不会删除低 salience 的概念，只会让高 salience 的概念更突出。**同一个动作两头都用**——这就是 Marginalia 和 Zettelkasten 在最小颗粒度上协作的样子。用户的每一次划线和边注不仅是对论文内容的理解和加工，也是对 AI 维护的概念底层的塑造和引导。

## Vibe Coding 

笔者曾经多次尝试 vibe coding 都以失败告终。当然，很多情况下是不知道为了 vibe coding 而 vibe coding，不免落入平庸。这一次不太一样，从文中也可以看出，笔者这次是有备而来，准备好了钱和一个相对明确的目标，so far so good。 所以，也向分享一下我对 vibe coding 的一些思考。

Vibe coding 本身是一种在不确定性和模糊性中前进的工程迭代，相比于传统的工程模式，VC 更加强调快速迭代、不断调整方向、以及对用户反馈的敏感。一般来说，功能的提出和实现不是线性的，而是一个循环的过程：
1. **提出功能**：基于对用户需求的理解和市场调研，我们提出了一个功能，比如"AI 维护的 wiki"或者"基于概念的图谱"。
2. **快速实现**：我们不会花太多时间在设计和规划上，而是直接进入编码阶段，快速实现一个最小可行版本（MVP）。这个版本可能非常粗糙，甚至不太好用，但它的目的是为了验证我们的想法，看看它是否真的解决了用户的问题。
3. **收集反馈**：我们把这个 MVP 放到用户面前，收集他们的反馈和使用数据。我们会关注用户是否真正使用了这个功能，他们在使用过程中遇到了什么问题，他们喜欢什么、不喜欢什么。
4. **调整和迭代**：基于用户的反馈，我们会调整我们的设计和实现。可能我们会发现用户并不喜欢这个功能的某个方面，或者我们会发现一个更好的实现方式。我们会迅速迭代我们的代码，改进这个功能，或者在必要的时候彻底重构它。
5. **重复这个过程**：我们会不断重复这个循环，提出新的功能，快速实现，收集反馈，调整和迭代。通过这个过程，我们能够在不确定性中前进，逐步构建出一个真正满足用户需求的产品。

那么现在的 agent 工具一版是以什么思路来构建的呢？ 比如在沙盒中执行任务、修改代码/bug、生成 PR、自动测试等等，这些功能的提出和实现是线性的还是循环的？我们是否在每个功能的实现过程中都收集了用户的反馈，并基于这些反馈进行了调整和迭代？我们是否在不断重复这个过程，以确保我们的产品能够真正满足用户的需求？无论是否满足这样的循环，现有的 agent 更多的是 “agent 操作代码” 的范式，而没有进入到 agentic SDLC 的范式。也就导致了许多非科班的人，比如笔者，或者更准确地说，那些没有受过专业 software development 训练的人，在开始 vibe coding 的时候，虽然一开始感觉很爽，但很快就会感觉到无从下手，不知道如何构建一个合理的迭代流程，最终导致 vibe coding 的失败。我将这一个过程总结为：

```
需求意图不可追踪 → 任务拆解不可审计 → 代码修改不可局部化 → 验收标准不稳定 → 迭代历史不可重放
```

作为曾是半个数学相关专业的学生，笔者不禁要问，如果我们把这个过程抽象成一个生长过程，实际上我们构建的是不是一个 DAG？从这个思路出发，如果将所有的功能模块构建成一个 DAG，那么我们在实现的时候或者迭代的时候只需要构建/测试它及其下游受影响的部分，形成一个局部的 DAG 子图，从而达到一个持续集成和增量构建的基础。同时，从并行的角度出发，DAG 的结构也允许我们在没有依赖的模块之间进行并行开发和测试，提高我们的开发效率。

但这里的 DAG 不是传统 build system 意义上的“文件依赖图”，而更像是一个 **intent-to-artifact graph**：上游是需求意图和验收标准，中游是任务拆解、上下文选择、agent 执行、代码 diff、测试结果，下游才是最终长出来的 feature。本质上，vibe coding 之所以容易失控，是因为我们平时只看见了最末端的代码，却看不见这段代码是为什么被写出来的、它依赖了哪些前提、失败过哪些尝试、又是依据什么被判定为“可以合并”的 {{< sidenote >}}这里笔者不是意图大家物理意义上看不见，而是说使用者很容易忽略一些 coding 上的细节 {{</ sidenote >}}。一旦这些东西不可见，整个开发过程就只能靠直觉维持；而直觉一旦中断，项目就会迅速退化成一堆彼此解释不清的 patch。

如果顺着这个思路继续走下去，那么一个更像样的 agentic SDLC 也许应该至少满足几件事：第一，**每一次迭代都要绑定一个局部且稳定的意图单元**，比如“给 PDF block 加稳定 ID”，而不是“把阅读器体验做得更好”；第二，**每一个意图单元都要带着自己的可执行验收条件**，比如 parser snapshot、e2e case、或者最起码是一组可以重跑的人工检查项；第三，**agent 的工作范围要局部化**，它拿到的是和当前子图相关的上下文，而不是整个仓库的一团混沌；第四，**每一次成功或失败的尝试都应该沉淀为可回放的 artifact**，包括 prompt、plan、diff、test log、review comment。这样一来，我们积累的就不只是代码，还有“这段代码是怎么长出来的”这一层过程知识。

到了这一步，vibe coding 才开始从一种情绪，变成一种方法。人负责决定下一个要扩张的 frontier：这件事值不值得做，验收标准是什么，失败了要不要回滚；agent 负责在局部子图里执行：补代码、修测试、解释改动、尝试替代实现。整个过程仍然可以保持很强的速度感，甚至比传统工程更快，但这种“快”不再建立在遗忘之上，而是建立在**局部性、可验证性和可重放性**之上。你可以随时砍掉一条分支，而不需要把整个项目推倒重来；你也可以把两个互不依赖的子图交给不同 agent 并行推进，而不会在最后 merge 的时候才发现彼此踩坏了地基。

从这个意义上说，笔者现在真正感兴趣的已经不只是“用 agent 写代码”，而是“如何让 agent 参与一个可以持续生长的开发系统”。Sapientia 表面上是在做一个 reading-first 的 AI note-taking tool，但在实现它的过程中，我越来越强烈地感觉到：**产品本身需要第二大脑，开发过程本身也需要第二大脑**。如果前者是在解决“人读过的东西如何积累成知识”，那后者解决的就是“人和 agent 一起写过的东西，如何积累成一个不会失忆的工程系统”。也许这才是这次 vibe coding 和之前几次最大的不同：不是为了 vibe coding 而 vibe coding，而是试图给 vibe coding 长出骨架。从某种意义上说，似乎又和 harness engineering 有一些相似之处[^0]。

[^0]: 关于 harness engineering，可以阅读 Anthropic 的 [Effective harnesses for long-running agents](https://www.langchain.com/blog/the-anatomy-of-an-agent-harness?utm_source=chatgpt.com)
