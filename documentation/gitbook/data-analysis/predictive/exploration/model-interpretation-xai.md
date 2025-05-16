---
description: >-
  Allows users to perform a variety of analyses to interpret features and their
  contributions to the model's performance.
icon: diagram-project
---

# Model interpretation - xAI

<figure><img src="../../../.gitbook/assets/Prediction_Model Interpretation_Main_annotated_v2.png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="1. Setup analyses" %}
Users can perform multiple analyses with select features to investigate their contributions to the model. Aside from display settings, which are explained on the[ side panel options](../../discovery/side-panel.md) page, users have two main settings for running these analyses:

* **Vars:** Selects the features to use in the analysis (if applicable).
* **Analysis:** Choose the analyses to perform on the selected features and generate plots for each.

#### Types of Analysis:

1. **Scatter Plot:** Visualize the relationship between two variables by displaying them as points distributed across a Cartesian plane. They help illustrate how changes in feature values could affect the model's output.
   * Select two **variables** to compare in this analysis
2. **Heatmap:** Depicts the interactions between two features by coloring cells according to the model’s output for combinations of feature values, showing how joint variations influence the prediction.
   * Select **two variables** for this analysis
3. **ICE Plot** (Individual Conditional Expectation): Visualize the change in the prediction outcome as a feature varies while all other features are held constant, highlighting the marginal effect of each feature
   1. Select one **variable** to vary in this analysis
4. **LIME Plot** (Local Interpretable Model-agnostic Explanations): Explain individual predictions by showing which features were most influential, helping to demystify the model’s behavior on a case-by-case basis.
   * Plots the most influential variables that best explain the individual predictions
   * &#x20;Green bars indicate that a variable causes an increase in the probability (supports) the model. Red bars indicate that a variable causes a decrease in the probability (contradicts) the model.
   * Explanation Fit: Measure of how well the linear LIME model matches the region
5. **Feature Importance:** Illustrates the importance of each feature in the predictive model, showing which features have the most significant impact on the model's predictions.
6. **Interactive Effects:** Shows the interaction effects between features, highlighting how the combination of different features affects the model's output.
7. **ALE Plot** (Accumulated Local Effects): Visualize how features impact the prediction on average, focusing on how the model’s output changes when a feature varies over its distribution
8. **PDP**  (Partial Dependence Plots) **& ICE** (Individual Conditional Expectation) Plot: Show both average and individual feature effects on the model's prediction
   1. Select variables to compare.

<figure><img src="../../../.gitbook/assets/Model Interpretation_PDP and ICE.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}

{% tab title="2. Display options" %}
When a user runs analyses, they will be run for all the currently selected models and all the selected analyses. This is computationally expensive, so select only a few models and analyses at a time for best results. Once results are generated, the user can toggle which results to view.

* **Select Model:** At the top of the plot, select the model for which to view the analysis results.
* **Select Analysis:** On the right side-bar, select the analysis for which to view the resulting plot.
{% endtab %}
{% endtabs %}

