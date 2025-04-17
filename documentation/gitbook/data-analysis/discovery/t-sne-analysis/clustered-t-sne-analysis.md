---
description: >-
  Enables improved visualization of t-SNE plot trends through algorithmic
  clustering
---

# Clustered t-SNE analysis

This tab displays the t-SNE plot after applying a clustering algorithm (selected in the setup, e.g., Louvain) to the 2D t-SNE coordinates. This helps to automatically identify and label distinct groups within the visualization.

<figure><img src="../../../.gitbook/assets/tSNE_Clustered tSNE_Highres-min_annotated.png" alt=""><figcaption><p>Screenshot of the Clustered t-SNE Analysis tab showing colored clusters</p></figcaption></figure>

#### What it Shows

* **Clustered t-SNE Plot:** The main visualization is the standard t-SNE scatter plot, but now the points (samples) are colored according to the cluster they were assigned to by the chosen algorithm.
* **Cluster Labels:** Each distinct cluster is typically labeled directly on the plot (e.g., "1 - 54" indicates Cluster 1 containing 54 points).
* **Legend:** A legend maps the colors back to the cluster IDs.
* **Algorithm Information:** Text above the plot often specifies the clustering method used (e.g., Louvain) and may mention specific details, such as how outliers are handled (e.g., designated cluster "100").
* **Silhouette Score:** An average silhouette score might be displayed, providing a metric for how well-separated the clusters are (values range from -1 to +1, higher values indicate better clustering).

#### How to Interpret

* **Identify Groups:** Use the colors and labels to clearly see the distinct groups identified by the clustering algorithm within the t-SNE map.
* **Evaluate Clustering:** Compare the automatically identified clusters to any visual patterns you observed in the standard t-SNE plot or based on known grouping variables. The silhouette score gives a quantitative measure of cluster separation.
* **Foundation for Further Analysis:** These cluster assignments form the basis for the analyses performed in the **Dataset Analysis** tab, which examine the characteristics of these groups using the original high-dimensional data.

{% tabs %}
{% tab title="1. Clusters" %}
This view displays the t-SNE plot where samples are colored based on the clusters identified by the algorithm you selected in the setup (e.g., Louvain, Hierarchical).

* **Visualization:** Each point represents a sample, colored according to its assigned cluster ID. This helps you clearly visualize the groups found by the clustering method within the t-SNE map.
* **Silhouette Score:** A description above or near the plot usually includes the **average silhouette score** for the clustering result.
  * This score measures how similar each sample is to its own cluster compared to other clusters.
  * Values range from -1 to +1.
  * A high value (closer to +1) indicates that samples are well-matched to their own cluster and poorly matched to neighboring clusters, suggesting well-defined, distinct clusters.
  * Values near 0 indicate overlapping clusters.
  * Negative values generally indicate that samples might have been assigned to the wrong cluster.
* **Download:** You can download this plot as an SVG file or right-click to save it as a PNG directly from PANDORA.

<figure><img src="../../../.gitbook/assets/Clustered_tSNE.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}

{% tab title="2. Features" %}
This view helps you understand the characteristics of the clusters identified in the **Clustered t-SNE Analysis** by examining the original data features (variables).

* **Visualization:** Displays a plot (often a grouped bar plot) titled "Mean Values of Features by Cluster".
  * The **X-axis** represents the different clusters identified by the clustering algorithm.
  * The **Y-axis** represents the mean value of each feature within a specific cluster (often after scaling/centering if applied during preprocessing).
  * Within each cluster on the X-axis, there are multiple bars, each representing a different original feature, colored according to the legend.
* **Interpretation:** Compare the heights of the bars for the _same feature_ (same color) across different clusters.
  * Features with significantly higher or lower mean values in one cluster compared to others are potential biomarkers or distinguishing characteristics of that cluster.
  * For example, if the pink bar (representing `nasal_foldchange_go.0070498`) is much higher in Cluster 1 than in Clusters 2 and 3, it suggests this feature has a high average value specifically in the samples belonging to Cluster 1.

<figure><img src="../../../.gitbook/assets/tSNE_CLustered t-SNE_ FeaturesPlot.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}

{% tab title="3. FoldChange" %}
This view allows you to compare the relative levels of original features across the different clusters identified in the **Clustered t-SNE Analysis**, typically represented as fold changes.

* **Visualization:** Displays a plot, often titled "Fold Change of Features Across Clusters".
  * The **Y-axis** lists the identified clusters.
  * The **X-axis** represents the fold change value (often on a log scale).
  * For each cluster, a bar is shown composed of colored segments. Each segment corresponds to an original feature, with its color defined by the legend.
* **Interpretation:**
  * The position of a colored segment along the **X-axis** for a given cluster indicates the fold change of that feature in that cluster compared to a baseline (e.g., compared to the average across all other clusters).
  * Segments extending to the **right (positive fold change)** indicate features that have higher average values in that specific cluster compared to the baseline.
  * Segments extending to the **left (negative fold change)** indicate features that have lower average values in that specific cluster.
  * The magnitude of the fold change is represented by how far the segment extends along the X-axis.

<figure><img src="../../../.gitbook/assets/tSNE_CLustered t-SNE_ FoldChangePlot.png" alt="" width="375"><figcaption><p>Plot showing fold change of features across clusters</p></figcaption></figure>

* **Use:** Identify features that are significantly enriched (up-regulated) or depleted (down-regulated) within each specific cluster, providing insights into the biological characteristics that define each group.
{% endtab %}
{% endtabs %}
