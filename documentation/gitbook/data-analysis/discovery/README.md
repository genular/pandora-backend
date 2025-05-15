---
icon: chart-scatter-bubble
---

# Discovery

The **Discovery** section in PANDORA offers a set of tools to help you get to know your biomedical datasets. It's designed for initial data exploration, visualization, and finding underlying patterns. Using these tools first can help you understand your data's characteristics, spot potential relationships, and form hypotheses before you move on to more complex modeling.

Key goals when using the Discovery tools:

* **Get familiar with your data:** Use the **Data Overview** to check the structure of your dataset, how your variables are distributed, and the overall data quality.
* **Assess relationships:** The **Correlation** tool helps you measure and visualize how different variables in your dataset relate to each other.
* **Find patterns:** Identify natural groupings and structures within your data using unsupervised methods:
  * **Hierarchical Clustering:** Groups similar samples or features based on their values.
  * **PCA Analysis (Principal Component Analysis):** Simplifies complex data by finding the main sources of variation, helping you visualize these in lower dimensions.
  * **t-SNE Analysis and UMAP:** Visualize high-dimensional data (like genomics or proteomics) in 2D or 3D plots to reveal clusters and non-linear relationships that might not be obvious otherwise.

Each tab within this section is dedicated to a specific analytical approach, allowing for a systematic exploration of your data.

{% tabs %}
{% tab title="Overview" %}
Use the **Data Overview** tab to get a quick summary of your dataset and explore initial data distributions.

#### Available Plots

* **Table Plot:** Visualize distribution patterns for multiple variables together in a single figure. This helps you spot broader trends across your data.
* **Distribution Plot:** Examine the frequency and spread for individual variables. Use this to check data ranges and identify potential outliers.

#### Settings

Customize your overview using these options:

* **Column Selection:** Choose which variables (columns) you want to include or exclude from the plots. This lets you focus on specific parts of your data.
* **Preprocessing:** Apply simple preprocessing steps directly within the tab, such as normalization or handling missing values, before generating visualizations.
* **Theme Settings:** Change the visual appearance (like colors and styles) of your plots to make patterns easier to see.
{% endtab %}

{% tab title="Correlation" %}
Use the **Correlation** tab to find relationships between different variables in your dataset.

#### Available Plots

* **Correlation Circle:** Visualize correlations in a circular layout. Quickly spot strong positive or negative relationships between variables.
* **Correlation Plot:** Show correlations using a standard heatmap matrix. Colors indicate the strength and direction of the correlation.
* **Clustered Correlation Plot:** Group variables with similar correlation patterns together. This helps identify clusters of related features (like biomarkers or genes).

#### Settings

Adjust how correlations are calculated and displayed:

* **Preprocessing:** Apply simple data cleaning steps like handling missing values (NAs) or normalizing data before calculating correlations.
* **Correlation Settings:**
  * Choose the plot type (Circle, Heatmap, Clustered Heatmap).
  * Select how to handle missing values during calculation.
  * Reorder variables based on correlation strength or clustering.
* **Significance Threshold:** Set a p-value threshold (e.g., 0.05) to only show statistically significant correlations in the plots. This helps you focus on meaningful relationships.
{% endtab %}

{% tab title="Clustering" %}
Use the **Hierarchical Clustering** tab to group your data points (like samples or genes) based on their similarity.

#### Available Plots

* **Dendrogram:** View a tree diagram that shows how data points are merged into clusters. This helps you understand the hierarchy and relationships within your data.
* **Heatmap:** See a color-coded grid of your data, often displayed alongside the dendrogram. Rows and columns are reordered based on the clustering, making it easy to visually compare patterns within and between clusters.

#### Settings

Configure the clustering process and visualization:

* **Clustering Settings:**
  * Choose the distance metric (e.g., Euclidean, Manhattan) to define how similarity between data points is measured.
  * Select the linkage method (e.g., Ward, Complete, Average) to determine how clusters are merged.
* **Display Options:** Customize the appearance of the dendrogram and heatmap (like colors, labels, orientation) for better readability and interpretation.
{% endtab %}

{% tab title="PCA" %}
Use **Principal Component Analysis (PCA)** to simplify high-dimensional data. PCA finds the main sources of variation (principal components) in your dataset, making it easier to see patterns and differences, for example, between cell types or experimental conditions.

#### Available Plots

