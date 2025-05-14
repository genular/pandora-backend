# Flu Fighters Workflow

In this workflow, you will learn how to use PANDORA to create and analyze a predictive model using the Flu Fighter dataset. You’ll begin by preparing the dataset for use with PANDORA, then explore key tools in the Discovery section, which includes [Data Overview](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview), [Correlation](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/correlation), [t-SNE Analysis](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/t-sne-analysis), and [Hierarchical Clustering](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/hierarchical-clustering). You will then learn how to build and evaluate predictive models using PANDORA's [Predictive section](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive). Each phase of the workflow is outlined below.

<details>

<summary><a href="./#phase-1-data-configuration">Phase 1: Data Configuration</a></summary>

Configure and understand the dataset for use in the predictive analysis

1. **Launch PANDORA**
   * Brief intro on how to launch PANDORA after installation.

2) **Inspect Data**
   * Upload dataset and inspect data to understand variable types and distributions.

3. **Explore Outcome Variable Relationships**
   * Run analysis to uncover correlations between outcome variables.

</details>

<details>

<summary><a href="./#phase-2-define-responders">Phase 2: Define Responders</a></summary>

Define the responder column to be used in the predictive analysis via method A or method B

1. **Method A**
   1. Define responder classification via clustering with t-SNE
2. **Method B**
   1. Manually define responder classification based on a  biological threshold

</details>

<details>

<summary><a href="./#phase-3-confounding-check">Phase 3: Confounding Check</a></summary>

Ensure your model isn't biased by checking for any potential confounding demographic variables

1. **Set Up Confounding Analysis**
   * Configure t-SNE analysis for confounding variable check.
2. **Check for Confounding**
   * Analyze resulting t-SNE plots and check the distribution of confounding variables in responder classifications.
3. **Additional Analysis**
   * Further analysis in the case that the confounding variable distribution among responder classifications is unclear on the t-SNE plot.

</details>

<details>

<summary><a href="./#phase-4-predictive-modeling">Phase 4: Predictive Modeling</a></summary>

Create your predictive models for responder classification based on baseline data.

1. **Process Predictive Dataset**
   * Remove outcome variables from the dataset for predictive analysis
2. **Set Up Prediction Task**
   * Using PANDORA, configure predictive models for responder classification
3. **Run Analysis**
   * Generate and analyze predictive models

</details>

<details>

<summary><a href="./#phase-5-predictive-results">Phase 5: Predictive Results</a></summary>

Assess predictive model results to identify top models and understand model predictions with Explainable AI

1. **Configure Exploration**
   * Select analysis from Dashboard, then select the dataset and models for which to view results.
2. **Evaluate Model Performance**
   * View and compare performance metrics for each model.
3. **Identify Key Predictors**
   * Identify and analyze top predictive features for top models.
4. **Interpret Model Behavior**
   * Utilize explainable AI tools to uncover variable relationships and contributions to model behavior.

</details>

<details>

<summary><a href="./#phase-6-synthesize-findings">Phase 6: Synthesize Findings</a></summary>

Combine all your findings to report on your best model

1. **Combine Findings**
   * Take record of all relevant model information including confounding check, performance measurements, and predictive features
2. **GO Term Analysis & Biological Themes (if applicable)**
   * Analyze top predictive GO terms and uncover biological themes

</details>
