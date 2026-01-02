---
description: >-
  In this phase, we will conduct analyses to identify patterns within the
  dataset
hidden: true
icon: chart-scatter-bubble
---

# Phase 2: Multivariate exploratory analysis

Multivariate exploratory data analysis is an open-ended approach that allows us to understand the relationships within our data. It can help with discovering patterns, spotting anomalies, and guiding assumptions before inputting the data into a machine learning algorithm.

{% hint style="info" %}
### The importance of Exploratory Data Analysis

Exploratory data analysis is a necessary step to ensure any results produced with your data are valid and applicable. Some examples demonstrating the importance of the step are provided below:

* Detecting patterns: dimensionality reduction can expose otherwise hidden clusters of data points that can provide insights on underlying structure of data.
* Revealing modeling considerations: Several patterns can be revealed by this analysis that inform data processing and model inputs.
  * Multicollinearity: Analysis may show multiple attributes are highly correlated, which we may want to group into a single variable or remove to prevent redundancy.
  * Pattern recognition: Recognition of non-linear versus linear data patterns can inform appropriate model selection.
  * Cluster identification: Dimensionality reduction may reveal data clusters that can form a new attribute input into the data model.
* Preparing data: EDA can inform data cleaning and transformation prior to inputting the data into a model. For instance, if you notice the expression levels of related antibodies exhibit a strong positive correlation, a new variable could be created as the mean expression level across these antibodies to replace the individual antibody expression levels.
{% endhint %}

Skipping this process can result in the use of inappropriate models for your data, unnecessary noise that affects model performance, and missed patterns that could have informed feature engineering or data cleanup to improve your model.

In this workflow, we will perform two multivariate exploratory data analyses: Principal Component Analysis (PCA) for dimensionality reduction, and correlation analysis.

