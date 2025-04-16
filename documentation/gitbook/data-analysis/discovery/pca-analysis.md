---
description: Helping to reduce dimensionality and visualize relationships.
---

# PCA Analysis

### Overview

The **PCA Analysis** tab provides tools for dimensionality reduction and exploratory data analysis.

<figure><img src="../../.gitbook/assets/PCA_main_Highres_annotated-min.png" alt=""><figcaption><p>Main overview</p></figcaption></figure>

{% tabs %}
{% tab title="1. PCA Setup" %}
For generic setup steps and preprocessing options, please see the [Side Panel Options](side-panel-options.md) page. Information about the settings unique to PCA setup is provided below:

* **Grouping Variable**: Select a variable to use for grouping. This variable won’t impact PCA computation but will be used for plotting.
  * Selecting a grouping variable allows users to investigate if the PCA suggests that individuals with similar grouping variable values tend to cluster in the reduced dimensional space.
* **X and Y Axes**: Choose which principal components to display on the X and Y axes. Defaults to dimension 1 and dimension 2 for X and Y, respectively.
* **KMO/Bartlett Column Limit**: Set a column limit for performing Kaiser-Meyer-Olkin and Bartlett tests. If the data contains more columns than this limit, these tests will not be performed.
* **Analysis Method**: Choose between PCA for numerical variables or MCA for categorical ones.
* **Display Loadings**: Enable this option to show variable loadings on the plot.
* **Ellipse Alpha**: Set the transparency level of ellipses for grouping.
* **Remove Ellipse**: Toggle to remove or add concentration ellipses and confidence ellipses around groupings for individuals in the reduced dimensional space.
  * When toggled on, ellipses are present; when toggled off, ellipses are no longer present.
{% endtab %}

{% tab title="2. Analysis Options" %}
After running PCA, on the right of the side panel, the user will see results for several analyses.

* [**Bartlett's Sphericity**](pca-analysis/bartletts-sphericity.md): Provides results for Bartlett's Test of Sphericity and Kaiser-Meyer-Olkin (KMO) Index Test for user to assess suitability of the dataset for PCA.
* [**Eigenvalues / Variances**](pca-analysis/eigenvalues-variances.md): View eigenvalues and variances to understand the significance of each principal component.
* [**Variables**](pca-analysis/variables.md): Provides information on the relationship between the dataset variables and the principal components, the quality of variable representation in the principal components, and how much the variables contribute to the formation of principal components.&#x20;
* [**Individuals**](pca-analysis/individuals.md):Provides information on the relationship between the individuals in the dataset and the principal components, the quality of each individual's representation in the principal components, and how much the individuals contribute to the formation of principal components.&#x20;
* [**PCA Output**](pca-analysis/pca-output.md): Displays a snippet of detailed PCA results.
{% endtab %}
{% endtabs %}



