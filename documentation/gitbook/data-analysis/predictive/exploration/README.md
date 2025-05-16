---
description: >-
  Enables users to explore the results of machine learning models by selecting
  metrics and utilizing built-in analysis tools.
icon: chart-scatter
---

# Exploration

<figure><img src="../../../.gitbook/assets/Exploration_Main_Highres_annotated-min.png" alt=""><figcaption><p>Main overview</p></figcaption></figure>

{% tabs %}
{% tab title="Data Configuration" %}
There are several options for configuring the data to prepare it for exploring the results of the predictive models:&#x20;

* **Metric Selection:** Choose from a variety of metrics to display for your dataset. Metrics available will change depending on the associated outcomes selected.
* **Dataset Selection:** Select the dataset of interest to explore the results of its associated machine learning models.
  * Users can also download .csv files for each resampled data, training data, and testing data.
* **Model Selection:** Select machine learning models from the dataset to explore and compare results.
  * Users can also download the Rdata for each selected model at this step.
{% endtab %}

{% tab title="Analysis Options" %}
PANDORA provides a variety of tools to analyze the results of your predictive models along with its performance:&#x20;

* [**Variable Importance**](variable-importance.md)**:** Allows for assessment of feature contributions to model variance and visualization of feature value distribution for each outcome. This can reveal the top contributing features in the model for further investigation.
* [**Training Summary:**](training-summary.md) Provides whiskerplot comparison of training performance metrics between the selected models.
* [**ROC Curve Analysis:**](roc-curve-analysis.md) Provides a graphical representation for evaluating binary classification performance in models from both training and testing.
* [**Model Interpretation:**](model-interpretation-xai.md) Allows for investigation of feature impact on model performance through a variety of analysis options.
{% endtab %}
{% endtabs %}

