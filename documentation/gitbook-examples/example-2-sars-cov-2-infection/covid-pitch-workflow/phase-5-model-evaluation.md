---
description: >-
  In this phase, we will evaluate and assess model performance with statistical
  methods and explainable AI techniques.
hidden: true
icon: square-poll-vertical
---

# Phase 5: Model evaluation

Assess and compare model performance using statistical metrics like AUC, and explainable AI techniques to understand model predictions. This allows for identification of the most reliable models and extraction of biologically meaningful insights from models.

<details>

<summary>1) Select models for evaluation </summary>

**Step 1. Navigate to the&#x20;**<kbd>**Dashboard**</kbd>**&#x20;and select your predictive analysis from the queue**

* The queue number selected is indicated in the pink box at the top right of the PANDORA interface.

<figure><img src="../../.gitbook/assets/CP_Phase 5_Select Analysis.png" alt=""><figcaption></figcaption></figure>

***

**Step 2. Navigate to&#x20;**<kbd>**Predictive**</kbd>**&#x20;->** [<kbd>**Exploration**</kbd>](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration)

* Select the dataset

<figure><img src="../../.gitbook/assets/CP_Phase 5_Exploration Select Dataset.png" alt=""><figcaption></figcaption></figure>

***

**Step 3. Configure model metrics**

1. Select all Response outcomes
2. Select metrics of interest
   1. For our analysis, we will select metrics `AUC` `Accuracy`, and `Precision`

{% hint style="info" %}
### How to select appropriate metrics for our model

To select metrics most appropriate for the model, we need to consider our driving immunological question and dataset balance. This will help identify areas where error minimization is critical and where certain metrics may be misleading. For more information on determining which metrics are best for evaluating your model, see our [Model Metrics page](https://atomic-lab.gitbook.io/pandora/data-analysis/predictive/exploration/model-metrics)

Let's consider our immunological question and dataset:

* **Immune Question:** Can we utilize certain immune parameters measured early after infection to predict whether an individual builds a durable immune response to SARS-CoV-2?
  * Think about the applications of our immune question. Applications could include deciding who to vaccinate or placement of healthcare workers. In these cases, we must be correct in assuming someone is a durable responder, even if we miss assigning some durable responders. Thus, `Precision` is key here.
* **Dataset:** Even though the dataset is evenly split between high and low responders, the split between sex and disease severity is imbalanced. Therefore, measures assuming a balanced dataset, such as accuracy, should be taken with a grain of salt.
{% endhint %}

<figure><img src="../../.gitbook/assets/CP_Phase 5_Exploration Select Metrics.png" alt=""><figcaption></figcaption></figure>

***

**Step 4. Select models for evaluation**

* Select models to evaluate
  * For this example, we will select the top three models: `cforest`, `sparseLDA` and `dwdRadial` to evaluate their performance.

<figure><img src="../../.gitbook/assets/CP_Phase 5_Exploration Select Models.png" alt=""><figcaption></figcaption></figure>

</details>

<details>

<summary>2) Evaluate model performance </summary>

**Purpose:** Evaluate model metrics, which will tell us how well early immune signatures predict durable antibody response.

***

**Step 1. Tabular comparison of metrics**&#x20;

In the exploration space, you will notice that each selected model is part of a table containing metrics. The metrics in this table are the same as those selected in the prior step. You can sort models in this table by metric values if there is a particular metric you care most about.

Each metric tells us something important about the model, and comparing metrics within a model can reveal even more information. The table of metrics selected for our models is shown below:

<figure><img src="../../.gitbook/assets/CP_Phase 5_Exploration Model Metrics Comparison.png" alt=""><figcaption></figcaption></figure>

From the metrics in this table, we can deduce the following for each model:

* `cforest`: Initially, accuracy may seem the best in this model, but we see training accuracy is about 20% lower, indicating a potential imbalance in the data split between training and testing or complexity. Thus, accuracy may not be a good measure here. With high AUCs in training (0.8639) and testing (1), the model is good at distinguishing between classes (durable vs non-durable). The model is also decently good at correctly identifying those who are responders with a precision of 0.8417.
* `sparseLDA`: Overall, this model is best at correctly identifying positive responders with a precision of 0.9333. With the highest AUCs (train=0.9056, test=1), this model is also best at distinguishing between durable and non-durable responders.
* `dwdRadial`: Although the AUC in this model is comparable to the other models (train=0.8444, test=0.9583), it has the lowest precision (0.7939). Indicating that the model is good at distinguishing between responders, but struggles more in correctly identifying positive (durable) responders.

