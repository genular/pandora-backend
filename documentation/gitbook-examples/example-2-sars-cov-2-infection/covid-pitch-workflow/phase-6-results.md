---
description: >-
  In this phase, we will combine all results from the analysis to address our
  initial objectives in the study.
icon: file-magnifying-glass
---

# Phase 6: Results

The main objectives of this study are listed below. The analysis conducted should have provided insights into these objectives, which can be clearly conveyed by synthesizing results into a report.

* **Visualize the trajectories of diverse immune responses over 6 months** after infection by analyzing how trajectories differ based on initial disease severity and the correlations between different immune parameters
* **Predict pre-defined long-term antibody responder status based on early immune signatures**

***

### Exploratory Summary

Through exploratory analysis, we addressed the first objective in visualizing the trajectory of immune responses over 6 months through PCA analysis.

**Findings:** Overall, exploratory results aligned closely with those of Figure 6 in the reference paper.

* At early onset of disease, all disease severity groups are clustered tightly, suggesting similar immune profiles at initial infection. Over time, variability increases and then converges into a moderate spread based on disease severity, which suggests distinct immune profiles form at later time points (Figure a).
* Separation of immune parameters does not appear driven solely by disease severity. While severe and asymptomatic cases present distinct clustering patterns, mild cases are more spread with three distinct immunophenotypic groups, as shown in Figure b.
  * **Group 1**: _Lower right_ quadrant, distinct immunophenotype with T cell parameters driving separation.
  * **Group 2**: _Upper right_ quadrant, immunophenotype similar to severe disease cases with antibody parameters driving separation
  * **Group 3**: _Centered around origin_, immunophenotype similar to the asymptomatic cases
* As the high responders are shown to have notable spread across both principal components Dim1 and Dim2 (Figure c), both antibody and T cell responses correspond with the variance of high responders' immune profiles. This suggests that high responders have **multiple correlates of protection**.&#x20;
* In the correllogram (Figure d), similar to the reference study, there is a **Negative correlation between&#x20;**<kbd>**T-cell response**</kbd>**&#x20;and&#x20;**<kbd>**temporal variables**</kbd>**:** suggesting that T cell responses generally decrease with time after infection, and a **Slight positive correlation between some&#x20;**<kbd>**antibody response**</kbd>**&#x20;variables (`ADNP`, `ADKNA`, and `S-IgG1`) and&#x20;**<kbd>**temporal variables**</kbd>**:** indicating that some antibody levels increased with time after infection.



{% columns %}
{% column %}
**Figure a.** PCA plot representing integrated immunological data grouped by `Timpoint`

<figure><img src="../../.gitbook/assets/CP_timepoint_PCA indiv grouped plot.png" alt=""><figcaption></figcaption></figure>

**Figure c.** A PCA biplot showing immunological data points grouped by responder status, with a variable correlation plot overlayed.

<figure><img src="../../.gitbook/assets/CP_responder_PCA indiv biplot (1).png" alt=""><figcaption></figcaption></figure>


{% endcolumn %}

{% column %}
**Figure b.** A PCA biplot showing immunological data points grouped by disease severity, with a variable correlation plot overlayed.

<figure><img src="../../.gitbook/assets/CP_disease_PCA indiv biplot.png" alt=""><figcaption></figcaption></figure>

**Figure d.** Correlations of immunological parameters with time components (`days pso`, `Timepont`). Black boxes indicated clusters.

<figure><img src="../../.gitbook/assets/CP_clustered correlation_all immune assays_days pso timepoints.png" alt=""><figcaption></figcaption></figure>


{% endcolumn %}
{% endcolumns %}



***

### Predictive Summary

Through predictive analysis, we addressed the second objective to predict pre-defined long-term antibody responder status based on early immune signatures.

**Best Model:** `sparseLDA`

**Metrics:** Train AUC=0.9056, Test AUC=1, Precision=0.9333, Accuracy=0.8824

**ROC Curves:** train AUROC = 0.92, test AUROC = 1

<figure><img src="../../.gitbook/assets/CP_Phase 5_sparseLDA ROC Curves v2.png" alt=""><figcaption></figcaption></figure>

**Top Features:** The top features are shown in the graph below. Similar to those found in the reference paper, top features include, `N-IgG`, `ADCD`, `psuedoNA Abs`, `S-IgG`, `M T cells elispot`, `S1 T cells EliSpot`, `Total pos T cells ELISpot`, and `S2 T Cell ELISPOT`. Notably, the top features are a mix of antibody and T-cell responses, with antibody N-IgG contributing most to the model.

<figure><img src="../../.gitbook/assets/CP_Phase 5_Variable Importance Plot_sparseLDA.png" alt=""><figcaption></figcaption></figure>

**Interpretation:** The sparseLDA model can effectively predict responder outcome from early timepoint (28 days pso) immunological features, with T-Cell and antibody responses providing the greatest predictive power. Thus, suggesting that T-cells and antibodies play an important role in durability against SARS-CoV-2. The model performance and top features validate results in the reference paper, which contained the same top features and had similar AUROC performance (train=0.96, test=1).

***

### Conclusion

Our analysis demonstrated that longitudinal immune responses following SARS-CoV-2 infection evolve from an initial similar immunological state into more distinct profiles over time. The heterogeneity of these profiles, however, is not solely explained by disease severity, with the mild severity data presenting three distinct immunophenotypes. Our principal component analysis and correlation analysis revealed temporal shifts in antibody and T cell responses, indicating declining T cell activity alongside slight increases in antibody features as time from infection progressed.

Complementing findings from our exploratory analysis, predictive analysis showed that responder status at six months post symptom onset can accurately be predicted from early immunological measurements (day 28 pso). The most influential predictors included a combination of antibody and T cell features, indicating a joint contribution of humoral and cellular immunity in long-term durability for SARS-CoV-2.

Overall, the results indicate that early immunological signatures are sufficient in capturing biological variation for the robust prediction of long-term antibody responders (durable status). Additionally, results from this analysis validate findings from the reference paper [**Divergent trajectories of antiviral memory after SARS-CoV-2 infection**](https://doi.org/10.1038/s41467-022-28898-1)**.**

