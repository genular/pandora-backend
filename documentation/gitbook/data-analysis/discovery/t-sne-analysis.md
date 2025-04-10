# t-SNE Analysis

### Overview

The **t-SNE Analysis** tab supports both standard and clustered t-SNE visualizations.

<figure><img src="../../.gitbook/assets/discovery-tsne.png" alt=""><figcaption></figcaption></figure>

### Key Functionalities

#### 1. Column Selection

* **Columns**: Choose specific columns for t-SNE analysis. If left empty, all numerical columns are included, except those specified in "Exclude Columns."
* **First (n) Columns**: Specify the number of columns for analysis when no specific columns are selected, with a range from 2 to 50,000.
* **Exclude Columns**: Select columns to exclude from analysis.

#### 2. Grouping and Color Options

* **Grouping Variable**: Select a categorical variable to group data points by color on the t-SNE plot. This variable is excluded from the analysis but used for visualization.
* **Color Variable**: Choose a continuous variable for coloring the t-SNE plot. Unlike the grouping variable, this column is included in the analysis.

#### 3. Clustering Settings

* **Clustering Algorithm**: Choose the clustering algorithm, such as Louvain, Hierarchical, Mclust, or Density-based clustering.
* **Clustering Method**: Select the clustering method for hierarchical clustering, including options like Ward.D2, average, complete, etc.
* **epsQuantile**: Set the quantile used for the `eps` parameter in DBSCAN clustering. Higher values increase the neighborhood size for clustering.
* **Exclude Outliers**: Toggle whether to include or exclude outliers in the clustering.
* **Cluster Groups**: Define the number of clusters (for Hierarchical and Mclust algorithms).

#### 4. t-SNE Settings

* **Perplexity**: Adjust the perplexity, affecting how many neighbors each point considers. Suitable values range from 5 to 50, depending on the dataset.
* **Exaggeration Factor**: Set a factor to increase or decrease the separation between clusters. Typical values are between 4 and 30.
* **Theta**: Choose a theta value to control the accuracy/speed trade-off for the t-SNE approximation.
* **Max Iterations**: Define the maximum number of iterations for the t-SNE algorithm, up to 50,000.
* **Eta**: Set the learning rate, controlling the step size in the t-SNE optimization.

#### 5. Dataset Settings

* **Preprocessing**: Apply preprocessing steps such as "center," "scale," "medianImpute," and "remove zero-variance features" before running t-SNE.
* **Remove NA**: Enable this option to drop rows with missing values before processing.
* **Dataset Analysis Type**: Select the analysis type, such as heatmap or hierarchical clustering.
* **Grouped Display**: Display the mean values of clusters on a heatmap.
* **Remove Outliers for Downstream Analysis**: Choose whether to remove outliers for downstream analyses like machine learning.

#### 7. Analysis and Download Options

* **Auto t-SNE Settings**: Automatically compute t-SNE settings based on dataset characteristics.
* **Download Plot**: Save plots as SVG files for further analysis or reporting.

### Clustered t-SNE Analysis

The **Clustered t-SNE Analysis** view offers an enhanced visualization by applying clustering methods to the t-SNE plot. Users can examine:

* **Clusters**: View clusters identified in the t-SNE plot.
* **Features**: Visualize mean feature values within each cluster.
* **FoldChange**: Observe fold changes in features across clusters.

