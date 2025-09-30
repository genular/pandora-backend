---
description: >-
  In this phase, we will import the dataset downloaded from 'Introduction', and
  examine the structure of the dataset for downstream analysis.
hidden: true
icon: chart-mixed
---

# Phase 1: Data overview

The aim is to assess the different data types within the dataset, view their distributions for preliminary exploration, and inspect missing values, which is especially common in longitudinal studies.&#x20;



<details>

<summary>1) Launch PANDORA</summary>

1. Open Docker and start the PANDORA container&#x20;

<figure><img src="../../../.gitbook/assets/CP_launch pandora.png" alt=""><figcaption><p>PANDORA container on Docker Desktop</p></figcaption></figure>

1. Open Your Terminal:
   * On Windows, search for **PowerShell** in your Start menu and open it.
   * On MacOS or Linux, open the **Terminal** app.
2.  Run the Installation command:

    {% code overflow="wrap" %}
    ```bash
    docker run --rm --detach --name genular --tty --interactive --env IS_DOCKER='true' --env TZ=Europe/London --oom-kill-disable --volume genular_frontend_latest:/var/www/genular/pandora --volume genular_backend_latest:/var/www/genular/pandora-backend --volume genular_data_latest:/mnt/usrdata --publish 3010:3010 --publish 3011:3011 --publish 3012:3012 --publish 3013:3013 genular/pandora:latest
    ```
    {% endcode %}
3. Access PANDORA:
   * Open your browser and navigate to [http://localhost:3010](http://localhost:3010)

</details>

<details>

<summary>2) Data upload and plot</summary>

1. Navigate to [**Workspace**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/general/workspace)&#x20;
2. Upload the `covid_pitch.csv` file onto  Workspace&#x20;
3. Select the uploaded dataset&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-17 122917.png" alt=""><figcaption></figcaption></figure>

4. Navigate to [Data Overview](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview) by going to **Discovery -> Start -> Data overview**&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-14 070809.png" alt=""><figcaption><p>Steps to access 'Data overview' on PANDORA</p></figcaption></figure>

5. Select up to a dozen variables to examine the data structure through visualization of data distributions
   1. The first variable will be selected as the sorting variable
   2. **Identify key columns**: In this study, the data can be divided into several important categories- `Donor ID`, `Timepoints`, immunological assays, demographics, clinical symptoms, `Disease severity` and `Responders` . Hence, aim to view distributions that are representative of these categories&#x20;
   3. **Missing values (NA)**:  The number of missing values in each feature is provided during column selection. A star next to the number of NAs indicates that <10% of the values are NA in that feature
   4. In this example, from column selection, features are selected in the order of  `Timepoint`, `Age`, `Days pso`, `S-IgG`, `S-IgG memB SARS-CoV-2`, `Disease severity`, `Responder`
      1. As the first feature selected the day sample was acquired after a positive SARS-CoV-2 test (`Timepoint`) is used as the sorting variable. `Timepoint` is compared to the severity of SARS-CoV-2 symptoms experienced (`Disease severity`),  outcome of immune response durability at 6 months (`Responder`), and concentrations of immunoglobin G antibodies targeting SARS-CoV-2 spike protein (`S-IgG`, `S-IgG memB SARS-CoV2`)

<figure><img src="../../../.gitbook/assets/image.png" alt=""><figcaption></figcaption></figure>

{% hint style="warning" %}
**Handling Missing Values**

Caution should be taken when using median imputation for features containing more than 10% missing values (NA). In these cases, you will want to check the dataset to ensure no bias in the missing values (ie, all high responders are missing a selected baseline measurement).
{% endhint %}

6. After selection of desired features, select 'Plot image', and the distribution and table plots will be generated for the selected columns. You will see plots similar to the ones below:&#x20;

<div><figure><img src="../../../.gitbook/assets/CP_dist plot main (1).png" alt=""><figcaption><p><strong>Distribution plot</strong> for  <kbd>Timepoint</kbd>, <kbd>Disease severity</kbd>, <kbd>Responder</kbd>,<kbd>S-IgG memB SARS-CoV-2</kbd> and <kbd>S-IgG</kbd></p></figcaption></figure> <figure><img src="../../../.gitbook/assets/CovidPitch_Table Plot.png" alt=""><figcaption><p><strong>Table plot</strong> for  <kbd>Timepoint</kbd>, <kbd>Disease severity</kbd>, <kbd>Age</kbd>, <kbd>Days pso</kbd>, <kbd>Responder</kbd>,<kbd>S-IgG memB SARS-CoV-2</kbd> and <kbd>S-IgG</kbd></p></figcaption></figure></div>

