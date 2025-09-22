---
hidden: true
icon: chart-line-up-down
---

# Phase 3: Correlation analysis

Correlation analysis helps understand the relationships _between_ different immune measurements across all samples and timepoints. This helps confirm if certain responses tend to occur together (positive correlation) or are mutually exclusive/inversely related (negative correlation). This phase presents how to produce a correlation matrix and interpret biological insight from those correlations.&#x20;

<details>

<summary>Perform correlation </summary>

1. Navigate to perform correlation analysis by going to **Discovery -> Start ->** [**Correlation**](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/correlation)&#x20;

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-15 140554.png" alt=""><figcaption></figcaption></figure>

2. Choose the same numerical immunological assays columns as used in PCA under Column Selection&#x20;
3. Select **Spearman** for the **Correlation Method** within the Column Selection Tab

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-15 141012.png" alt=""><figcaption></figcaption></figure>

4. Under the **Preprocessing** tab, select `center` and `scale` to normalize the data

<figure><img src="../../.gitbook/assets/image (2).png" alt=""><figcaption></figcaption></figure>

5. Go to the Correlation Settings tab:&#x20;
   1. **NA Action**: Set it to a method that can appropriately **handle missing values** such as `pairwise.complete.obs`
   2. **Plot Type**: Select preferred option to view the correlation in the plot. For this example, the `Full` type was chosen&#x20;
   3. **Reorder Correlation**: Select `Hierarchical clustering` to visualize relationships between clustered parameters&#x20;
   4. **Method**: This tab will appear when Hierarchical clustering is selected. Select `Ward` algorithm for clustering.

<figure><img src="../../.gitbook/assets/Screenshot 2025-05-15 141316.png" alt=""><figcaption></figcaption></figure>



</details>

<details>

<summary>Correlogram analysis: Correlation of immune parameters and timepoints</summary>

The [correlogram](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/discovery/correlation#id-2.-correlogram) visually represents the correlation matrix calculated based on the settings. Based on our settings, here are the main features to aid with analysis:&#x20;

* **Cell in matrix:** Each cell in the matrix shows the Spearman **correlation coefficient** between two variables. This coefficient can range from a value of -1 to 1.
*   **Color of cell**: The **color** represents the strength and direction of correlation:

    * **Reddish colors:** Positive correlation (as one variable increases, the other tends to increase)
    * **Bluish colors:** Negative correlation (as one variable increases, the other tends to decrease)
    * **White/very light colors:** No/very low correlation

    **Note: Diagonal** values are always 1, since a variable is always perfectly correlated with itself, so they will always be a dark red.&#x20;
* **Color legend/bar**: Located on the right end of the graph, it provides the values that corresponds to the **intensity** of the color, which reflects the strength of the correlation
* **Cluster grouping**: As we chose hierarchical clustering, the correlogram will high clusters of variables highlighted with a black box on encompassing the cells on the plot.&#x20;

### What insight can the resulting correlogram provide?

* **Clusters**
  * The hierarchical clustering resulted in clusters that define main groups of immune responses:
    * Top-left block: T-cell related responses (e.g., “T cells elispot”, “Proliferation”)
    * Middle block: Antibody responses (e.g., “S-IgG”, “pseudoNAbs”, “MSD” assays)
    * Bottom-right block: Memory B cell responses (“memB”)
* **In-group correlations:**&#x20;
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
* **Out of group correlations:**&#x20;
  * Some antibody effector functions (ADNP, ADMP) and immunoglobin G level (S-IgG) had slight negative to zero correlation with T cell function variables, indicating the orthogonality between cellular and humoral immunity for certain functions.&#x20;
  * Many memory B cell related variables had slight negative to zero correlation with several T cell functions, again suggesting the cellular and humoral immunity functions orthogonality.&#x20;
* **Timepoint specific correlations:**&#x20;
  * Generally. the variables relates to T cell responses show negative correlation to the time variables (`Timepoint`, `Days pso`), suggesting that T cell responses generally decreased with time after infection.&#x20;
  * Some antibody response variables, such as ADNP, ADKNA, and S-IgG1 have slight positive correlation with the temporal variables, indicating that some antibody increased with time after infection.&#x20;
  * Some other antibody responses variables have negative or no correlation, hence indicating a mixed relation between general humoral responses and time.&#x20;
  * Some B-cell variables like `B cell elispot` and `S-IgG memB SARS-CoV2` had slight positive correlation with the temporal variables.&#x20;

<figure><img src="../../.gitbook/assets/CP_clustered correlation_all immune assays_days pso timepoints (1).png" alt=""><figcaption></figcaption></figure>

</details>

You have now learned how to produce a correlation matrix and perform a correlation analysis, identifying blocks of correlated variables and their potential biological insight.&#x20;

Now that we have taken steps to identify important immune parameters related to disease severity, temporal variables and immune response durability, we will work towards how to identify early immunological signatures that can be associated to a durable immune response o SARS-CoV-2 using predictive modelling.&#x20;
