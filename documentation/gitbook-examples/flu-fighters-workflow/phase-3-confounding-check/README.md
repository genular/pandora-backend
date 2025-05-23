---
description: >-
  In this phase, you will run t-SNE analysis to check for confounding variables
  within your dataset.
icon: chart-scatter-bubble
---

# Phase 3: confounding check

Assess whether confounding variables, such as age, sex, or batch year, are evenly distributed across responder classifications. Identifying confounding ensures that any patterns in your predictive models are biologically meaningful rather than products of biased group composition.

<details>

<summary>1. Confounding analysis (Example)</summary>

1. Navigate to [**Discovery** -> **Start** -> **t-SNE analysis**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/t-sne-analysis)
2. Configure **Column Selection**
   1. Select all `*fold_change` columns
   2. Select `year`, `sex`, and the responder column for **Grouping variable**
   3. Select `z_score_continuous` for **Color variable**

<figure><img src="../../.gitbook/assets/FF_Phase 3_Confounding Setup tSNE_annotated.png" alt=""><figcaption></figcaption></figure>



</details>

<details>

<summary>2. Check for confounding variables</summary>

1. Compare all t-SNE plots generated to the responder t-SNE plot
   * Is there an approximately equal distribution of confounding variable values in each responder class?  If not, there may be confounding in your predictive model.
     * ex. Is there an equal distribution of males and females in each responder class?

2)  An example confounding check with the manual HAI Responder group

    * Z-score vs HAI Responder
      * Here we see no confounding effect from z-score



    <figure><img src="../../.gitbook/assets/FF_Phase  3_Z-score vs HAI Responder.png" alt="" width="563"><figcaption></figcaption></figure>

    * Year vs HAI Responder
      * Confounding is unclear



    <figure><img src="../../.gitbook/assets/FF_Phase  3_Batch Year vs HAI Responder.png" alt="" width="563"><figcaption></figcaption></figure>

    * Sex vs HAI Responder
      * Confounding is unclear

<figure><img src="../../.gitbook/assets/FF_Phase  3_Sex vs HAI Responder.png" alt="" width="563"><figcaption></figcaption></figure>

{% hint style="success" %}
After generating all these t-SNE plots for the confounder check, it may be a good idea to save the plots to report with your findings later.
{% endhint %}

</details>

<details>

<summary>3. Additional analysis</summary>

In some cases, the resulting t-SNE plots for confounding analysis may be unclear, warranting further analysis, as in the example. It can be beneficial to manually check the confounding variable distribution for each responder class in these cases.

1. Open the dataset with responder columns in Excel

2) Filter by responder class, and manually check the distribution for any confounder variables warranting further analysis

<figure><img src="../../.gitbook/assets/HAI Responder_Sex and year confound.png" alt=""><figcaption></figcaption></figure>

</details>

You’ve examined the distribution of key demographic variables across responder classes to detect possible confounding. If distributions appear balanced, you can proceed confidently; if not, consider addressing the imbalance before continuing with predictive modeling.
