---
description: >-
  In this phase, we will import the dataset downloaded from 'Introduction', and
  examine the structure of the dataset for downstream analysis.
hidden: true
icon: chart-mixed
---

# Phase 1: Data overview

The aim is to assess the different data types within the dataset, view their distributions for preliminary exploration, and inspect missing values, which are especially common in longitudinal studies.&#x20;



<details>

<summary>1) Launch PANDORA</summary>

**Step 1. Open Docker and start the PANDORA container**&#x20;

<figure><img src="../../../.gitbook/assets/CP_launch pandora.png" alt=""><figcaption><p>PANDORA container on Docker Desktop</p></figcaption></figure>

***

**Step 2. Open Your Terminal**

* On Windows, search for **PowerShell** in your Start menu and open it.
* On MacOS or Linux, open the **Terminal** app.

***

**Step 3. Run the Installation command**

{% code overflow="wrap" %}
```bash
docker run --rm --detach --name genular --tty --interactive --env IS_DOCKER='true' --env TZ=Europe/London --oom-kill-disable --volume genular_frontend_latest:/var/www/genular/pandora --volume genular_backend_latest:/var/www/genular/pandora-backend --volume genular_data_latest:/mnt/usrdata --publish 3010:3010 --publish 3011:3011 --publish 3012:3012 --publish 3013:3013 genular/pandora:latest
```
{% endcode %}

***

**Step 4. Access PANDORA:**

* Open your browser and navigate to [http://localhost:3010](http://localhost:3010)

</details>

<details>

<summary>2) Data upload and plot</summary>

The following steps will walk you through uploading your dataset and creating plots to examine your data structure.

***

**Step 1. Navigate to Workspace**

***

**Step 2. Upload the `covid_pitch.csv` file into Workspace**&#x20;

***

**Step 3. Select the uploaded dataset**

<figure><img src="../../../.gitbook/assets/Screenshot 2025-06-17 122917.png" alt=""><figcaption></figcaption></figure>

***

**Step 4. Navigate to** [**Data Overview**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview)&#x20;

* Click **Discovery -> Start -> Data overview**&#x20;

<figure><img src="../../../.gitbook/assets/Screenshot 2025-05-14 070809.png" alt=""><figcaption><p>Steps to access 'Data overview' on PANDORA</p></figcaption></figure>

***

**Step 5. Select and examine dataset variables**

* **Select your** [**sorting variable**](#user-content-fn-1)[^1] **first**, which is `Timepoint` in this example.
* **Select columns** `Age`, `Days pso`, `S-IgG`, `S-IgG memB SARS-CoV-2`, `Disease severity`, and `Responder` .&#x20;
  * These columns are representative of key parameters to consider for answering our immunological questions proposed in the [dataset description.](../../dataset-description/)
* **Check for missing values** during column selection.
  * The number of missing values (NAs) is shown to the right of the column name.
  * A star (\*) indicates that a column is missing 10% or more of its values.

<figure><img src="../../../.gitbook/assets/image.png" alt=""><figcaption></figcaption></figure>

{% hint style="info" %}
## Guidelines for Column Selection

**How to select your sorting variable:**

* This is typically the independent variable central to your immune question which all other variables are compared against to reach your answers.
* Looking at this workflow example, the immunological questions (listed below) both focus on time as an independent variable. Hence, `Timepoints` was used as the sorting variable.
  * Are there certain immune parameters that can explain the disease severity experienced by individuals and that are **dependent on time** post SARS-CoV-2 infection?
  * Can we utilize certain immune parameters **measured early** after infection to predict whether an individual builds a durable immune response to SARS-CoV-2?

**How to select columns for examination:**

* Consider columns from categories of variables that are essential to answering your proposed immunological question.&#x20;
* In this example, as described in the data overview, these are columns in the categories of:
  * Clinical symptoms, immunological parameters, responder status, demographics, and time
* Pandora allows you to select up to a dozen columns at a time for examination, so you may need to generate multiple plots.
{% endhint %}

{% hint style="warning" %}
#### Handling Missing Values

Caution should be taken when using median imputation for features containing more than 10% missing values (NA). In these cases, you will want to check the dataset to ensure no bias in the missing values (ie, all severe cases are missing a particular timepoint measurement).
{% endhint %}

***

**Step 6. Select 'Plot Image' to generate distribution and table plots**

* You will see plots similar to the ones below:&#x20;

<div><figure><img src="../../../.gitbook/assets/CP_dist plot main (1).png" alt=""><figcaption><p><strong>Distribution plot</strong> for  <kbd>Timepoint</kbd>, <kbd>Disease severity</kbd>, <kbd>Responder</kbd>,<kbd>S-IgG memB SARS-CoV-2</kbd> and <kbd>S-IgG</kbd></p></figcaption></figure> <figure><img src="../../../.gitbook/assets/CovidPitch_Table Plot.png" alt=""><figcaption><p><strong>Table plot</strong> for  <kbd>Timepoint</kbd>, <kbd>Disease severity</kbd>, <kbd>Age</kbd>, <kbd>Days pso</kbd>, <kbd>Responder</kbd>,<kbd>S-IgG memB SARS-CoV-2</kbd> and <kbd>S-IgG</kbd></p></figcaption></figure></div>

***

**Repeat the above steps to produce plots for key categorical variables and numerical assays of interest.**

</details>

<details>

<summary>3) Examine <a href="https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview#distribution-plot">distribution plots</a></summary>

