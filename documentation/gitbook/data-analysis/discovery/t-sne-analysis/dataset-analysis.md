---
description: Helping users assess differences between clusters in their t-SNE analysis
---

# Dataset analysis

This tab helps you understand the biological meaning behind the clusters identified in the **Clustered t-SNE Analysis** tab. It relates the cluster assignments back to the original high-dimensional feature data (e.g., gene expression levels, protein abundances).

<figure><img src="../../../.gitbook/assets/tSNE_Dataset Analysis_Highres-min_annotated.png" alt=""><figcaption><p>Dataset Analysis tab showing a heatmap of features per cluster</p></figcaption></figure>

{% tabs %}
{% tab title="1. Analysis Graph" %}
Based on the **Dataset Analysis Type** chosen in the setup, this area displays a visualization comparing the original feature values across the clusters identified by the t-SNE clustering.

#### 1. Heatmap View

If you selected "Heatmap" as the **Dataset Analysis Type**, this view will show a heatmap comparing the average feature values for each cluster.

<figure><img src="../../../.gitbook/assets/tSNE_Data analysis_Heatmap.png" alt="" width="375"><figcaption><p>Heatmap showing mean feature values per cluster</p></figcaption></figure>

* **Structure:**
  * **Rows:** Represent the original features (variables) included in the analysis. Rows might be reordered based on similarity (hierarchical clustering).
  * **Columns:** Represent the clusters identified in the **Clustered t-SNE Analysis** tab (e.g., labeled "pandora\_cluster" 1, 2, 3). Columns might also be reordered based on similarity, often indicated by a dendrogram above them.
* **Cell Colors:** The color of each cell reflects the average value of that specific feature (row) within that specific cluster (column).
  * Values are typically **normalized or scaled** (e.g., Z-score transformed) across each feature (row) to make values comparable across features with different units or ranges.
  * **Warm colors (e.g., red):** Indicate the feature has a higher average value in that cluster compared to its average across all clusters.
  * **Cool colors (e.g., blue):** Indicate the feature has a lower average value in that cluster.
  * **Neutral colors (e.g., white/yellow):** Indicate the feature value is close to the overall average for that feature.
* **Color Legend:** A legend shows the mapping between colors and the scaled/normalized values. Another legend typically maps cluster IDs to the columns.
* **Interpretation:** Look for patterns within columns (clusters) or rows (features). Blocks of similar colors highlight features that are consistently up- or down-regulated within a specific cluster, revealing the unique "signature" of that group.

#### 2. Hierarchical Clustering Analysis View

If you selected "Hierarchical Clustering Analysis" as the **Dataset Analysis Type**, this view displays a heatmap similar to the one described above, but with added dendrograms to explicitly show hierarchical relationships.

<figure><img src="../../../.gitbook/assets/tSNE_Data analysis_Hierarchical clustering.png" alt="" width="375"><figcaption></figcaption></figure>

* **Visualization:** The core is still a heatmap where:
  * **Rows** are features.
  * **Columns** are the t-SNE clusters.
  * **Cell Colors** represent the average, scaled feature value within each cluster (Red = high, Blue = low).
* **Hierarchical Clustering Emphasis:**
  * **Row Dendrogram (Left):** A tree structure showing how features are grouped based on the similarity of their average value patterns across the clusters. Features close together on the dendrogram have similar profiles across the identified t-SNE groups.
  * **Column Dendrogram (Top):** A tree structure showing how the t-SNE clusters themselves are grouped based on the similarity of their overall feature profiles (average values across all features). Clusters that merge early in the dendrogram have more similar feature signatures.
* **Interpretation:** This view not only shows the feature signatures of each cluster (like the basic heatmap) but also highlights higher-order relationships:
  * Identify groups of co-regulated or similarly behaving features across the conditions defined by the t-SNE clusters.
  * Identify which t-SNE clusters are most similar to each other based on their overall feature profiles.
{% endtab %}

{% tab title="2. Actions" %}
The "Actions" button (often located on the right side of the **Dataset Analysis** tab) provides options to utilize the cluster assignments generated from the t-SNE analysis for further steps.

* **Start ML Analysis:**
  * **Purpose:** Sends the data, including the newly assigned cluster labels, to the SIMON predictive modeling platform.
  * **Use:** Allows you to train and evaluate machine learning models (e.g., classifiers) that predict the t-SNE cluster membership based on the original features. You can then explore the model performance and feature importance.
* **Download:**
  * **Purpose:** Exports the dataset with the cluster assignments included.
  * **Use:** Download your original data with an additional column indicating the cluster membership (e.g., Cluster 1, Cluster 2, etc.) assigned to each sample during the **Clustered t-SNE Analysis**. This file can be used for offline analysis or with other tools.
* **Save to Workspace:**
  * **Purpose:** Saves the dataset (including the cluster assignments) as a new item within your PANDORA workspace.
  * **Use:** Allows you to easily access and reuse this clustered dataset for subsequent analyses within PANDORA without needing to rerun the t-SNE clustering step.
{% endtab %}
{% endtabs %}

#### Interpretation

* **Identify Cluster Signatures:** Look for blocks of color within the heatmap. For example, a column (cluster) with a block of bright red indicates that the corresponding features have high average values specifically in that cluster. These features form the "signature" of that cluster.
* **Compare Clusters:** Compare the color patterns across columns to see which features differentiate the clusters.
* **Relate to Biology:** Use the identified feature signatures to infer the potential biological identity or state represented by each cluster (e.g., a cluster high in specific cell markers might represent a particular cell type).
