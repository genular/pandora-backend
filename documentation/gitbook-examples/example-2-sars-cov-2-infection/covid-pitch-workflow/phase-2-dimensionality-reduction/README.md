---
hidden: true
icon: chart-scatter-bubble
---

# Phase 2: Dimensionality reduction

PCA can be used to reduce the dimensionality of the complex immune data and visualize the features that contribute to the most variation in the dataset across all timepoints. We will use PCA to also investigate how individuals cluster based on their overall immune profile and whether this relates to features such as disease severity, changes over time, or responder status.&#x20;

To understand more about why PCA is used for this particular analysis, click [here](why-pca.md) or visit the subpage under this section.&#x20;

<details>

<summary>Perform PCA</summary>

1. Navigate to PCA analysis by going to **Discovery -> Start -> PCA analysis**&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-14 080523.png" alt=""><figcaption></figcaption></figure>

2. Select all relevant columns on which to perform PCA. This can be achieved in two ways:&#x20;
   1. Selecting desired columns in the <kbd>Columns</kbd> tab. For this example, we will choose all numerical immunological assay columns (e.g. e.g., `pseudoNA Abs`, `ADCD`, `ADMP`, `ADNKA`, `B cells elispot`, `S-IgA`, `S-IgG1`…, `N-IgG`, Proliferation assays, T cell ELISpots, MSD assays etc.)&#x20;
   2. Removing undesired columns in the E<kbd>xclude Columns</kbd> tab. For this example, since we want to keep all numerical immunological assays, we will remove `Donor ID`, `Timepoint`, `Days pso`, `Responder`, demographics (`Age`, `Sex`), clinical symptom columns

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-14 082628.png" alt=""><figcaption></figcaption></figure>

{% hint style="warning" %}
You **cannot** use categorical variables to perform PCA&#x20;
{% endhint %}

3. Perform **preprocessing** of the features. This is essential for PCA

<figure><img src="../../../.gitbook/assets/image (1).png" alt=""><figcaption></figcaption></figure>

Choose `center` and `scale` to perform z-score normalization on the data&#x20;

Choose a method for addressing the missing values. There are two options: **a)** **`medianimpute`** (replaces NA with median of the feature data, might be acceptable for visualization) and **b)** `Remove NA` toggle (if imputation is undesirable, but this reduces data considerably)&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-14 083940.png" alt=""><figcaption></figcaption></figure>

{% hint style="info" %}
For the examples below, `medianImpute` was used instead of the NA toggle switch\\
{% endhint %}

4. Choose a **grouping variable.** This will determine how to color the PCA plot and clusters, and is vital for interpreting immune trajectories&#x20;

To choose a grouping variable, go to PCA Settings (below Preprocessing Options)&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-14 084250 (1).png" alt=""><figcaption></figcaption></figure>

For this dataset, we will be grouping the variables based on `Disease severity`, `Timepoint` and optionally `Responder` variables. The plots and analysis using these grouping variables can be seen below.

</details>

The **variable plot** showcases how the original variables contribute to the principal components produced through PCA. This plot is vital to understand which immune assays are important in driving the separation between the principal components.&#x20;

