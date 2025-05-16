---
description: >-
  Provides users an easy way and visual way to assess diagnostic capabilities of
  their machine learning models
icon: chart-line
---

# ROC curve analysis

**What are ROC Curves (Training & Testing) Plots:**

* A **ROC (Receiver Operating Characteristic) curve** is a graph.
* It plots the **True Positive Rate (Sensitivity/Recall)** on the y-axis against the **False Positive Rate (1 - Specificity)** on the x-axis, at various classification thresholds.
  * **Training ROC:** Shows this performance on the data the model was trained on.
  * **Testing ROC:** Shows this performance on new, unseen (test/validation) data.

**How This Helps:**

1. **Visualizes performance:**
   * A curve closer to the **top-left corner** means better performance (high true positives, low false positives).
   * The **Area Under the Curve (AUC)** is a single number summarizing this: 1.0 is perfect, 0.5 is like random guessing.
2. **Detects overfitting:**
   * **Crucially, you compare the two curves.**
   * If the **Training ROC is much better** (further top-left, higher AUC) than the **Testing ROC**, your model is likely **overfitting**. It performs well on data it's seen but poorly on new data. The Testing ROC shows its true generalization ability.
3. **Threshold independent view:** It shows how well the model separates classes regardless of which specific probability cut-off you choose to make a final classification.

In short: ROC curves (especially comparing train vs. test) help you see how well your model distinguishes between classes and diagnose if it's just memorizing the training data (overfitting) or actually learning generalizable patterns.

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

