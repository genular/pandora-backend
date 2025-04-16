---
description: >-
  Allows users to perform a variety of analyses to interpret features and their
  contributions to the model's performance.
---

# Model Interpretation

### Overview

The **Model Interpretation** tab in PANDORA offers a powerful suite of analysis tools to investigate feature contributions to the predictive models. Users can select the analyses of interest to generate informative visual plots for improved understanding of feature influence in model performance.

<figure><img src="../../../.gitbook/assets/Exploration_Model Interpretation_Medres_annotated-min.png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="1. Setup analyses" %}
Users can perform multiple analyses with select features to investigate their contributions to the model. Aside from display settings, which are explained on the[ side panel options](../../discovery/side-panel-options.md) page, users have two main settings for running these analyses:

* **Vars:** Selects the features to use in the analysis (if applicable).
* **Analysis:** Choose the analyses to perform on the selected features and generate plots for each.
{% endtab %}

{% tab title="2. Display options" %}
When a user runs analyses, they will be run for all the currently selected models and all the selected analyses. This is computationally expensive, so select only a few models and analyses at a time for best results. Once results are generated, the user can toggle which results to view.

* **Select Model:** At the top of the plot, select the model for which to view the analysis results.
* **Select Analysis:** On the right side-bar, select the analysis for which to view the resulting plot.
{% endtab %}
{% endtabs %}

