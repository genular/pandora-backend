---
description: >-
  Create models to predict response classification from baseline immune
  measurements.
---

# Phase 4: Predictive Modeling

### Purpose

Prepare your dataset for predictive analysis by removing outcome variables that could bias results, ensuring that only baseline predictor variables remain. Then, configure and run predictive models in PANDORA using the cleaned dataset.

***

### Action:

{% stepper %}
{% step %}
### Process Predictive Dataset

To ensure unbiased predictions, it's important to remove any outcome variables that aren't the designated responder. Various tools can be used for this step, but Excel is used in the example below.

1. Open your Flu Fighter dataset with responder columns in Excel
2. Search and remove all undesired outcome variables. A few examples below:
   1. `ch6_titer_v21`, `h3_v2_shed`, `h1_hai_gmt_fold_change`
   2. Helpful search terms
      1. fold
      2. v2
      3. v7
3. Select and delete every column containing these terms.

<figure><img src="../.gitbook/assets/FF_Phase 4_Process Dataset_cropped.png" alt=""><figcaption></figcaption></figure>

1. Save as a new predictive processed .csv file
2. Upload the new file to PANDORA
{% endstep %}

{% step %}
### Select Dataset

1. Navigate to **Workspace**
2. Select the processed Flu Fighters dataset with added `ResponderStatus` or `Cluster` column

<figure><img src="../.gitbook/assets/FF_Phase 4_Workspace_Select Processed Dataset.png" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}
### Set Up Prediction Task

3. Navigate to **Predictive** -> **Start**

<figure><img src="../.gitbook/assets/FF_Phase 4_Predictive Start.png" alt=""><figcaption></figcaption></figure>

3. Configure **Analysis Properties**
   1. Select all columns as **Predictor variables**
   2. Use PANDORA's **Exclude predictors** for `*fold_change`, `v2`, `v7`, `v21` or any other accidental outcome variables. There should be none if the predictive processing was completed correctly in step 1.
   3. Select `ResponderStatus` or `pandora_cluster` column for **Response**
   4. Select **Preprocessing** options `center`, `scale`, `medianimpute`, `corr`,  `zv`, and `nzv`
   5. Set **Training/Testing dataset partition** to 75% training and 25% testing

<figure><img src="../.gitbook/assets/FF_Phase 4_Predictive_Analysis Properties.png" alt=""><figcaption></figcaption></figure>

3. Select **packages** for your predictive models
   1. For this example, select `rf`, `nb`, `glm`, `mlp`, and `C5.0`

<figure><img src="../.gitbook/assets/FF_Phase 4_Predictive_Package Selection.png" alt=""><figcaption></figcaption></figure>

{% hint style="info" %}
### Experimental Options

When creating your own predictive models, you can experiment with the following:

* **Training/Testing dataset partition**: Different models perform better in different partitions, and experimenting with this parameter can help generate the best model.
* **Packages:** PANDORA has 200+ packages for predictive models, and you can even select a whole family of models with similar features.
* [**Multi-set Intersection**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/simon/multiset-intersection)
* [**Feature Selection**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/simon/feature-selection)
{% endhint %}

{% hint style="warning" %}
**Caution:** Running too many models simultaneously on a personal computer may significantly increase processing time, and computationally intensive models may fail due to **Timeout**
{% endhint %}
{% endstep %}

{% step %}
### Run Analysis

1. Click the **Validate data** button
2. Click the **Process** button on the pop-up that appears

<figure><img src="../.gitbook/assets/FF_Phase 4_Predictive_Process Models.png" alt=""><figcaption></figcaption></figure>

1. Monitor Progress on your PANDORA **Dashboard**

<figure><img src="../.gitbook/assets/FF_Phase 4_Dashboard_Monitor Progress.png" alt=""><figcaption></figcaption></figure>
{% endstep %}
{% endstepper %}

***

### Summary

You’ve successfully processed your dataset to remove bias-inducing outcome variables and configured predictive models using PANDORA. Once your models have completed processing, you're ready to interpret the results and evaluate model performance in the next phase.