[Reference ](https://www.dasca.org/world-of-data-science/article/a-comprehensive-guide-to-mastering-exploratory-data-analysis)for more information on exploratory data analysis.

***

### Analysis 1 - Principal Component Analysis (PCA)

PCA can be used to reduce the dimensionality of the complex immune data and visualize the features that contribute to the most variation in the dataset across all timepoints. We will use PCA to also investigate how individuals cluster based on their overall immune profile and whether this relates to features such as disease severity, changes over time, or responder status.&#x20;

To understand more about why PCA is used for this particular analysis, click [here](why-pca.md) or visit the subpage under this section.&#x20;

<details>

<summary>Perform PCA</summary>

**Step 1. Navigate to PCA analysis by going to&#x20;**<kbd>**Discovery**</kbd>**&#x20;->&#x20;**<kbd>**Start**</kbd>**&#x20;->&#x20;**<kbd>**PCA analysis**</kbd>&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-14 080523.png" alt=""><figcaption></figcaption></figure>

***

**Step 2. Select all relevant columns on which to perform PCA.**

&#x20;This can be achieved in two ways:&#x20;

1. **Selecting desired columns** in the <kbd>Columns</kbd> tab.&#x20;
   1. For this example, we will choose all numerical immunological assay columns (e.g. e.g., `pseudoNA Abs`, `ADCD`, `ADMP`, `ADNKA`, `B cells elispot`, `S-IgA`, `S-IgG1`…, `N-IgG`, Proliferation assays, T cell ELISpots, MSD assays etc.)&#x20;
2. **Removing undesired columns** in the <kbd>Exclude Columns</kbd> tab.&#x20;
   1. For this example, since we want to keep all numerical immunological assays, we will remove `Donor ID`, `Timepoint`, `Days pso`, `Responder`, demographics (`Age`, `Sex`), clinical symptom columns

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-14 082628.png" alt=""><figcaption></figcaption></figure>

{% hint style="warning" %}
You **CANNOT** use categorical variables to perform PCA&#x20;
{% endhint %}

***

**Step 3. Perform preprocessing of the features. This is essential for PCA**

<figure><img src="../../../.gitbook/assets/image (1).png" alt=""><figcaption></figcaption></figure>

* **Normalize data:** Choose `center` and `scale` to perform z-score normalization on the data
* **Address missing values**: Select `medianimpute` from preprocessing to replace NAs with the median of the feature data.

{% hint style="info" %}
#### Other Options for Handling Missing Values (NA)

It is important to understand your dataset to make the right call on handling missing values. As mentioned in phase 1, "caution should be taken when using median imputation for features containing more than 10% missing values (NA)."

The methods for handling missing values in PANDORA include:

* **Medianimpute**: Replaces NAs with the median of feature data, but is discouraged if more than 10% of a feature contains NAs.
* **Bagimpute:** Utilizes bagged trees to fill missing values. It is more accurate and accounts for relationships between variables, but is computationally expensive.
* **KnnImpute:** Estimates missing values by finding rows with similar patterns to the row with the missing value. This method is also computationally expensive
* **Remove NA toggle:** Toggling this on removes all rows containing any NAs for the features selected and reduces the data considerably.
{% endhint %}

***

**Step 4. Choose a grouping variable.**&#x20;

This will determine how to color the PCA plot and clusters, and is vital for interpreting immune trajectories.

1. Go to PCA Settings (below Preprocessing Options)&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-14 084250 (1).png" alt=""><figcaption></figcaption></figure>

2. Select grouping variables `Disease severity`, `Timepoint` and optionally `Responder` .&#x20;

***

**Step 5. Select Plot Image**

The plots and analyses produced using the selected grouping variables are assessed in the next part.

</details>

<details>

<summary>Analyze Variable Plot</summary>

The **variable plot** showcases how the original variables contribute to the principal components produced through PCA. This plot is vital to understand which immune assays are important in driving the separation between the principal components.&#x20;

To see the variable plot on PANDORA, navigate to the [**Variables**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/pca-analysis/variables) tab within PCA analysis. Specifically, we will be working with the [Correlation plot](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/pca-analysis/variables#id-1.-correlation-circle-s)

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-30 122536.png" alt=""><figcaption></figcaption></figure>

The plot generated from our example is shown below:

<figure><img src="../../../.gitbook/assets/CP_PCA variables plot.png" alt=""><figcaption></figcaption></figure>

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
  * The color gradient represents how well the variable is represented on these two dimensions.
    * **High cos² (red)** = variable is well represented on Dim1 and Dim2.
    * **Low cos² (blue)** = variable contributes more to other PCs (Dim3, Dim4…)

Based on the plot above:

* Variables for **T-cell parameters** like `Proliferation S2 CD8`, `Proliferation NP CD8`, `T cells elispot` etc. strongly contribute to **Dim1** (PC1) and is well represented in both PCs with being mostly red and orange colored&#x20;
* Variables for **antibody responses** like `SARS-CoV2 RBD MSD`, `S-IgG` etc. strongly contribute to **Dim2** (PC2) and is well represented in both PCs with being mostly red and orange colored&#x20;
* Variables such as `B cells elispot`, `memB NL63` etc. do not strongly contribute to either principle component and is also not well represented in either PC with being mostly blue and green in color

</details>

<details>

<summary>Analyze Individuals Plots</summary>

The **individual plot** showcases results for the individual samples in the dataset within the principal component analysis. These plots will help us visualize how the samples are positioned in the PCA space and how they relate to each other based on the principal components. The grouping variables will also aid in observing trends in the dataset within the PCA space with respect to certain important variables.&#x20;

To see the individuals plots on PANDORA, navigate to the [**Individuals**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/pca-analysis/individuals) tab within PCA analysis. Specifically, we will be working with [Grouped and Biplot](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/pca-analysis/individuals#id-1.-correlation-circle-s) within the Correlation circle(s) section.

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-30 135750.png" alt=""><figcaption></figcaption></figure>

&#x20;**Main features of the Individuals correlation circle(s) grouped plots:**

* **Axes :** Like the variable plot, these represent the first two principal components, which explain the most variance in the data (Dim1 = 23.9%, Dim2 = 11.1%).
* **Each point:** A sample taken from healthcare workers, colored and shaped by the grouping variable.
* **Legend**: Shows the grouping categories corresponding to the color and shape of the sample points
* **Ellipses:** Represent the **confidence ellipses** around each group to portray the spread of samples from individuals with the same grouping category.

**Main features of the biplots:**

* The biplot combines the variable and individuals plots explained earlier into one graph.
* **Axes:** These represent the first two principal components, which explain the most variance in the data (Dim1 = 23.9%, Dim2 = 11.1%).
* **Each point:** A sample taken from healthcare workers, colored according to the grouping variable categories
* **Ellipses:** Represent the **confidence ellipses** around each group to portray the spread of samples from individuals with the same grouping category.
* **Arrows:** Each arrow represents one **original variable**
  * **Arrow Direction:** shows how that variable aligns with the principal components
  * **Arrow Length:**  indicates how strongly that variable contributes to the components
  * **Arrow Color & Transparency:** Indicates how strongly a variable contributes to the principal components. Purple and fully opaque is a very strong contributor, while green and translucent is a weak contributor

With this information in mind, let's look at our example Individuals plots below:

***

#### **Grouping Variable - `Disease Severity`**

The **grouped plot** for `disease severity` is shown below.

<figure><img src="../../../.gitbook/assets/CP_disease_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

In the plot above, we observe:&#x20;

* Disease-severity specific trends:&#x20;
  * **Mild cases** (orange triangles) are widely spread, indicating high variance.
  * **Severe cases** (purple squares) are more tightly clustered and separated along Dim1.
  * **Asymptomatic** individuals (green circles) are clustered around the origin, indicating no particular dependence on any principal components&#x20;
* Immunophenotypic groups for mild disease severity cases:
  * **Group 1**: _Lower right_ quadrant, distinct immunophenotype&#x20;
  * **Group 2**: _Upper right_ quadrant, immunophenotype similar to severe disease cases&#x20;
  * **Group 3**: _Centered around origin_, immunophenotype similar to the asymptomatic cases



The **biplot** for `disease severity` is shown below:&#x20;

<figure><img src="../../../.gitbook/assets/CP_disease_PCA indiv biplot (1).png" alt=""><figcaption></figcaption></figure>

From the biplot, we can infer parameters that lead to the separation between the immunophenotypic groups.

* The **T-cell responses** separated **immunophenotypic group 1,** which consisted of the samples with mild disease severity whose immunophenotype shared similarity with those with severe disease severity
* We can see that the **antibody responses** separated **immunophenotypic group 2,** which consisted of the distinct immunophenotypes for the samples with mild disease severity

***

#### **Grouping Variable - `Timepoint`**

The **grouped plot** for `Timepoint` is shown below.

<figure><img src="../../../.gitbook/assets/CP_timepoint_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

In the plot above, we observe:&#x20;

* **Timepoint specific trends:**&#x20;
  * **g\_1 (green circles)** and **g\_56 (green squares)** are tightly clustered in the _upper-left quadrant_, suggesting similar immune profiles early in the onset of the disease.
  * **g\_28 (pink plus signs)** has the **most spread**, which indicates that there is **more variability** in immune responses around 28 days after positive SARS-CoV-2 test
  * **g\_180 (blue squares)** also shows **moderate spread** (the second most spread), suggesting a distinct immune profile at late timepoints.
* **Trajectory over time**
  * The distribution of samples moves from **the upper left quadrant (g\_1)** towards the **lower left quadrant (g\_28 and g\_180)** along **Dim1**.
    * This implies that **Dim1 (PC1)** to some extent captures **immune system evolution over time**.



The **biplot** for `Timepoint` is shown below:&#x20;

<figure><img src="../../../.gitbook/assets/CP_timepoint_PCA indiv biplot (2).png" alt=""><figcaption></figcaption></figure>



From the biplot, we can further infer that:

* The previously observed trend that distribution of samples temporally move along Dim1 is likely due to **antibody responses**, which are the parameters that explain the most variance in Dim1 (PC 1)&#x20;

***

#### **Grouping Variable - `Responder`**

The **grouped plot** for `Responder` is shown below:

<figure><img src="../../../.gitbook/assets/CP_responder_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

In the plot above, we observe:&#x20;

* **Grouping by Responder Status**
  * **High responders** (green circles) are more spread out, especially along Dim1 and Dim2
  * **Low responders** (orange triangles) are tightly clustered around the origin
* **Variance and Spread**
  * The ellipse for high responders is much larger, suggesting **greater heterogeneity** in immune features.
  * Low responders show less variance, indicating they are immunologically **more homogeneous.**



The **biplot** for `Responder` is shown below:&#x20;

<figure><img src="../../../.gitbook/assets/CP_responder_PCA indiv biplot (1).png" alt=""><figcaption></figcaption></figure>

From the biplot, we can further infer that:

* As the high responders are shown to have notable spread across both principal components Dim1 and Dim2, both antibody and T cell responses correspond with the variance of high responders' immune profiles. This suggests that high responders have **multiple correlates of protection**.&#x20;

</details>

You have now used PCA to gain insight into immunological differences between varying responders and visualized immune trajectories based on parameters such as disease severity, time and responder status.&#x20;

This analysis can used to inform hypotheses that look deeper into distinct immunophenotypes from the aforementioned groups or define features of interest for further testing or predictive modelling.&#x20;

***

### Analysis 2 - Correlation Analysis

Correlation analysis helps understand the relationships _between_ different immune measurements across all samples and timepoints. This helps confirm if certain responses tend to occur together (positive correlation) or are mutually exclusive/inversely related (negative correlation). This section presents how to produce a correlation matrix and interpret biological insight from those correlations.&#x20;

<details>

<summary>Perform correlation </summary>

**Step 1. Navigate to perform correlation analysis by going to&#x20;**<kbd>**Discovery**</kbd>**&#x20;->&#x20;**<kbd>**Start**</kbd>**&#x20;->** [<kbd>**Correlation**</kbd>](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/correlation)

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-15 140554.png" alt=""><figcaption></figcaption></figure>

***

**Step 2. Choose the same numerical immunological assays columns as used in PCA under Column Selection**&#x20;

This can be done in two ways:

1. **Selecting desired columns** in the <kbd>Columns</kbd> tab.&#x20;
   1. For this example, we will choose all numerical immunological assay columns (e.g. e.g., `pseudoNA Abs`, `ADCD`, `ADMP`, `ADNKA`, `B cells elispot`, `S-IgA`, `S-IgG1`…, `N-IgG`, Proliferation assays, T cell ELISpots, MSD assays etc.)&#x20;
2. **Removing undesired columns** in the <kbd>Exclude Columns</kbd> tab.&#x20;
   1. For this example, since we want to keep all numerical immunological assays, we will remove `Donor ID`, `Timepoint`, `Days pso`, `Responder`, demographics (`Age`, `Sex`), clinical symptom columns

<figure><img src="../../../.gitbook/assets/CP_Select Columns PCA-Correlation.png" alt=""><figcaption></figcaption></figure>

***

**Step 3. Select&#x20;**<kbd>**Spearman**</kbd>**&#x20;for the Correlation Method within the Column Selection Tab**

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-15 141012.png" alt=""><figcaption></figcaption></figure>

***

**Step 4. Under the Preprocessing tab, select `center` and `scale` to normalize the data**

<figure><img src="../../../.gitbook/assets/image (2).png" alt=""><figcaption></figcaption></figure>

***

**Step 5. Set Correlation Settings**

Go to the Correlation Settings tab to set the following:

* **NA Action**: Set it to a method that can appropriately **handle missing values** such as `pairwise.complete.obs`
* **Plot Type**: Select preferred option to view the correlation in the plot. For this example, the `Full` type was chosen&#x20;
* **Reorder Correlation**: Select `Hierarchical clustering` to visualize relationships between clustered parameters&#x20;
* **Method**: This tab will appear when Hierarchical clustering is selected. Select `Ward` algorithm for clustering.

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-15 141316.png" alt=""><figcaption></figcaption></figure>

***

**Step 6. Select Plot Image to generate the correlogram**

</details>

<details>

<summary>Correlogram analysis: Correlation of immune parameters and timepoints</summary>

The [correlogram](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/correlation#id-2.-correlogram) visually represents the correlation matrix calculated based on the input settings. Based on our settings, here are the main features to consider for analysis:

* **Cell in matrix:** Each cell in the matrix shows the Spearman **correlation coefficient** between two variables. This coefficient can range from a value of -1 to 1.
*   **Color of cell**: The **color** represents the strength and direction of correlation:

    * **Reddish colors:** Positive correlation (as one variable increases, the other tends to increase)
    * **Bluish colors:** Negative correlation (as one variable increases, the other tends to decrease)
    * **White/very light colors:** No/very low correlation

    **Note: Diagonal** values are always 1, since a variable is always perfectly correlated with itself, so they will always be a dark red.&#x20;
* **Color legend/bar**: Located on the right end of the graph, it provides the values that correspond to the colors and their **intensity**, which reflects the strength and direction of the correlation
* **Cluster grouping**: Since we selected hierarchical clustering, the correlogram will show clusters of variables highlighted with a black box encompassing the included cells on the plot.&#x20;

### What insight can the resulting correlogram provide?

Based on the correlogram generated from our input settings, which is shown below, several insights are revealed.

<figure><img src="../../../.gitbook/assets/CP_clustered correlation_all immune assays_days pso timepoints (1).png" alt=""><figcaption></figcaption></figure>

**Clusters:** these are identified groups of variables that are highly correlated or most similar to each other

* The hierarchical clustering revealed clusters that define the primary immune response groups:
  * Top-left block: T-cell related responses (e.g., “T cells elispot”, “Proliferation”)
  * Middle block: Antibody responses (e.g., “S-IgG”, “pseudoNAbs”, “MSD” assays)
  * Bottom-right block: Memory B cell responses (“memB”)

**In-group correlations:** these are correlations identified within clusters that indicate relationships among features within clusters.

* **T Cell Responses (Top-left block)**
  * High correlations among:
    * ELISpot data for different parts of the SARS-CoV-2 coronavirus proteins&#x20;
    * CD4 and CD8 proliferation data for matching antigens, specifically the proteins of the different SARS-CoV-2 strains&#x20;
  * This indicates that health care workers with strong T cell responses to one viral protein often show strong responses to others
* **Antibody Responses (Middle block)**
  * Strong correlation among:
    * SARS-CoV-2 spike protein specific IgG responses and antibody-dependent effector functions (ADMP, ADNP) and MSD assays for SARS-CoV-2 spike and receptor binding proteins
    * MSD assays of seasonal coronavirus spike proteins&#x20;
  * This indicates a robust humoral response in the healthcare workers with the antibodies and effector functions being highly correlated along with antibodies of various strains being correlated&#x20;
* **Memory B Cells (Bottom-right block)**
  * Very strong correlations with immunoglobin G antibodies produced from memory B cells and the number of memory B cells specific to the HKU1 seasonal coronavirus while reasonably strong positive correlation to other seasonal coronavirus specific memory B cells.&#x20;

**Out of group correlations:** these are correlations identified outside of the clusters that indicate relationships between other features.

* Some antibody effector functions (ADNP, ADMP) and immunoglobin G level (S-IgG) had slight negative to zero correlation with T cell function variables, indicating there is orthogonality between cellular and humoral immunity for certain functions.&#x20;
* Many memory B cell related variables had slight negative to zero correlation with several T cell functions, again suggesting the cellular and humoral immunity functions are orthogonal.&#x20;

**Timepoint specific correlations:** these correlations reveal trends in specific immune responses over time. Some noted temporal trends are stated below:

* **Negative correlation between&#x20;**<kbd>**T-cell response**</kbd>**&#x20;and&#x20;**<kbd>**temporal variables**</kbd>**:** suggests that T cell responses generally decrease with time after infection.&#x20;
* **Slight positive correlation between some&#x20;**<kbd>**antibody response**</kbd>**&#x20;variables (`ADNP`, `ADKNA`, and `S-IgG1`) and&#x20;**<kbd>**temporal variables**</kbd>**:** indicating that some antibody levels increased with time after infection.&#x20;
* **Slight negative/zero correlation between some&#x20;**<kbd>**other antibody response variables**</kbd>**&#x20;and&#x20;**<kbd>**temporal variables**</kbd>**:** indicating a mixed relation between general humoral responses and time.&#x20;
* **Slight positive correlation between&#x20;**<kbd>**some B-cell variables**</kbd>**&#x20;like `B cell elispot` and `S-IgG memB SARS-CoV2` and&#x20;**<kbd>**temporal variables**</kbd>**:**   indicating that these B-cell levels increase with time after infection

</details>

You have now learned how to produce a correlation matrix and perform a correlation analysis, identifying blocks of correlated variables and their potential biological insight.

***

Now that we have taken steps to identify important immune parameters related to disease severity, temporal variables and immune response durability, we will work towards identifying early immunological signatures that are associated with a durable immune response to SARS-CoV-2 using predictive modelling.&#x20;
