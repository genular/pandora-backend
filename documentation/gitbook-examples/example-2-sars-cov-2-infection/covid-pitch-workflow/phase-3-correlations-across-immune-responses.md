---
icon: chart-line-up-down
---

# Phase 3: Correlations across immune responses

### Purpose

Correlation analysis helps understand the relationships _between_ different immune measurements across all samples and timepoints. This helps confirm if certain responses tend to occur together (positive correlation) or are mutually exclusive/inversely related (negative correlation)

### Action

<details>

<summary>Perform correlation </summary>

1. Navigate to perfrom correlation analysis by going to **Discovery -> Start -> Correlation**&#x20;

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-15 140554.png" alt=""><figcaption></figcaption></figure>

2. Choose the same numerical immunological assays columns as used in PCA under Column Selection&#x20;
3. Select **Spearman** for the **Correlation Method** within the Column Selection Tab

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-15 141012.png" alt=""><figcaption></figcaption></figure>

4. Under the **Preprocessing** tab, select `center` and `scale` to normalize the data

<figure><img src="../../.gitbook/assets/image (2).png" alt=""><figcaption></figcaption></figure>

5. Go to the Correlation Settings tab:&#x20;
   1. **NA Action**: Set it to a method that can appropriately **handle missing values** such as `pairwise.complete.obs`
   2. **Plot Type**: Select preferred option to view the correlation in the plot. For this example, the `Full` type was chosen&#x20;
   3. **Reorder Correlation**: Select `Hierarchical clustering` to visualize relationships between clustered parameters&#x20;
   4. **Method**: This tab will appear when Hierarchical clustering is selected. Select `Ward` algorithm for clustering.

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-15 141316.png" alt=""><figcaption></figcaption></figure>



</details>

<details>

<summary>Correlogram - Correlation of Immune parameters</summary>

<figure><img src="../../.gitbook/assets/CP_clustered correlation_all immune assays (1).png" alt=""><figcaption></figcaption></figure>

</details>

<details>

<summary>Correlogram Analysis: Correlation of Immune parameters and Timepoints</summary>

<figure><img src="../../.gitbook/assets/CP_clustered correlation_all immune assays_days pso timepoints (1).png" alt=""><figcaption></figcaption></figure>

</details>