To see the variable plot on PANDORA, navigate to the [**Variables**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/pca-analysis/variables) tab within PCA analysis. Specifically, we will be working with the [Correlation plot](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/pca-analysis/variables#id-1.-correlation-circle-s)&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-30 122536.png" alt=""><figcaption></figcaption></figure>

<details>

<summary>Analyze Variable Plot</summary>

Main features to focus on in this plot are: &#x20;

* **Axes**:&#x20;
  * Dim1 (x-axis) and Dim2 (y-axis) are the **first two principal components** (PCs)
  * The percentages represent the **fraction** **of total variance explained** by the respective PC. As shown in the figure below, Dim1 (PC1) explains 23.9% and Dim2 (PC2) explains 11.1% of the total variance in the dataset.&#x20;
* **Arrows:**&#x20;
  * Each arrow represents one **original variable**&#x20;
  * The **direction** of the arrow shows how that variable **aligns with the principal components**
    * The **length** of the arrow indicates **how strongly that variable contributes** to the components:
      * Longer arrows = stronger contribution.
      * Arrows near the origin contribute less.
* **Color (cos²):**
  *   The color gradient represents how well the variable is represented on these two dimensions.

      * **High cos² (red)** = variable is well represented on Dim1 and Dim2.
      * **Low cos² (blue)** = variable contributes more to other PCs (Dim3, Dim4…)



Based on the plot below:

* Variables for **T-cell parameters** like `Proliferation S2 CD8`, `Proliferation NP CD8`, `T cells elispot` etc. strongly contribute to **Dim1** (PC1) and is well represented in both PCs with being mostly red and orange colored&#x20;
* Variables for **antibody responses** like `SARS-CoV2 RBD MSD`, `S-IgG` etc. strongly contribute to **Dim2** (PC2) and is well represented in both PCs with being mostly red and orange colored&#x20;
* Variables such as `B cells elispot`, `memB NL63` etc. do not strongly contribute to either principle component and is also not well represented in either PC with being mostly blue and green in color

<figure><img src="../../../.gitbook/assets/CP_PCA variables plot.png" alt=""><figcaption></figcaption></figure>

</details>

The **individual plot** showcases results for the individual samples in the dataset within the principal component analysis. These plots will help us visualize how the samples are positioned in the PCA space and how they relate to each other based on the principal components. The grouping variables will also aid in observing trends in dataset within the PCA space with respect to certain important variables.&#x20;

To see the individuals plots on PANDORA, navigate to the [**Individuals**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/pca-analysis/individuals) tab within PCA analysis. Specifically, we will be working with [Grouped and Biplot](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/pca-analysis/individuals#id-1.-correlation-circle-s) within the Correlation circle(s) section.&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-30 135750.png" alt=""><figcaption></figcaption></figure>

<details>

<summary>Analyze Individual plots (Grouping variable = <code>Disease severity</code>)</summary>

Main features to focus on in this plot are: &#x20;

* **Axes :** Like the variable plot, these represent the first two principal components, which explain the most variance in the data (Dim1 = 23.9%, Dim2 = 11.1%).
* **Each point:** A sample taken from healthcare workers, colored and shaped by the grouping variable `Disease severity`, indicating severity of clinical symptoms presented by the healthcare worker (asymptomatic, mild, or severe).
* **Ellipses:** Represent the **confidence ellipses** around each group to portray the spread of samples from individuals with same disease severity category.



In the plot below, we observe:&#x20;

* Disease-severity specific trends:&#x20;
  * **Mild cases** (orange triangles) are widely spread, indicating high variance.
  * **Severe cases** (purple squares) are more tightly clustered and separated along Dim1.
  * **Asymptomatic** individuals (green circles) are clustered around the origin, indicating no particular dependence on any principal components&#x20;
* Immunophenotypic groups for mild disease severity cases:
  * **Group 1**: _Lower right_ quadrant, distinct immunophenotype&#x20;
  * **Group 2**: _Upper right_ quadrant, immunophenotype similar to severe disease cases&#x20;
  * **Group 3**: _Centered around origin_, immunophenotype similar to the asymptomatic cases&#x20;

<figure><img src="../../../.gitbook/assets/CP_disease_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

The biplot combines the variable and individuals plots explained earlier into one graph. Based on this combination, we can further infer that:

* The parameters that lead to the separation between the immunophenotypic groups
  * For example, we can see that the **antibody responses** separated **immunophenotypic group 1** which consisted of the distinct immunophenotypes for the samples with mild disease severity
  * The **T-cell responses** separated **immunophenotypic group 2** which consisted of the samples with mild disease severity whose immunophenotype shared similarity with those with severe disease severity&#x20;

<figure><img src="../../../.gitbook/assets/CP_disease_PCA indiv biplot (1).png" alt=""><figcaption></figcaption></figure>



</details>

<details>

<summary>Analyze Individual plots (Grouping variable = <code>Timepoint</code>)</summary>

Main features to focus on in this plot are: &#x20;

* **Axes :** Like the variable plot, these represent the first two principal components, which explain the most variance in the data (Dim1 = 23.9%, Dim2 = 11.1%).
* **Each point:** A sample taken from healthcare workers, colored and shaped by the grouping variable `Timepoint`, the number of days after a healthcare worker's positive SARS-CoV-2 PCR test the sample was obtained.&#x20;
* **Ellipses:** Represent the **confidence ellipses** around each group to portray the spread of samples within each discrete timepoint.
*   **Legend**: Shows the timepoints at which sample was taken after positive SARS-CoV-2 test. Each label indicates sample taken at:&#x20;

    * g\_1: Day 1
    * g\_28: Day 28 (1 month)&#x20;
    * g\_56: Day 56 (2 months)&#x20;
    * g\_90: (3 months)&#x20;
    * g\_120: (4 months)&#x20;
    * g\_180: (6 months)&#x20;



In the plot below, we observe:&#x20;

* **Timepoint specific trends:**&#x20;
  * **g\_1 (green circles)** and **g\_56 (green squares)** are tightly clustered in the _upper-left quadrant_, suggesting similar immune profiles early in the onset of the disease.
  * **g\_28 (pink plus signs)** has the **most spread**, which indicates that there is **more variability** in immune responses around 28 days after positive SARS-CoV-2 test
  * **g\_180 (blue squares)** also shows **moderate spread** (the second most spread), suggesting a distinct immune profile at late timepoints.
* **Trajectory over time**
  * The distribution of samples moves from **the upper left quadrant (g\_1)** towards the **lower left quadrant (g\_28 and g\_180)** along **Dim1**.
    * This implies that **Dim1 (PC1)** to some extent captures **immune system evolution over time**.

<figure><img src="../../../.gitbook/assets/CP_timepoint_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

The biplot combines the variable and individuals plots explained earlier into one graph. Based on this combination, we can further infer that:

* The previously observed trend that distribution of samples temporally move along Dim1 is likely due to **antibody responses**, which are the parameters that explain the most variance in Dim1 (PC 1)&#x20;

<figure><img src="../../../.gitbook/assets/CP_timepoint_PCA indiv biplot (2).png" alt=""><figcaption></figcaption></figure>



</details>

<details>

<summary>Analyze Individual plots (Grouping variable = <code>Responder</code>) - Optional</summary>

Main features to focus on in this plot are: &#x20;

* **Axes :** Like the variable plot, these represent the first two principal components, which explain the most variance in the data (Dim1 = 23.9%, Dim2 = 11.1%).
* **Each point:** A sample taken from healthcare workers, colored and shaped by the grouping variable `Responder`, the outcome of immune response durability calculated based on the titer of the anti-nucleocapsid-specific antibodies measured 6 months post symptoms onset.&#x20;
* **Ellipses:** Represent the **confidence ellipses** around each group to portray the spread of samples within each discrete timepoint.



In the plot below, we observe:&#x20;

* **Grouping by Responder Status**
  * **High responders** (green circles) are more spread out, especially along Dim1 and Dim2
  * **Low responders** (orange triangles) are tightly clustered around the origin
* **Variance and Spread**
  * The ellipse for high responders is much larger, suggesting **greater heterogeneity** in immune features.
  * Low responders show less variance, indicating they are immunologically **more homogeneous.**

<figure><img src="../../../.gitbook/assets/CP_responder_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

The biplot combines the variable and individuals plots explained earlier into one graph. Based on this combination, we can further infer that:

* As the high responders are shown to have notable spread across both principal components Dim1 and Dim2, both antibody and T cell responses correspond with the variance of high responders' immune profiles. This suggests that high responders have **multiple correlates of protection**. &#x20;

<figure><img src="../../../.gitbook/assets/CP_responder_PCA indiv biplot (1).png" alt=""><figcaption></figcaption></figure>

</details>



You have now used PCA to gain insight into immunological differences between varying responders and visualized immune trajectories based on parameters such as disease severity, time and responder status. This analysis can used to inform hypotheses that look deeper into distinct immunophenotypes from the aforementioned groups or define features of interest for further testing or predictive modelling.&#x20;
