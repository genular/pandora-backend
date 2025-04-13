---
description: >-
  Allows user to investigate how the variables contribute to the principal
  component analysis (PCA).
---

# Variables

### Overview

The **Variables** tab in PANDORA provides valuable insights on the correlation, quality, and contributions of each variable in the principal component analysis.

<figure><img src="../../../.gitbook/assets/PCA_Variables_Notated.png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="1. Correlation circle(s)" %}
This sub-tab provides correlation circle plots of all variables in a non-clustered and clustered form. These plots can be downloaded as SVG files or right-clicked and saved as a PNG in PANDORA.

#### a. Correlation plot

Provides a correlation circle for all variables with coloring based on the cos2 value for each variable. Learn more about correlation circles on the [PCA Analysis](../pca-analysis.md) page.

<figure><img src="../../../.gitbook/assets/Correlation Circle_Correlation Plot.png" alt="" width="375"><figcaption></figcaption></figure>

#### b. Correlation plot clustered

Provides a correlation circle for all variables, but with clustering groups overlayed. Each cluster is represented by a different color and is determined by the kmeans clustering algorithm.

<figure><img src="../../../.gitbook/assets/Correlation Circle_Correlation Plot Clustered.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}

{% tab title="2. Quality of representation" %}
Provides graphical information on how well each variable is represented on the primary principal components. The plots below can be downloaded as SVG files or right-clicked and saved as a PNG in PANDORA.

#### Correlation plot

The correlation plot shows how well each variable (listed on the side) is represented in each dimension (listed at the top). A dark red dot indicates greater representation of a variable in the associated principal component, and a dark blue dot corresponds to poor representation. The associated cos2 value for each color is shown on the right side bar.

<figure><img src="../../../.gitbook/assets/Quality of representation_Correlation plot.png" alt="" width="375"><figcaption></figcaption></figure>

#### Bar plot

This bar plot shows the cos2 value associated with each variable. A high cos2 indicates good representation on the principal components, and so the corresponding variable would be shown further from the origin in the correlation circle. A variable with a low cos2 is poorly represented on the principal components, and would be shown closer to the origin in the correlation circle.

<figure><img src="../../../.gitbook/assets/Quality of representation_Bar plot.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}

{% tab title="3. Contribution of variables to PCs" %}
This sub-tab provides information on how much the variables contribute to the variance in the principal components. The plots below can be downloaded as SVG files or right-clicked and saved as a PNG in PADNORA.

#### Correlation plot

The correlation plot shows how well each variable (listed on the side) is represented in each dimension (listed at the top). A dark red dot indicates greater variance contribution from the variable in the associated principal component, and a dark blue dot corresponds to poor variance contribution. The percent contribution to variability in the principal component is shown on the right side bar.

<figure><img src="../../../.gitbook/assets/Contribution of variables to PCs_Correlation plot.png" alt="" width="375"><figcaption></figcaption></figure>

#### Bar plot

Shows the top 10 variables that contribute to the variance of the principal components

<figure><img src="../../../.gitbook/assets/Contribution of variables to PCs_Bar plot.png" alt="" width="375"><figcaption></figcaption></figure>

#### Correlation circle

Provides a correlation circle for all variables with coloring based on the variance contribution for each variable. Learn more about correlation circles on the [PCA Analysis](../pca-analysis.md) page.

<figure><img src="../../../.gitbook/assets/Contribution of variables to PCs_Correlation circle.png" alt="" width="375"><figcaption></figcaption></figure>

#### Dimension description

A terminal output for all quantitative variables that gives the correlation value and its associated p-value for principal component one.
{% endtab %}
{% endtabs %}
