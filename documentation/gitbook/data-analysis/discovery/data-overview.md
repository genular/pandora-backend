---
description: Used to examine structure and contents of dataset
---

# Data Overview

### Overview&#x20;

The **Data Overview** tab in PANDORA offers  preliminary data inspection, allowing users to filter, preprocess, and visualize columns before diving into analysis.

<figure><img src="../../.gitbook/assets/discovery-data-overview-tabls-plot.png" alt=""><figcaption><p>Main overview</p></figcaption></figure>

{% tabs %}
{% tab title="Table Plot" %}
This plot visualizes the data in a tabular format, allowing users to examine aggregated distribution patterns across multiple variables.



<figure><img src="../../.gitbook/assets/image (8).png" alt=""><figcaption><p><strong>Table Plot</strong></p></figcaption></figure>
{% endtab %}

{% tab title="Distribution Plot" %}
Displays the distribution of values in selected columns, which helps in identifying skewness, outliers, and patterns in the data.

<figure><img src="../../.gitbook/assets/image (9).png" alt=""><figcaption><p><strong>Distribution Plot</strong></p></figcaption></figure>
{% endtab %}
{% endtabs %}

**Download Options**: Users can download the raw data and plot images for offline analysis. Images are available in SVG format for scalability.

[**Side Panel Options**](side-panel-options.md): Users can choose specific columns of the dataset to visualize, along with modifying themes and plot colors to match their preferences&#x20;

**Dynamic Tab Control**:

* The tab will only be enabled if there is a sufficient amount of data in the selected file, preventing empty visualizations and optimizing performance.

**Bottom Bar Details**:

* Shows additional details about selected columns, including:
  * Unique values count.
  * Whether the column is numeric (for PCA suitability).
  * Zero variance indication.
  * Percentage of missing values (NA).
