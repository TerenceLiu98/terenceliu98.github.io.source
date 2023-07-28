---
title: "🤔 A General Introduction of ML/DL Project Management and Knowledge Management - Project Management"
date: 2023-07-28T00:15:00+08:00
draft: false
math: true
tags: ["Management", "Deep Learing", "Coding"]
series: ["Project Management", "Knowledge Management"]
---

There are multiple articles have illustruated that the project(code) management is important:
<!--more-->

1. [neptune.ai - how to organize deep learning projects](https://neptune.ai/blog/how-to-organize-deep-learning-projects-best-practices)
2. [深度学习科研，如何高效进行代码和实验管理？](https://www.zhihu.com/question/269707221/answer/350542551)

In this guideline, I would mainly shows you how I manage my project's code and link the new knowledge to the knowledge base.

## In General

A lifecyle of a project may includes this five points[^1]:
1. Planning and project setup
    * Define the task and scope out requirements
    * Determine project feasibility
    * Discuss general model tradeoffs (accuracy vs speed)
    * Set up project codebase
2. Data collection and labelling
    * Define ground truth (create labeling documentation)
    * Build data ingestion pipeline
    * Validate quality of data
    * Label data and ensure ground truth is well-definend
    * Revisit Step 1 and ensure data is sufficient for the task
3. Model exploration
    * Establish baselines for model performance
    * Start with a simple model using initial data pipeline
    * Overfit simple model to training data
    * Stay nimble and try many parallel (isolated) ideas during early stages
    * Find SoTA model for your problem domain (if available) and reproduce results, then apply to your dataset as a second baseline
    * Revisit Step 1 and ensure feasibility
    * Revisit Step 2 and ensure data quality is sufficient
4. Model refinement
    * Perform model-specific optimizations (ie. hyperparameter tuning)
    * Iteratively debug model as complexity is added
    * Perform error analysis to uncover common failure modes
    * Revisit Step 2 for targeted data collection and labeling of observed failure modes
5. Testing and evaluation
    * Evaluate model on test distribution; understand differences between train and test set distributions (how is “data in the wild” different than what you trained on)
    * Revisit model evaluation metric; ensure that this metric drives desirable downstream user behavior
    * Write tests for:
        * Input data pipeline
        * Model inference functionality
        * Model inference performance on validation data
        * Explicit scenarios expected in production (model is evaluated on a curated set of observations)

For each part of the project, there are multiple different tools we may use:
1. Planning and project step, in specific, it could be treated as the project tracking, thus, all the tracking tools can be used in the step, e.g., Confluence, YouTrack, Jira, Trello, etc..
2. Data collection and labelling: If we are using the public dataset, we may ignore the labelling problem; however, if we are collecting and labelling our own dataset, we may consider these [awesome-labelling-tools](https://github.com/HumanSignal/awesome-data-labeling); the next question for the data storage and collection is the versioning problem, we may consider these tools:
    1. [Neptune](https://neptune.ai/)
    2. [WandB](https://wandb.ai/)
    3. [DVC](https://dvc.org/)
    4. [LakeFS](https://lakefs.io/)
    5. [Git LFS](https://git-lfs.com/)
3. Log tracing
    1. We can use `loggings` or `tensorboard` to store the log to the local directory
    2. We can also use `wandb`, `neptune` and other tools to store the log to both the local directory or the cloud

## Project Specification

The project specification includes two aspects:
1. project files specification
2. git branche specification

### Project files Specification

Here is the architecuture of a project[^2]

|  Files/Catalogue   |  Detail   | Required  |
|--------------|---------|---------|
| README.md     | Instruction of the project and the folder architecture | YES |
| train.py      | Model Traning and Validation | YES |
| test.py       | Model Testing | YES |
| src/{model-name}.py | Statement and Source code of the Model (For single model) | YES |
| src/{model-name}.py | Statement and Source code of the Model (For multiple models) | YES |
| src/{modules-name}/{model-name}}.py | Statement and Source code of the Model (For multiple submodules & single model) | YES |
| src/{modules-name}/{model-name}.py | Statement and Source code of the Model (For multiple submodules & multiple models) | YES |
| utils/loss.py | Implementation of loss function | NO |
| utils/base.py | utilities file | NO |
| data/data.py | Dataset and DataLoader Implemenetation | NO |
| data/train.txt | manifest file of training set | NO |
| data/validate.txt   | manifest of validation set | NO |
| data/test.txt   | manifest of testing set | NO |
| experiment/{exp-name}/params.yaml | configuration of the experiment | YES |
| experiment/{exp-name}/log/ | folder to store the log file produced by the experiment | YES |
| experiment/{exp-name}/model/ | folder to store the binary file of the trained models  | YES |
| experiment/{exp-name}/result/ | folder to store the model output (images, csv, etc.) | YES |

### Git Branch Specification

Every projects may face a problem: how to perform multiple experiments in parallel? We adopt the solution of git branch:
1. Each experiment has a corresponding git branch
2. Three kinds of branches: 
    1. Temporary branches: start with `TEMP_`
    2. Long-term branches: start with `MAIN_`
    3. Project Introduction/Demo branch: `main`: include the basic information of the project in the branch
3. The branches' name should includes:
    1. Main purpose of the branch, i.e. model's name
    2. Dataset it use: i.e., dataset's name
    3. Others: whether the experiment include augmentation or other configuration

Here are two examples:
1. `TEMP_PIX2PIX_DRIVE_NOAUG` represents a temporary branch with `pix2pix` model using `DRIVE` dataset with no augmentation in data preprocessing
2. `MAIN_PIX2PIX_MESSIDOR_AUG` represents a long-term branch with `pix2pix` model using `MESSIDOR` dataset with augmentation in  data proprocessing

[^1]: There are some extra steps, you may check them in [Jeremey Jordan's Blog](https://www.jeremyjordan.me/ml-projects-guide/)
[^2]: For more detail, please check [CKLAU's GitLab - Specification](https://git.cklau.cc/terenceliu/specification/)