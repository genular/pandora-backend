---
description: >-
  Provides users an easy way and visual way to assess diagnostic capabilities of
  their machine learning models
---

# ROC Curve Analysis

### Overview

The **ROC Curve Analysis** tab in PANDORA provides a clear interface for visualizing the classification performance of predictive models. Its intuitive design allows users to easily compare individual or multiple models at once, and provides comprehensive customization options for ROC Curve visualization.



<figure><img src="../../../.gitbook/assets/ROC curve_Main_annotated_v2.png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="1. ROC curves" %}
The **ROC curves** provide a graphical representation of the trade-off between true positive and false positive rates. ROC curves provide valuable insights into model performance and can be helpful when comparing models. A good ROC curve is one that curves close to the top-left corner, indicating a balance of sensitivity and specificity.

* **Training ROC curve:** Shows the model's ability to correctly classify outcomes within the training dataset.

<figure><img src="../../../.gitbook/assets/Training_auc_roc_cforest.png" alt="" width="375"><figcaption></figcaption></figure>

* **Testing ROC curve:** Demonstrates the model's performance on correctly classifying outcomes with the unseen testing dataset.

<figure><img src="../../../.gitbook/assets/Testing_auc_roc_cforest.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}

{% tab title="2. Display Options" %}
Users can select the model to display the ROC curve for in both training and testing, and can choose to display an ROC curve for all or one model at a time.

* **One-vs-All:** This display setting allows users to select one model to display an ROC curve for at a time, and a curve will be provided for all classification outcomes.
  * Select the model to display by clicking the tab for the desired model located directly above the ROC curve.

<figure><img src="../../../.gitbook/assets/Testing_auc_roc_cforest.png" alt="" width="375"><figcaption></figcaption></figure>

* **Comparison**: This display setting allows users to view ROC curves of all selected models on one graph.

<figure><img src="../../../.gitbook/assets/ROC Curve_Comparison_v2.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}
{% endtabs %}

