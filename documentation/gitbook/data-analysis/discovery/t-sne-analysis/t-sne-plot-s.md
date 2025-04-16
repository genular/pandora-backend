---
description: >-
  Allows users to visualize the high dimensional data in a 2D plot after t-SNE
  analysis for trend identification
---

# t-SNE plot(s)

### Overview

The **t-SNE plot(s)** tab provides a t-SNE plot for just individuals, and t-SNE plots overlaying the grouping & coloring variables. These plots allow the user to identify trends and clustering within the dataset and investigate how features may correlate to these patterns.

<figure><img src="../../../.gitbook/assets/tSNE_tSNE Plots_highres-min_annotated.png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="1. Main plot" %}
The **main plot** is generated from t-SNE analysis that excludes the selected grouping variables. This graph simply shows the low-dimensional location of each data point (or individual) without any overlay of grouping or colored variables.&#x20;

This plot can be downloaded as SVG files or right-clicked and saved as a PNG in PANDORA.

<figure><img src="../../../.gitbook/assets/Normal_tSNE.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}

{% tab title="2. Grouping plots" %}
A **grouping plot** is generated for every selected grouping variable. Click on a grouping variable listed on the right side tabs to view its associated grouping t-SNE plot. The base analysis is the same as the main plot; the only difference is that now each outcome class is colored and overlaid on the plot for each individual.

These plots can be downloaded as SVG files or right-clicked and saved as a PNG in PANDORA.

<figure><img src="../../../.gitbook/assets/Grouped_tSNE.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}

{% tab title="3. Colored plots" %}
A **colored plot** is generated for every selected color variable. Click on a color variable listed on the left side tabs to view its associated colored t-SNE plot. The base analysis is the same as the main plot; the only difference is that now each dot is colored (in a gradient) based on the value associated with the color variable.

These plots can be downloaded as SVG files or right-clicked and saved as a PNG in PANDORA.

<figure><img src="../../../.gitbook/assets/Colored_tSNE.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}
{% endtabs %}
