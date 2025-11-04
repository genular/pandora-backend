---
description: >-
  In this phase, you will create models to predict the responder status at 6
  months after infection from early timepoint data (day 28)
hidden: true
icon: diagram-predecessor
---

# Phase 4: Predictive modelling

Upload the processed dataset from [**Phase 4**](../phase-3-data-pre-processing.md), then configure and run predictive models in PANDORA&#x20;

<details>

<summary>1) Setup prediction task </summary>

1. Navigate to [Workspace](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/general/workspace)&#x20;
2. Upload the `covid_pitch_day28_predictors_month6_outcome.csv` file onto  Workspace&#x20;
3. Select the uploaded dataset&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-24 141751.png" alt=""><figcaption></figcaption></figure>

4. Navigate to[ **Predictive**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive) **-> Start**&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-24 143135.png" alt=""><figcaption></figcaption></figure>

5.  Configure analysis properties:

    1. Use the toggle switch to select all columns as the **Predictor variables**&#x20;
    2. Use the **Exclude predictors** option to exclude `Donor ID`&#x20;
    3. Select `Responder` column for **Response**&#x20;
       1. You will not see the `Responder` variable when you scroll since it is beyond the first 50 variables, so type out the variable name and it will appear
    4. Set the **Training/Testing dataset partition** to 75% training (and hence 25% testing)&#x20;
    5. Select Preprocessing options `center`, `scale`, and `medianImpute`&#x20;



<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-24 145451.png" alt=""><figcaption></figcaption></figure>

6. Select **packages** for your predictive models.&#x20;
   1. For this example, we will select family of algorithms especially suitable for biomedical data:
      1. `L1 Regularization` : Also known as LASSO
      2. `L2 Regularization` : Also known as ridge penalty
      3. `Partial Least Squares` : Sparse partial least squares was used in the paper&#x20;
      4. `Random Forest`&#x20;
      5. `Support Vector Machines`&#x20;

{% hint style="success" %}
For more details about these algorithm families, visit the subpage [**Algorithms for biomedical data**](algorithms-for-biomedical-data.md)
{% endhint %}

<figure><img src="../../../.gitbook/assets/CP_SIMON set up (1).png" alt=""><figcaption></figcaption></figure>

{% hint style="warning" %}
**Caution**: Running too many models simultaneously on a personal computer may significantly increase processing time, and computationally intensive models may fail due to **Timeout** limit
{% endhint %}

{% hint style="info" %}
#### Experimental options&#x20;

When creating your own predictive models, you can experiment with:&#x20;

* **Packages**: PANDORA has 200+ packages for predictive models. You can choose other families of algorithms or select individual algorithms.
* **Training/Testing dataset partition**: Different models perform better in different partitions, and experimenting with this parameter can help generate the best model.
* [**Multi-set Intersection**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/simon/mulset-multiset-intersection)
* [**Feature Selection**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/simon/rfe-feature-selection)
{% endhint %}

</details>

<details>

<summary>2) Run analysis </summary>

1. Click the **Validate data** button at the bottom right of the screen&#x20;
2. Click the **Process** button on the pop-up

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-24 152244.png" alt=""><figcaption></figcaption></figure>

Your predictive modelling has started! You can monitor progress on the PANDORA [**Dashboard**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/general/dashboard)

</details>

You have successfully configured the predictive models using PANDORA. Once your models have completed processing, you're ready to interpret the results and evaluate model performance in the next phase.&#x20;
