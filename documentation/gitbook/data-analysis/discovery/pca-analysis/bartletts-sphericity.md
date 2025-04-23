---
description: >-
  Provides users with insights on the suitability of their dataset for principal
  component analysis (PCA).
---

# Bartlett's Sphericity

This sub-tab within the **PCA Analysis** results panel shows outputs from two statistical tests that help assess if your data is suitable for Principal Component Analysis.

<figure><img src="../../../.gitbook/assets/PCA_Bartletts Sphericity_annotated_v2.png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="Bartlett's Test of Sphericity" %}
Bartlett's Test of Sphericity

* **Purpose:** Tests the hypothesis that your variables are uncorrelated in the population (i.e., the correlation matrix is an identity matrix). If variables are uncorrelated, PCA is not very useful.
* **Output:**
  * $chisq: The test statistic value.
  * $p.value: The significance level (p-value) of the test.
  * $df: Degrees of freedom.
* **Interpretation:** You generally want to **reject** the null hypothesis. A **significant p-value (typically < 0.05)** indicates that the correlation matrix is significantly different from an identity matrix, meaning there are correlations between your variables, and PCA is likely appropriate. If the p-value is > 0.05, PCA might not be the best technique for your data.

<figure><img src="../../../.gitbook/assets/PCA_Bartletts output.png" alt=""><figcaption></figcaption></figure>
{% endtab %}

{% tab title="Kaiser-Meyer-Olkin (KMO)" %}
#### Kaiser-Meyer-Olkin (KMO) Measure of Sampling Adequacy

* **Purpose:** Measures the proportion of variance in your variables that might be common variance (i.e., shared with other variables). It assesses if the variables are suitable for factor analysis or PCA.
* **Output:**
  * $overall: The overall KMO index for the dataset.
  * $report: A qualitative interpretation of the overall KMO score.
  * $individual: (Optional, might be shown) KMO values for each individual variable.
* **Interpretation:**
  * KMO values range from 0 to 1.
  * Values **closer to 1** are better, indicating that patterns of correlation are relatively compact, and PCA should yield distinct and reliable components.
  * A common guideline suggests a minimum overall KMO value of **0.6**. Values below 0.5 are generally considered unacceptable.

<figure><img src="../../../.gitbook/assets/PCA_KMO Output.png" alt=""><figcaption></figcaption></figure>
{% endtab %}
{% endtabs %}