For more information on what each metric tells us, please see the documentation section [Model Metrics](https://atomic-lab.gitbook.io/pandora/data-analysis/predictive/exploration/model-metrics)

***

**Step 2. Evaluate ROC curves**&#x20;

ROC curves provide vital information about model performance with both training and testing datasets.&#x20;

1. To view and compare ROC curves for a model, choose your desired model(s) select the [**ROC Curve Analysis**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration/roc-curve-analysis) in Exploration&#x20;

<figure><img src="../../.gitbook/assets/CP_Phase 5_Exploration ROC Curve Select.png" alt=""><figcaption></figcaption></figure>

2. Observe the shape of the ROC curve and the AUC for each classification category (high or low responder) by clicking on the graph to expand.
   1. If choosing multiple models, select the model name to view its ROC curve&#x20;
   2. Compare curves of multiple models by selecting the **Comparison** tab&#x20;

Ideally, AUC scores to equal 1 or very close to 1 are preferred. Furthermore, you want the testing AUC to be higher than the training AUC, as that confirms the model is able to **classify accurately on unseen data**.&#x20;

Below, we can see that the ROC curves for both train and test datasets fit these criteria best for sparseLDA. The ROC curves for this model also match closely with the ROC curve in figure 7c of the [reference paper](https://www.nature.com/articles/s41467-022-28898-1).

<div><figure><img src="../../.gitbook/assets/CP_sparseLDA training roc-auc.png" alt=""><figcaption></figcaption></figure> <figure><img src="../../.gitbook/assets/CP_sparseLDA testing roc-auc.png" alt=""><figcaption></figcaption></figure></div>

***

**Step 3. Evaluate Training Summary**

Along with ROC curves and AUC, there are other important metrics that help determine whether a model is good for answering the specific research question. Many of these metrics are derived from a **confusion matrix**.

1. To view these metrics, choose **two or more models** and navigate to the [**Training summary**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration/training-summary) tab in Exploration&#x20;

<figure><img src="../../.gitbook/assets/Screenshot 2025-06-27 134812 (1).png" alt=""><figcaption></figcaption></figure>

2. View the **box plots** to compare various metrics related to the models' performance. The example below compares the measurements for the models `cforest`, `sparseLDA` and `dwdRadial` . Further details on each of these metrics can be found in our [documentation](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration/model-metrics)

<figure><img src="../../.gitbook/assets/CP_Phase 5_Training Summary Box Plotst.png" alt=""><figcaption></figcaption></figure>

3. &#x20;Scrolling down, you can view the **Performance measurements** to determine if there are significant differences between model metric values.
   1. From this, for our metrics of interest, we see no significant differences between training AUC values, but we do see significant differences between `dwdRadial` and `sparseLDA` for accuracy & precision values.
4. The **Model fitting results summary**, located to the right of the performance measurements, provides the five-number summary of each model that is visualized in the box plots.

<figure><img src="../../.gitbook/assets/CP_Phase 5_Training Summary_Performance Measurements and Model Fit.png" alt=""><figcaption></figcaption></figure>

</details>

<details>

<summary>3) Identify key early predictors </summary>

We can identify early predictors using PANDORA's [**Variable Importance**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration/variable-importance) feature, where explainable AI is used to assign a score to the predicting features based on how important the model considered that feature in its classification task. A higher score indicates higher importance.&#x20;

**Step 1. Identify Important Variables**

1. Choose your best model and select the **Variable Importance** tab in Exploration&#x20;
   1. Depending on your purpose, such as getting a generalized view of features agreed upon by multiple models, you can choose the top few models to explore their variable importance.&#x20;
   2. The example below follows looking at variable importance for the models `cforest`, `dwdRadial` and `sparseLDA`&#x20;
2. Select the **Variable Importance** sub-tab with the main Variable Importance tab

<figure><img src="../../.gitbook/assets/CP_Phase 5_Slect Variable Importance.png" alt=""><figcaption></figcaption></figure>

The variable importance plot generated is shown below.&#x20;

<figure><img src="../../.gitbook/assets/CP_Phase 5_Variable Importance Plot.png" alt=""><figcaption></figcaption></figure>

Many of the top features on this plot are the same as those reported in the reference paper in Figure 7c. Just like the paper, `N-IgG` is the most important feature. The features `ADCD`, `psuedoNA Abs`, `S-IgG`, `S1 T cells EliSpot`, `Total pos T cells ELISpot`, and `S2 T Cell ELISPOT` also account for a similar level of importance as in the paper figure 7c. A notable difference is that the feature `M T cells elispot` is rated at a higher level of feature importance in this model.

***

**Step 2. Assess feature distribution across the dataset**

The **Features across dataset** tab shows the distribution of high and low responders for any selected features. Looking at these plots will tell us how the quantitative values of early predictive features vary between durable and non-durable responders.

1. From the table, select the most important features identified in part 1. We will use `N-IgG`, `ADCD`, `psuedoNA Abs`, `S-IgG`, `S1 T cells EliSpot`, `Total pos T cells ELISpot`, `M T cells elispot`, and `S2 T Cell ELISPOT`
2. Select the <kbd>Features across dataset</kbd> tab and click the <kbd>Redraw Plot</kbd> button

<figure><img src="../../.gitbook/assets/CP_Phase 5_Features Across Dataset.png" alt=""><figcaption></figcaption></figure>

The resulting dot plots for each selected feature are shown below:

<figure><img src="../../.gitbook/assets/CP_Phase 5_Features Across Dataset Dot Plots.png" alt=""><figcaption></figcaption></figure>

Every dot plot shows the distribution of high and low responders for a selected feature. From this, we see the starkest difference between high and low responders for `N-IgG`, wherein `N-IgG` is elevated for high responders. Generally, we are also seeing that feature levels are elevated and distributions are more spread for high responders in comparison to low responders.

</details>

This concludes the analysis steps for our dataset. The next step is to combine all of the findings to meet the initial objectives of our analysis by describing immune trajectories, reporting the best model, and listing the most important early immune signatures. These objectives were:

* **Visualize the trajectories of diverse immune responses over 6 months** after infection by analyzing how trajectories differ based on initial disease severity and the correlations between different immune parameters
* **Predict pre-defined long-term antibody responder status based on early immune signatures**
