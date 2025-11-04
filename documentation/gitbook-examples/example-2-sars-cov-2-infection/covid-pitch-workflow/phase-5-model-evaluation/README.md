---
description: >-
  In this phase, we will evaluate and assess model performance with statistical
  methods and explainable AI techniques.
hidden: true
icon: square-poll-vertical
---

# Phase 6: Model evaluation

Assess and compare model performance using statistical metrics like AUC, and explainable AI techniques to understand model predictions. This allows for identification of the most reliable models and extraction of biologically meaningful insights from models.

<details>

<summary>1) Select models for evaluation </summary>

1. Navigate to the **Dashboard** and select your predictive analysis from the queue
   1. The queue number selected is indicated in the pink box at the top right of the PANDORA interface.
2. Navigate to **Predictive** -> [**Exploration**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration)

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-27 123150.png" alt=""><figcaption></figcaption></figure>

3. Configure the exploration space:
   1. Select all Response outcomes
   2. Select metrics of interest
   3. Select dataset
   4. Select models to evaluate

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-27 130436.png" alt=""><figcaption></figcaption></figure>

For this example, we will select at the top three models, `cforest`, `rFerns` and `sparseLDA`, and evaluate their performance&#x20;

</details>

<details>

<summary>2) Evaluate model performance </summary>

**Tabular comparison of metrics**&#x20;

1. The models can be compared by choosing metrics when configuring the exploration space (3.b in previous step) and viewing them in the table seen in 3.d from the previous step. Looking at `Training AUC` (Area under the ROC curve) is recommended. Find more information about these metrics [here](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration).&#x20;

**ROC curves** provide vital information about model performance with both training and testing datasets.&#x20;

1. To view and compare ROC curves for a model, chose your desired model(s) select the [**ROC Curve Analysis**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration/roc-curve-analysis) in Exploration&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-27 134609 (1).png" alt=""><figcaption></figcaption></figure>

2. Observe the shape of the ROC curve and the AUC for each classification category (high or low responder) by clicking on the graph to expand.
   1. If choosing multiple models, select the model name to view its ROC curve&#x20;
   2. Compare curves of multiple models by selecting the **Comparison** tab&#x20;

Ideally, AUC scores to equal 1 or very close to 1 are preferred. Furthermore, you want the testing AUC to be higher than the training AUC as that confirms the model is able to **classify accurately on unseen data**.&#x20;

Below, we can seen the ROC curves for both train and test datasets fit these criteria for sparseLDA. For more details on how to analyze ROC curves and AUC scores, see the subpage [**How to evaluate the model?** ](how-to-evaluate-the-model.md)

<div><figure><img src="../../../.gitbook/assets/CP_sparseLDA training roc-auc.png" alt=""><figcaption></figcaption></figure> <figure><img src="../../../.gitbook/assets/CP_sparseLDA testing roc-auc.png" alt=""><figcaption></figcaption></figure></div>

Along with ROC curves and AUC, there are other important metrics that help determine whether a model is good for answering the specific research question. Many of these metrics are derived from a **confusion matrix**.

1. To view these metrics, choose **two or more models** and navigate to the [**Training summary**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration/training-summary) tab in Exploration&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-27 134812 (1).png" alt=""><figcaption></figcaption></figure>

a. View the **box plots** to compare various metrics related to the models' performance. The example below is comparing the measurements for the models `cforest`, `rFerns` and `sparseLDA` . Further details on each of these metrics can be found in our [documentation](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration/model-metrics)

<figure><img src="../../../.gitbook/assets/CP_predictive model training summary.png" alt=""><figcaption></figcaption></figure>

b. Scrolling down, you can view the **Performance measurements** to determine if there are significant differences between model metric values.

c. The **Model fitting results summary** beside the performance measurements provides the five-number summary of each model that is visualized in the box plots.

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-27 134835.png" alt=""><figcaption></figcaption></figure>

</details>

<details>

<summary>3) Identify key early predictors </summary>

We can identify early predictors using PANDORA's [**Variable Importance**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration/variable-importance) feature, where explainable AI is used to assign a score to the predicting features based on how important the model considered that feature in its classification task. A higher score indicates higher importance.&#x20;

1. Choose your best model and select the **Variable Importance** tab in Exploration&#x20;
   1. Depending on your purpose, such as getting a generalized view of features agreed upon by multiple models, you can choose the top few models to explore their variable importance.&#x20;
   2. The example below follows looking at variable importance for the models `cforest`, `rFerns` and `sparseLDA`&#x20;
2. Select the **Variable Importance** sub-tab with the main Variable Importance tab

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-27 134954.png" alt=""><figcaption></figcaption></figure>

<figure><img src="../../../.gitbook/assets/CP_predictive model variable importance.png" alt=""><figcaption></figcaption></figure>



<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-27 135020.png" alt=""><figcaption></figcaption></figure>

<figure><img src="../../../.gitbook/assets/CP_feature violin plot.png" alt=""><figcaption></figcaption></figure>

</details>

<details>

<summary>4) Interpret model behavior </summary>



</details>
