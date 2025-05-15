---
description: Predicting LAIV Response
---

# Flu Fighters Workflow

This example workflow demonstrates the application of PANDORA to investigate predictors of immune response to the Live Attenuated Influenza Vaccine (LAIV), using the "Flu Fighters" dataset. The overarching goal is to identify baseline immune features capable of classifying participants into "high" or "low" vaccine responder categories.

**Workflow Phases:**

<details>

<summary><a href="phase-1-data-configuration.md">Phase 1: Data Configuration &#x26; Initial Inspection</a></summary>

**Objective:** To prepare the dataset for analysis by uploading it into PANDORA, examining its structure, identifying missing data patterns, and visualizing initial variable distributions and correlations.

**PANDORA Tools Utilized:** [Workspace](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/general/workspace), [Data Overview](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview), [Correlation](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/correlation).

**Outcome:** A foundational understanding of the dataset's characteristics and quality.

</details>

<details>

<summary><a href="phase-2-define-responders.md">Phase 2: Defining Vaccine Responders</a></summary>

**Objective:** To categorize participants into distinct immune response groups (e.g., "high" vs. "low" responders) based on post-vaccination outcome variables. This establishes the target variable for subsequent predictive modeling.

**PANDORA Tools/Methods Utilized:** [t-SNE Analysis](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/t-sne-analysis) (for data-driven clustering) or manual definition based on external biological thresholds.

**Outcome:** A new 'ResponderStatus' variable classifying each participant.

</details>

<details>

<summary><a href="phase-3-confounding-check.md">Phase 3: Confounding Variable Assessment</a></summary>

**Objective:** To evaluate whether potential confounding variables (e.g., age, sex, study year) are differentially distributed across the defined responder groups, which could bias downstream analyses.

**PANDORA Tools Utilized:** [t-SNE Analysis](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery#t-sne) (visualizing group distributions).

**Outcome:** Assessment of potential confounding to ensure the robustness of predictive findings.

</details>

<details>

<summary><a href="phase-4-predictive-results.md">Phase 4: Predictive Modeling Setup</a></summary>

**Objective:** To configure and initiate machine learning models within PANDORA, using baseline immune measurements as predictors for the 'ResponderStatus' outcome defined in Phase 2.

**PANDORA Tools Utilized:** [Predictive (SIMON interface).](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive#id-1.-simon-machine-learning)

**Outcome:** Trained predictive models ready for evaluation.

</details>

<details>

<summary><a href="phase-4-predictive-results.md">Phase 5: Predictive Model Evaluation &#x26; Interpretation</a></summary>

**Objective:** To rigorously assess the performance of the trained models using appropriate metrics (e.g., AUC) and to identify the most influential baseline features driving the predictions using explainable AI techniques.

**PANDORA Tools Utilized:** [Predictive ](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration)(Exploration: Metrics, ROC Curve Analysis, Variable Importance, Model Interpretation).

**Outcome:** Identification of the optimal predictive model(s) and key predictive biomarkers.

</details>

<details>

<summary><a href="phase-6-synthesize-findings.md">Phase 6: Synthesis of Findings</a></summary>

**Objective:** To consolidate all analytical results, interpret the biological significance of the top predictors, and formulate a comprehensive report on the model's performance and findings.

**PANDORA Tools/External Analysis:** Review of PANDORA outputs, potential pathway enrichment analysis (external), biological literature review etc..

**Outcome:** A complete analytical report with actionable insights.

</details>