* **Eigenvalues/Variances Plot (Scree Plot):** Shows how much variance each principal component captures. Use this to decide how many components are important to look at.
* **Variables Plot (Correlation Circle):** Visualizes how the original variables contribute to the principal components. Helps identify which variables drive the separation you see.
* **Individuals Plot (Scatter Plot):** Shows where your individual samples or data points fall in the reduced principal component space. Useful for spotting clusters or outliers based on the main variance components.

#### Settings

Configure the PCA calculation and output:

* **Column Selection:** Choose which variables (columns) to include in the PCA. Focus the analysis on relevant features.
* **Preprocessing Options:** Apply standard preprocessing steps like scaling (standardizing) variables before PCA. This is often recommended to prevent variables with large values from dominating the analysis.
* **PCA Settings:** Specify the number of principal components to calculate and display.
* **Display Options:** Customize the appearance of the PCA plots (like point colors, labels) for clearer results.
{% endtab %}

{% tab title="t-SNE" %}
Use **t-distributed Stochastic Neighbor Embedding (t-SNE)** to visualize high-dimensional data in a low-dimensional space (usually 2D). t-SNE is great for revealing underlying clusters or groups within complex datasets, such as identifying cell populations in single-cell RNA-seq data.

#### Available Plots

* **t-SNE Plot:** Displays your data points in two dimensions. Points that are similar in the original high-dimensional space will tend to group together in the t-SNE plot.
* **Clustered t-SNE Plot:** Runs a clustering algorithm (like k-means or DBSCAN) on the 2D t-SNE coordinates and colors the points according to their assigned cluster. This helps automatically identify and label groups directly on the visualization.

#### Settings

Fine-tune the t-SNE algorithm and the resulting visualization:

* **t-SNE Settings:**
  * **Perplexity:** Adjust this parameter (related to the number of nearest neighbors considered for each point) to control the balance between local and global aspects of your data. Typical values are between 5 and 50.
  * **Iterations:** Set the number of iterations for the optimization process. More iterations can lead to a more stable layout but take longer.
  * Other parameters like learning rate (`eta`) might also be available.
* **Cluster Settings (for Clustered t-SNE):**
  * Choose a clustering algorithm (e.g., k-means, DBSCAN).
  * Configure algorithm-specific parameters (like the number of clusters `k` for k-means, or `eps` and `minPts` for DBSCAN).
  * Optionally enable outlier detection if supported by the chosen algorithm.
* **Theme Settings:** Customize plot aesthetics like point colors, sizes, and labels to make the clusters visually distinct and easier to interpret.
{% endtab %}

{% tab title="UMAP" %}
Use **Uniform Manifold Approximation and Projection (UMAP)** for dimensionality reduction and visualization. Like t-SNE, it helps visualize high-dimensional data in 2D, but UMAP often preserves more of the data's global structure. This is useful for understanding the overall relationships between groups in your data.

#### Key Features

* **UMAP Visualization:** Generates a 2D plot where similar data points are placed close together, revealing potential clusters and relationships.
* **Supervised UMAP:** You can provide known labels (like experimental conditions or cell types) to guide the UMAP projection, potentially improving separation between known groups. This often involves splitting data into training and testing sets.

#### Settings

Configure the UMAP analysis and visualization:

* **Column Selection:** Choose which variables (columns) to use for calculating the UMAP embedding.
* **Grouping Variable:** Select a categorical variable (e.g., 'treatment', 'cell\_type') to color the points in the UMAP plot. **Note:** This variable is used only for visualization _after_ UMAP is calculated; it does not influence the dimensionality reduction unless used in Supervised UMAP.
* **Preprocessing:**
  * **Remove NA:** Handle missing values before running UMAP.
  * (Optional) Scaling/Normalization might be available depending on the implementation.
* **UMAP Parameters:**
  * Adjust parameters like `n_neighbors` (number of neighbors to consider, affects local vs. global balance) and `min_dist` (minimum distance between points, controls cluster density). Experimenting with these is key to getting a good visualization.
* **Partition Split (for Supervised UMAP):** If using supervised UMAP, set the proportion of data to use for training vs. testing. UMAP learns the structure based on the labels in the training set.
* **Theme and Style Customization:** Change colors, point sizes, font sizes, and plot aspect ratios to create clear and interpretable visualizations.
{% endtab %}
{% endtabs %}
