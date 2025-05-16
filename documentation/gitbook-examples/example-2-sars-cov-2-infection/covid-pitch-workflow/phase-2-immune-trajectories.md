---
icon: chart-scatter-bubble
---

# Phase 2: Immune Trajectories

### Purpose

PCA can be used to reduce the dimensionality of the complex immune data and visualize the features that contribute to the most variation in the dataset across all timepoints. We will use PCA to also investigate how individuals cluster based on their overall immune profile and whether this relates to features such as disease severity, changes over time, or responder status&#x20;

### Action

<details>

<summary>Perform PCA</summary>

1. Navigate to PCA analysis by going to **Discovery -> Start -> PCA analysis**&#x20;

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-14 080523.png" alt=""><figcaption></figcaption></figure>

2. Select all relevant columns on which to perform PCA. This can be achieved in two ways:&#x20;
   1. Selecting desired columns in the <kbd>Columns</kbd> tab. For this example, we will choose all numerical immunological assay columns (e.g. e.g., `pseudoNA Abs`, `ADCD`, `ADMP`, `ADNKA`, `B cells elispot`, `S-IgA`, `S-IgG1`…, `N-IgG`, Proliferation assays, T cell ELISpots, MSD assays etc.)&#x20;
   2. Removing undesired columns in the E<kbd>xclude Columns</kbd> tab. For this example, since we want to keep all numerical immunological assays, we will remove `Donor ID`, `Timepoint`, `Days pso`, `Responder`, demographics (`Age`, `Sex`), clinical symptom columns

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-14 082628.png" alt=""><figcaption></figcaption></figure>

{% hint style="warning" %}
You **cannot** use categorical variables to perform PCA&#x20;
{% endhint %}

3. Perform **preprocessing** of the features. This is essential for PCA

<figure><img src="../../.gitbook/assets/image (1).png" alt=""><figcaption></figcaption></figure>

Choose `center` and `scale` to perform z-score normalization on the data&#x20;

Choose a method for addressing the missing values. There are two options: **a)** **`medianimpute`** (replaces NA with median of the feature data, might be acceptable for visualization) and **b)** `Remove NA` toggle (if imputation is undesirable, but this reduces data considerably)&#x20;

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-14 083940.png" alt=""><figcaption></figcaption></figure>

4. Choose a **grouping variable.** This will determine how to color the PCA plot and clusters, and is vital for interpreting immune trajectories&#x20;

To choose a grouping variable, go to PCA Settings (below Preprocessing Options)&#x20;

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-14 084250 (1).png" alt=""><figcaption></figcaption></figure>

For this dataset, we will be grouping the variables based on `Disease severity`, `Timepoint` and optionally `Responder` variables. The plots and analysis using these grouping variables can be seen [below](phase-2-immune-trajectories.md#pca-plots-and-analysis-based-on-grouping-variables).

</details>

<details>

<summary>Analyze Variable Plot</summary>

<figure><img src="../../.gitbook/assets/CP_PCA variables plot.png" alt=""><figcaption></figcaption></figure>



</details>

<details>

<summary>Disease Severity </summary>

<figure><img src="../../.gitbook/assets/CP_disease_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

<figure><img src="../../.gitbook/assets/CP_disease_PCA indiv biplot (1).png" alt=""><figcaption></figcaption></figure>



</details>

<details>

<summary>Timepoint</summary>



<figure><img src="../../.gitbook/assets/CP_timepoint_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

<figure><img src="../../.gitbook/assets/CP_timepoint_PCA indiv biplot (2).png" alt=""><figcaption></figcaption></figure>

</details>

<details>

<summary>Responder Status (Optional)</summary>



<figure><img src="../../.gitbook/assets/CP_responder_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

<figure><img src="../../.gitbook/assets/CP_responder_PCA indiv biplot (1).png" alt=""><figcaption></figcaption></figure>

</details>
