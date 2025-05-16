---
description: Compare performance metrics for your machine learning models.
icon: chart-line
---

# Training summary

Summary of performance metrics for the selected predictive models.

<figure><img src="../../../.gitbook/assets/Exploration_Training Summary.png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="1.  Comparison" %}
The **Comparison of model performance measurements** sub-tab provides box plots for each model training metric to allow visual comparison. The box plots show the distribution of data and skewness for each model selected in the comparison. Two or more models must be selected from the dataset to view the "Training Summary" tab.

The box plots can be downloaded as SVG files or right-clicked and saved as a PNG in PANDORA.

<figure><img src="../../../.gitbook/assets/Training Summary_Comparison of models.png" alt=""><figcaption></figcaption></figure>
{% endtab %}

{% tab title="2. Performance measurements" %}
The **Performance measurements** section compares model performance for each metric by providing tables. The upper diagonals show mean performance across models, and the lower diagonals show Bonferroni‐adjusted p‐values.

Save the results for Performance measurements by clicking the copy button in PANDORA and pasting into a separate file.
{% endtab %}

{% tab title="3. Model fitting results summaries" %}
The **Model fitting result summaries** summarize model performance data in tables for each metric. Each table lists the selected models as rows and the five-number summary of each model's dataset in the columns.

Save the results for Model fitting result summaries by clicking the copy button in PANDORA and pasting into a separate file.
{% endtab %}
{% endtabs %}
