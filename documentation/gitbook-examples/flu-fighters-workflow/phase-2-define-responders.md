---
description: >-
  In this phase of the workflow you will define the outcome variable for later
  use in predictive analysis.
icon: user-shield
---

# Phase 2: Define Responders

### Purpose

Classify participants into immune response groups using unsupervised clustering (Method A) or predefined biological thresholds (Method B). The resulting responder labels will guide further analysis and visualization of immune response patterns.

***

### Action

This phase presents two distinct methods to create the `ResponderStatus` column. Choose one path, or potentially run both for comparison.

<details>

<summary>Method A: <strong>Multivariate Clustering (Using PANDORA Discovery)</strong></summary>

1. Navigate to **Discovery** -> **t-SNE Analysis**

<figure><img src="../.gitbook/assets/FF_Phase 2_tSNE Anlaysis_annotated.png" alt=""><figcaption></figcaption></figure>

2.  Expand **Column Selection**

    * Select all `*fold_change` variables

    ![](<../.gitbook/assets/FF_Phase 2_tSNE Anlaysis_Column Selection_annotated.png>)

3)  Expand **Cluster Settings**

    * Set **Target Clusters Range** to between 2 and 4

    ![](<../.gitbook/assets/FF_Phase 2_tSNE Anlaysis_Cluster Range_annotated.png>)

{% hint style="info" %}
### Experimental Options

Feel free to experiment and observe the effects of other t-SNE side panel settings, such as:

* Section **Column Selection**
  * `Grouping Variable`,  `Color Variable`
* Section **Clustering Settings**
  * `Clustering Algorithm`, `K`, `Pick 'Best Cluster' Method`
* Section **t-SNE Settings**
  * `Perplexity`, `Exaggeration Factor`, `Theta`, `Maximum Iterations,` `Learning Rate (Eta)`
* Section **Dataset Settings**
  * `Dataset analysis type`
* Section **Theme Setting**
  * `Theme`, `Color`, `Legend position`, `Font size`, `Point size`, `Ratio`, `Plot size`
{% endhint %}

4. Click the **Plot Image** Button

5) Navigate to **Clustered t-SNE analysis** to visualize clusters

<figure><img src="../.gitbook/assets/FF_Phase 2_tSNE Anlaysis_View Clusters_annotated.png" alt=""><figcaption></figcaption></figure>

6. Navigate to **Dataset Analysis**
   * Based on the heatmap, note the distinguishing features between clusters
   * In this case:
     * **Cluster 1:** Upregulated cellular response and IVPM binding
     * **Cluster 2:** Upregulated antibody response

<figure><img src="../.gitbook/assets/FF_Phase 2_tSNE Anlaysis_Dataset Analysis_annotated.png" alt=""><figcaption></figcaption></figure>

7. Click **Actions** -> **Save to workspace**
   * Enter a desired file name for the new dataset and click ok
   * This saves a new dataset to your dashboard with an added column for cluster assignment

<figure><img src="../.gitbook/assets/FF_Phase 2_tSNE Anlaysis_Save Clustered Dataset_annotated.png" alt=""><figcaption></figcaption></figure>



</details>

<details>

<summary>Method B: <strong>Manual Definition Based on Biological Thresholds (Requires manual pre-processing)</strong></summary>

#### Define Responder Status Rule

1. Define "High Responders" as anyone with `h1_hai_gmt_fold_change` >= 4 **OR** `h3_hai_gmt_fold_change` >= 4
   1. This rule is based on a commonly accepted threshold in immunology for high responders, based on an antibody titer increase of fourfold or more.

#### Implement the Rule

1. Use any tool like Python, R, Excel, etc on the dataset. For this example, Excel is used
2. Create a new column called `ResponderStatus`

<figure><img src="../.gitbook/assets/FF_Phase2_Dataset_Create ResponderStatus_annotated.png" alt=""><figcaption><p>Create ReponderStatus column in FluFighters.csv dataset using Excel</p></figcaption></figure>

3. Search for variable `h1_hai_gmt_fold_change` in th Excel sheet

<figure><img src="../.gitbook/assets/FF_Phase2_Dataset_Search h1.png" alt=""><figcaption><p>Search for h1_hai_gmt_fold_change in FluFighters.csv datset using Excel</p></figcaption></figure>

4. Filter by `h1_hai_gmt_fold_change` ≥ 4

<figure><img src="../.gitbook/assets/FF_Phase2_Dataset_Filter h1.png" alt=""><figcaption><p>Filter by h1_hai_gmt_fold_change ≥ 4 in FluFighters.csv dataset using Excel</p></figcaption></figure>

5. Define high responders
   1. Set filtered rows under `ResponderStatus` to 1 to indicate high responders.

<figure><img src="../.gitbook/assets/FF_Phase2_Dataset_Define High Responders h1_annotated.png" alt=""><figcaption><p>Set filtered rows under ResponderStatus to 1 in FluFighters.csv dataset using Excel</p></figcaption></figure>

6. Remove filter

7) Repeat steps 3 -6 for `h3_hai_gmt_fold_change`

8. Filter `ResponderStatus` column to view rows not equal to 1

<figure><img src="../.gitbook/assets/FF_Phase2_Dataset_Filter Low responders_annotated.png" alt=""><figcaption><p>Filter by ResponderStatus does not equal 1 in FluFighters.csv dataset using Excel</p></figcaption></figure>

9. Define low responders
   1. Set the filtered row values for `ResponderStatus` to 0 to indicate low responders

<figure><img src="../.gitbook/assets/FF_Phase2_Dataset_Define Low Responders_annotated.png" alt=""><figcaption><p>Set filtered rows under ResponderStatus to 0 in FluFighters.csv dataset using Excel</p></figcaption></figure>

10. Save the .csv file under a new name

#### Verify Definition

1. Launch PANDORA
2. Upload your new .csv file with the added `ResponderStatus` column to the **Workspace**

<figure><img src="../.gitbook/assets/FF_Phase 2_Workspace_Upload Manual Responders.png" alt=""><figcaption></figcaption></figure>

1. Select the file and navigate to **Discovery** -> **Data Overview**
2. Expand **Column Selection**
   1. Select the `ResponderStatus` column & another column of choice
   2. Click the **Plot Image** button

<figure><img src="../.gitbook/assets/FF_Phase 2_Data Overview_Manual Responder Column Select_cropped.png" alt="" width="375"><figcaption></figcaption></figure>

3. Check the distribution plot to see counts of "High Responder" vs "Low Responder"
   1. Here we see about an equal proportion of "High Responders" and "Low Responders," indicating suitability for use in further analysis

<figure><img src="../.gitbook/assets/FF_Phase2_Table Plot Manual Responders.png" alt="" width="375"><figcaption></figcaption></figure>

</details>

***

### Summary

You’ve now defined the responder variable, which classifies individuals based on immune response. This classification will guide the predictive models developed later.
