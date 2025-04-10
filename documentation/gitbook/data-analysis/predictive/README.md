---
icon: brain-circuit
---

# Predictive

The **Predictive** section allows users to create predictive models and explore the underlying features behind their performance. It provides a suite of tools to assess and compare model performance as well as provide insights on feature contributions. The Predictive Section can be broken into two primary tabs, one focused on predictive model creation, and the other focused on exploring model performance

{% tabs %}
{% tab title=" 1. SIMON (Machine Learning)" %}
[**Machine Learning**](simon/) tab is your starting point, providing a variety of tunable properties to streamline the process of developing and running your predictive models.

#### Settings

* **Analysis Properties:** Simple options to define analysis type, predictive and response variables, dataset partition, preprocessing, and more for model training and analysis.
* **Model Selection:** Filter and choose from a variety of machine learning packages for your analysis.
* **Advanced Options:** Enable advanced features to reduce dimensionality, prevent lengthy computations, or combine features from different models.
{% endtab %}

{% tab title="2. Exploration" %}
[**Exploration** ](exploration/)tab provides a suite of tools to easily assess model performance, and explain model performance through Explainable AI analyses.

#### Model Performance

* **Performance Metrics:** Multiple metrics, such as accuracy, predictive AUC, and training AUC, are provided to assess the performance of your predictive models.
* [**Training Summary:** ](exploration/training-summary.md)Provides box plots for a visual comparison of model performance for each performance metric.

#### Explainable AI

* [**Variable Importance:** ](exploration/variable-importance.md)Understand how much each feature contributes to the variance of your predictive model.
* [**ROC Curve Analysis:**](exploration/roc-curve-analysis.md) Provides a visual understanding of the predictive models' diagnostic capabilities for both the training and testing datasets.
* [**Model Interpretation:**](exploration/model-interpretation.md) Perform a variety of analyses to uncover feature interactions and contributions to model performance.
{% endtab %}
{% endtabs %}