7. Repeat the above steps to produce plots for key categorical variables and numerical assays of interest

</details>

<details>

<summary>3) Examine <a href="https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview#distribution-plot">distribution plots</a></summary>

This plot displays the frequency and spread of individual variables, hence providing information about skewness, potential outliers, and correlations between variables

Based on the distribution plot generated in our above example,&#x20;

1. The chosen variables consist of both **categorical** and **continuous** variables, as shown by presence of both graphs and histograms along the diagonal.&#x20;
   1. `Timepoint` is a continuous variable with a multimodal distribution
   2. `Disease severity` is a categorical variable shown with two bins, with the first class (asymptomatic) notably less present in the dataset compared to the second class (mild)&#x20;
   3. `Responder` is a categorical variable and there are almost equal numbers of 'low' and 'high' responders
   4. `S-IgG`, `S-IgG memB SARS-CoV2` are continuous variables and their distributions are right-skewed&#x20;
2. There is significant correlation, indicated by the stars next to the correlation values and highlighted by the red boxes, between:&#x20;
   1. `Timepoint` and `S-IgG`
   2. `S-IgG memB SARS-CoV2` and `S-IgG`
3. The box plots do not portray any highly notable relationships, and the histogram with `Responder` and `Disease severity` (shown in green box) show significantly low numbers of asymptomatic workers who were 'high' responders compared to workers with mild severity, and slightly higher mild workers who were 'low' responders compared to asymptomatic.&#x20;
4. There are significant outliers in the correlation plots, as shown by the blue circles.

<figure><img src="../../../.gitbook/assets/CovidPitch_Distribution Plot_annotated.png" alt=""><figcaption></figcaption></figure>

</details>

For a more comprehensive overview and understanding of distribution plots along with how to analyze the ones produced in PANDORA, visit the [**Understanding distribution plots**](understanding-distribution-plots.md) page

<details>

<summary>4) Examine <a href="https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview#table-plot">table plots</a></summary>

This plot can be used to visualize distribution patterns for multiple variables together in a single figure, examine missing values and understand data types and unique value counts.

Select the **Table Plot** tab (located left of the Distribution Plot tab)

Based on the table plot generated from our previous example:&#x20;

1. The leftmost variable, `Timepoint` , is the sorting variable, arranging all rows from the largest to the smallest values (starting from bottom to the graph to upwards)&#x20;
2. As stated in the left bottom corner of the graph (highlighted in a red box), there are 100 bins with 4 objects in each bin&#x20;
3. `Disease severity` and `Responder` variables are categorical, as shown by the legend and colored bins&#x20;
   1. There are a notable number of **missing values**  in the `Responder` column (colored in red), which compared to the `Disease severity` plot is highly present in samples taken from workers with **severe** disease symptoms.&#x20;
4. `Timepoint`, `Age`, `Days pso`, `S-IgG`, and `S-IgG memB SARS-CoV2` are numerical variables.&#x20;
   1. `Timepoint` has a staircase-type distribution indicating to five discrete timepoints the sample was obtained&#x20;
   2. The distribution of `Age`, `Days pso`,  `S-IgG` and  `S-IgG memB SARS-CoV` portrays these variables are more continuous
5. Generally, there is no correlation between timepoints and concentration of spike protein-specific IgG produced from memory B cells.&#x20;
6. `S-IgG`, which is log-transformed, indicating overall spike protein-specific IgG concentration, appears to be higher at the latest timepoint compared to the earliest timepoint&#x20;
7. The samples with highest IgG concentrations in either variable generally correspond with a high responder&#x20;

<figure><img src="../../../.gitbook/assets/CovidPitch_Table Plot.png" alt=""><figcaption></figcaption></figure>

</details>

For a more comprehensive overview and understanding of table plots along with how to analyze the ones produced in PANDORA, visit the [**Understanding table plots**](understanding-table-plots.md) page



You've now uploaded your dataset and completed an initial inspection to understand variable types, distributions, and missing values. These initial steps ensure your data is clean and well understood before performing more comprehensive analyses and running predictive models.&#x20;
