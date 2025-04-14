---
icon: chart-scatter-bubble
---

# Discovery

The **Discovery** section provides tools for visualizing, clustering and exploring complex datasets. Use it to uncover patterns and relationships in biological data. The Discovery section is divided into six tabs, each focusing on a specific type of analysis.

{% tabs %}
{% tab title="Overview" %}
[**Data Overview**](data-overview.md) tab is offering a summary of your dataset and an initial look at data distributions.&#x20;

* **Table Plot**: Aggregates and visualizes the distribution patterns of multiple variables in a single figure, making it easier to spot overarching trends.
* **Distribution Plot**: Provides frequency and spread visuals for individual variables, which is useful for checking data ranges and identifying outliers.

#### Settings

* **Column Selection**: Choose which variables (columns) to include or exclude from visualizations, allowing you to focus on specific aspects of your data.
* **Preprocessing**: Simple options for preprocessing, such as normalization or handling missing values, to improve the accuracy of subsequent analyses.
* **Theme Settings**: Customize the look and feel of the visualizations to make patterns and trends more visually distinct.
{% endtab %}

{% tab title="Correlation" %}
[**Correlation** ](correlation.md)tab helps you understand relationships between different variables in your dataset.

* **Correlation Circle**: Shows correlations among variables in a circular format, allowing quick identification of strong positive or negative relationships.
* **Correlation Plot**: Displays a classic heatmap-style matrix, where darker shades represent stronger correlations.
* **Clustered Correlation Plot**: Groups similar variables, making it easy to identify clusters of related biomarkers or genes.

#### Settings

* **Preprocessing**: Options for handling missing data or normalizing variables, which can improve the quality of correlation analysis.
* **Correlation Settings**: Configure plot type (circle, heatmap), NA handling, and reordering based on correlation strength.
* **Significance Threshold**: Set a threshold to highlight only statistically significant correlations, helping to focus on biologically relevant relationships.
{% endtab %}

{% tab title="Clustering" %}
[**Hierarchical Clustering**](clustering.md) tab organizes data into clusters based on similarity.

* **Dendrogram**: A tree-like structure showing how different data points are grouped at various levels, revealing hierarchical relationships.
* **Heatmap**: Provides a color-coded intensity map of data distributions across clusters, allowing for visual comparison of clustered groups.

#### Settings

* **Clustering Settings**: Adjust the clustering algorithm, distance metric, and linkage method to refine cluster formation.
* **Display Options**: Customize the appearance of the heatmap and dendrogram for clear interpretation of clustering results.
{% endtab %}

{% tab title="PCA" %}
[**PCA Analysis**](pca-analysis.md) (Principal Component Analysis) reduces the complexity of high-dimensional data, highlighting the main components that contribute to variance in your dataset. PCA is particularly valuable for identifying key factors that differentiate cell types or experimental conditions.

* **Eigenvalues/Variances**: Displays the amount of variance each principal component explains, guiding you to the most informative components.
* **Variables and Individuals Plots**: Show the relationships among variables and individual data points in the principal component space.

#### Settings

* **Column Selection**: Select specific columns (variables) to include in PCA, focusing on those most relevant to your research.
* **Preprocessing Options**: Preprocess data to improve consistency in PCA results.
* **PCA Settings**: Choose the number of components to extract, balancing detail and interpretability.
* **Display Options**: Customize plots to suit analysis needs, making results more intuitive.
{% endtab %}

{% tab title="t-SNE" %}
[**t-SNE Analysis**](t-sne-analysis/) (t-distributed Stochastic Neighbor Embedding) is a technique for reducing dimensionality and visualizing high-dimensional data in a two-dimensional plot. This is particularly useful for visualizing clusters in complex data, like single-cell RNA sequencing results.

* **t-SNE Plot**: Reduces data to two dimensions and groups similar data points together, often forming clusters representing cell types or conditions.
* **Clustered t-SNE Analysis**: Applies clustering to the t-SNE plot, helping to identify and label clusters directly on the plot.

#### Settings

* **t-SNE Settings**: Customize parameters like perplexity and number of iterations for optimal visualization of clusters.
* **Cluster Settings**: Choose clustering algorithms and methods, configure the number of clusters, and set outlier detection.
* **Theme Settings**: Customize colors and plot styles for clear visual separation between clusters, aiding in pattern recognition.
{% endtab %}

{% tab title="UMAP" %}
[**UMAP Analysis**](umap.md) (Uniform Manifold Approximation and Projection) is another dimensionality reduction technique. It is designed to preserve more of the global structure in the data than t-SNE, making it useful for datasets where maintaining overall data structure is important.

* **UMAP Visualization**: Creates a two-dimensional representation where similar data points are closer together, helping to identify meaningful groups.
* **Training and Testing Splits**: Supports supervised UMAP, allowing you to partition data into training and testing sets for predictive analysis.

#### Settings

* **Column Selection**: Specify which variables to include in the UMAP calculations.
* **Grouping Variable**: Select a categorical variable to group data points in the UMAP plot, which will be excluded from UMAP analysis itself.
* **Preprocess and Remove NA**: Options for handling missing values to ensure data consistency.
* **Partition Split**: Set a training/testing split for supervised analysis, allowing UMAP to learn group distinctions.
* **Theme and Style Customization**: Adjust themes, colors, font sizes, and aspect ratios for visually distinct plots that aid in biological interpretation.
{% endtab %}
{% endtabs %}
