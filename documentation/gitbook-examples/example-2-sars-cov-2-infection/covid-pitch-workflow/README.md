---
description: >-
  Exploring post SARS-CoV-2 infection immune trajectories and predicting durable
  immunity
icon: '3'
---

# COVID Pitch workflow

This example workflow will answer the key immunological questions using the SARS-CoV-2 dataset and the PANDORA software. The following six phases will walk you through the analysis for this example:

<details>

<summary><a href="phase-1-data-overview/"><strong>Phase 1: Data overview</strong></a></summary>

Prepare the dataset for downstream analysis by uploading it to PANDORA to assess the different data types within the dataset, view their distributions for preliminary exploration, and inspect missing values, which are especially common in longitudinal studies.&#x20;

**PANDORA Tools Utilized:** [Workspace](https://atomic-lab.gitbook.io/pandora/general/workspace), [Data Overview](https://atomic-lab.gitbook.io/pandora/data-analysis/discovery/data-overview) (Distribution Plot, Table Plot)

**Outcome:** A foundational understanding of the dataset's characteristics and quality.

</details>

<details>

<summary><a href="phase-2-multivariate-exploratory-analysis/"><strong>Phase 2: Multivariate exploratory analysis</strong></a></summary>

In this phase, the analysis addresses the first objective, "**Visualize the trajectories of diverse immune responses over 6 months"**. Principal Component Analysis (PCA) allows investigation of how individuals cluster based on their overall immune profile and whether this relates to features such as disease severity, changes over time, or responder status. Correlation analysis helps understand the relationships _between_ different immune measurements across all samples and timepoints.

**PANDORA Tools Utilized:** [PCA Analysis](https://atomic-lab.gitbook.io/pandora/data-analysis/discovery/pca-analysis), [Correlation](https://atomic-lab.gitbook.io/pandora/data-analysis/discovery/correlation)

**Outcome:** Uncover patterns in the data that reveal insights on the trajectory of immune responses over 6 months, and relationships between immune parameters over time as it relates to disease severity and responder status.

</details>

<details>

<summary><a href="phase-3-data-pre-processing.md"><strong>Phase 3: Data pre-processing</strong></a></summary>

This phase isolates the specific data needed for the supervised task: predicting the 6-month outcome from early data.

**Tools Utilized:** Python, R, or Excel

**Outcome:** A new filtered dataset in a form that the predictive ML models can use effectively to predict durability, and determine early immune signatures that can predict the durability of a person's immune response to SARS-CoV-2 infection.

</details>

<details>

<summary><a href="phase-4-predictive-modelling/"><strong>Phase 4: Predictive modelling</strong> </a></summary>

Configure and initiate machine learning models within PANDORA, using early immune measurements (28 days pso) as predictors for the `Responder` outcome where a high responder is defined as anti-N Ab titer ≥ 1.4 = High responder (seropositive).

**Tools Utilized:** [Predictive (SIMON) Interface](https://atomic-lab.gitbook.io/pandora/data-analysis/predictive#id-1.-simon-machine-learning)

**Outcome:** Trained predictive models ready for evaluation.

</details>

<details>

<summary><a href="phase-5-model-evaluation.md"><strong>Phase 5: Model evaluation</strong></a></summary>

Assess the performance of the trained models using appropriate metrics (e.g., AUC), and utilize explainable AI techniques to identify the most influential early immunological features driving the predictions.

**PANDORA Tools Utilized:** [Predictive ](https://atomic-lab.gitbook.io/pandora/data-analysis/predictive/exploration)(Exploration: Metrics, ROC Curve Analysis, Variable Importance)

**Outcome:** Identification of the optimal predictive model(s) and key predictive immunological parameters.

</details>

<details>

<summary><a href="phase-6-results.md"><strong>Phase 6: Results</strong></a></summary>

Consolidate all analytical results, interpret the biological significance of the top predictors, and formulate a comprehensive report on the model's performance and findings as it relates to the key objectives.

**PANDORA Tools:** Review PANDORA Outputs from prior analysis

**Outcome:** A complete report that interprets analytical results for real immunological insights.

</details>