The distribution plot displays the frequency and spread of individual variables, hence providing information about skewness, potential outliers, and correlations between variables. Here, we will provide an example of interpreting results from the distribution plot generated in the previous steps.

{% hint style="info" %}
For a more comprehensive overview and understanding of distribution plots, along with how to analyze the ones produced in PANDORA, visit the [**Understanding distribution plots**](broken-reference) page
{% endhint %}

<figure><img src="../../../.gitbook/assets/CovidPitch_Distribution Plot_annotated.png" alt=""><figcaption><p>Distribution plot generated in the COVID Pitch example for variables <code>Timepoint</code>, <code>Disease severity</code>, <code>Responder, S-IgG</code>, and <code>S-IgG memB SARS-CoV2</code></p></figcaption></figure>

Based on the distribution plot that was generated in our example, and is shown above:&#x20;

1. The chosen variables consist of both **categorical** and **continuous** variables, as indicated by the presence of both graphs and histograms along the diagonal.
   1. `Timepoint` is a **continuous** variable with a multimodal distribution.
   2. `Disease severity` is a **categorical** variable shown with two bins, with the first class (asymptomatic) notably less present in the dataset compared to the second class (mild).&#x20;
   3. `Responder` is a **categorical** variable with approximately equal numbers of 'low' and 'high' responders
   4. `S-IgG`, `S-IgG memB SARS-CoV2` are **continuous** variables with right-skewed distributions.
2. There is **significant correlation** (indicated by the stars next to the correlation values and highlighted by the red boxes) between:&#x20;
   1. `Timepoint` and `S-IgG`
   2. `S-IgG memB SARS-CoV2` and `S-IgG`
3. The box plots do not portray any notable relationships
4. The histogram with `Responder` and `Disease severity` (shown in green box) shows the following:
   1. Lower numbers of asymptomatic workers who were 'high' responders compared to workers with mild severity
   2. A slightly higher number of mild workers who were 'low' responders compared to asymptomatic.&#x20;
5. There are **outliers** in the correlation plots, as shown by the blue circles.

</details>

<details>

<summary>4) Examine <a href="https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/data-overview#table-plot">table plots</a></summary>

This plot can be used to visualize distribution patterns for multiple variables together in a single figure, examine missing values, and understand data types and unique value counts.

{% hint style="info" %}
For a more comprehensive overview and understanding of table plots, along with how to analyze the ones produced in PANDORA, visit the [**Understanding table plots**](broken-reference) page
{% endhint %}

To view the table plots, select the **Table Plot** tab (located left of the Distribution Plot tab)

<figure><img src="../../../.gitbook/assets/CovidPitch_Table Plot.png" alt=""><figcaption></figcaption></figure>

Based on the table plots generated from our previous example, and shown above:&#x20;

1. The leftmost variable, `Timepoint` , is the sorting variable that arranges all rows from top to bottom in the order of smallest to largest values.
2. As stated in the bottom left corner of the graph (highlighted in a red box), there are 100 bins with 4 objects in each bin.
3. `Disease severity` and `Responder` variables are categorical, as shown by the legend and colored bins.
   1. There are a notable number of **missing values** in the `Responder` column (colored in red).
   2. When comparing the `Responder` plot to the `Disease severity` plot, missing values are more prevalent in samples taken from workers with **severe** disease symptoms.&#x20;
4. `Timepoint`, `Age`, `Days pso`, `S-IgG`, and `S-IgG memB SARS-CoV2` are numerical variables.&#x20;
   1. `Timepoint` has a staircase-type distribution that indicates the five discrete time points at which the samples were obtained.
   2. The distribution of `Age`, `Days pso`,  `S-IgG` and  `S-IgG memB SARS-CoV` portrays these variables as more continuous numerical variables.
5. Generally, there is no correlation between timepoints and concentration of spike protein-specific IgG produced from memory B cells.
6. `S-IgG`, which is log-transformed and represents overall spike protein-specific IgG concentration, appears to be higher at the later time points compared to the earliest time points.
7. The samples with the highest IgG concentrations in either variable generally correspond with a high responder&#x20;

</details>

You've now uploaded your dataset and completed an initial inspection to understand variable types, distributions, and missing values. These initial steps ensure your data is clean and well understood before performing more comprehensive analyses and running predictive models.

[^1]: The variable used as the basis for sorting when comparing to other variables. For numerical variables, sorting occurs in ascending order. For categorical variables, sorting occurs by each category.
