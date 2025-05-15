---
description: >-
  In this phase of the workflow, you will upload the dataset downloaded in the
  intro, and inspect the dataset for use in the analysis.
icon: sliders
---

# Phase 1: data configuration

Perform an initial exploratory data analysis on the `flu_fighters.csv` dataset, including data upload, inspection of missing values, visualization of variable distributions, and identification of key correlations to guide further analysis.



<details>

<summary>1. Launch PANDORA (if needed)</summary>

1. Open Docker and run PANDORA container if not running

<figure><img src="../.gitbook/assets/FF_Phase1_Launch Docker_annotated.png" alt=""><figcaption></figcaption></figure>

4. Access PANDORA:
   1. Open your browser and navigate to [http://localhost:3010](http://localhost:3010)

</details>

<details>

<summary>2. Inspect data</summary>

1. Navigate to [**Workspace**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/general/workspace)

<figure><img src="../.gitbook/assets/FF_Phase1_Workspace_annotated.png" alt=""><figcaption></figcaption></figure>

2. Upload the `flu_fighters.csv` dataset to [**Workspace**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/general/workspace)

3) Select the uploaded `flu_fighters.csv` dataset

<figure><img src="../.gitbook/assets/FF_Phase1_Workspace_Select Dataset_annotated.png" alt=""><figcaption></figcaption></figure>

4. With the dataset selected, navigate to[ **Discovery** -> **Start**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery)
   1. Select the[ **Data Overview**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview) tab

<figure><img src="../.gitbook/assets/FF_Phase1_Discovery_Data Overview_annotated.png" alt=""><figcaption></figcaption></figure>

5. Select up to 5 variables for inspection
   1. The first variable selected will be set as the sorting variable
   2. Examine missing values - The number of NAs per feature is provided when selecting your columns, a star next to that number indicates <10% of values are NA for a given feature
   3. In this example, baseline CD4+ IFN-γ responses to H1 (`h1_v0_cd4_ifng`)is set as the sorting variable and compared to CD4 cytokine fold change variables (`h1_cd4_ifng_fold_change`, `h3_cd4_ifng_fold_change`, `h1_cd4_il2_fold_change`)

<figure><img src="../.gitbook/assets/FF_Phase1_Data Discovery_Column Selection.png" alt="" width="375"><figcaption></figcaption></figure>

{% hint style="warning" %}
### Handling Missing Values

Caution should be taken when using median imputation for features containing more than 10% missing values (NA). In these cases, you will want to check the dataset to ensure no bias in the missing values (ie, all high responders are missing a selected baseline measurement).
{% endhint %}

6. Plot image for the selected data

7) Examine the [**Distribution Plot**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview#distribution-plot)
   1. This plot provides information about skewness, potential outliers, and correlations between variables.
   2. Based on the distribution plot generated in our example below, we see:
      1. The distribution plot for every selected feature is right-skewed, as shown in the figures along the diagonal.
      2. There is a significant correlation, as shown in the red boxes, between:
         1. `h1_v0_cd4_ifng` & `h1_cd4_ifng_fold_change`
         2. `h1_cd4_ifng_fold_change` & `h1_cd4_il2_fold_change`
         3. `h1_cd4_ifng_fold_change` & `h3_cd4_ifng_fold_change`
         4. `h1_cd4_il2_fold_change` & `h3_cd4_ifng_fold_change`
      3. There are significant outliers in some of the correlation plots, as shown by the red circles.

<figure><img src="../.gitbook/assets/FF_Phase1_Distribution Plot_annotated.png" alt=""><figcaption></figcaption></figure>

8. Select the [**Table Plot**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview#table-plot) tab and examine the table plot
   1. This plot can be used to understand columns (predictors vs. outcomes), data types, and unique value counts.
   2. The leftmost variable is the sorting variable, arranging all rows from its largest to smallest values.
   3. Based on the table plot generated in our example below, we see:
      1. No apparent correlation (positive or negative) between the fold change variables and decreasing baseline cytokine levels.
      2. The data types for each variable are continuous and tend to range between -0.5 and 1 for the log of every variable.

<figure><img src="../.gitbook/assets/FF_Phase1_Table Plot.png" alt=""><figcaption></figcaption></figure>

**Repeat this process for all key baseline and outcome features of interest.**

</details>

<details>

<summary>3. Explore Outcome Variable Relationships (Optional)</summary>

1. Navigate to [**Discovery** -> **Correlation**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery#correlation)

<figure><img src="../.gitbook/assets/FF_Phase1_Dicsovery_Correlation_annotated.png" alt=""><figcaption></figcaption></figure>

2.  Expand **Column Selection**

    1. Select all outcome columns (`fold_change`)

    ![](<../.gitbook/assets/FF_Phase1_Correlation_Column Selection.png>)

    b.  Choose **Correlation Method** `Spearman`

    ![](<../.gitbook/assets/FF_Phase1_Correlation_Correlation Method.png>)

3)  Expand **Preprocessing**

    1. Remove the `medianimpute`

    ![](<../.gitbook/assets/FF_Phase1_Correlation_Remove medianimpute.png>)

4.  Expand **Correlation Settings**

    1. Select **NA Action** `pairwise.complete.obs` from the dropdown

    ![](<../.gitbook/assets/FF_Phase1_Correlation_NA Action.png>)

    b.  Select a desired **Plot method** for visualization

    ![](<../.gitbook/assets/FF_Phase1_Correlation_Plot Method.png>)

5) Set **Text size** to 1

6. Click the **Plot Image** button

7) Observe the correlation plot
   1. See documentation on [Correlation](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/correlation) for more information about interpreting the plot.

<figure><img src="../.gitbook/assets/FF_Phase1_Correlation_Correlation Plot.png" alt=""><figcaption><p>Flu Fighters correlation plot for all fold_change variables</p></figcaption></figure>

This correlogram visualizes the pairwise correlations between the variables listed on both axes; in this instance, these are various \_fold\_change immune parameters. The diagonal line of large, dark red circles represents each variable's perfect positive correlation (+1) with itself. For all other pairs, **reddish circles indicate a positive correlation** (meaning as one variable's fold change increases, the other's also tends to increase), while **bluish circles signify a negative correlation** (as one increases, the other tends to decrease). The **size of each circle and the intensity of its color directly reflect the strength** of this relationship, with the exact correlation coefficient values corresponding to the color bar on the right (ranging from -1 for strong negative to +1 for strong positive). Users should look for **clusters or blocks of similarly colored and sized circles**, as these highlight groups of immune responses whose magnitudes of change are often interlinked or coordinated within the studied cohort; the variables are typically reordered to make such patterns more visually apparent.

</details>

You've now uploaded your dataset and completed an initial inspection to understand variable types, distributions, and missing values. These initial steps ensure your data is clean and well understood before deriving any responder features and running predictive models.

