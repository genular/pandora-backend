---
hidden: true
---

# Phase 6: Synthesize Findings

### Purpose

Report the best model and its test set performance (e.g., AUC). List the top predictors identified via **Variable Importance**. Describe insights from confounder analysis (Phase 3) and **Model Interpretation** (if applicable). Discuss the biological relevance of the top predictors.

***

### Action:

<details>

<summary>1 - Combine Findings</summary>

1. Identify the top model from phase 4 by considering
   * Model performance metrics
   * ROC Curves
   * Biological relevance of top predictors in Variable Importance
   * Confounder Check (phase 3)
2.  Pull together all your findings, including

    * Clustered t-SNE plots for responder classification, if applicable (Phase 2)

    <figure><img src="../.gitbook/assets/FF_Phase6_Clustered tSNE Plot.png" alt="" width="375"><figcaption></figcaption></figure>

    * t-SNE plots and analysis from Confounder check (Phase 3)

    <figure><img src="../.gitbook/assets/FF_Phase  3_Age vs HAI Responder (1).png" alt="" width="563"><figcaption></figcaption></figure>

    * Model performance metrics (Phase 4)

    <figure><img src="../.gitbook/assets/FF_Phase 5_Training Summary Box Plots.png" alt="" width="375"><figcaption></figcaption></figure>

    * Training and Testing ROC Curves

    <figure><img src="../.gitbook/assets/FF_Phase 5_Combined ROC Curves RF.png" alt="" width="563"><figcaption></figcaption></figure>

    * Model Interpretation plots, if applicable

    <figure><img src="../.gitbook/assets/FF_Phase 5_Model Interp Heatmap RF.png" alt="" width="375"><figcaption></figcaption></figure>

    * Variable Importance bar plot

    <figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Variable Importance Plot_white background.png" alt="" width="375"><figcaption></figcaption></figure>

    * Features across dataset dot plots for top predictive features

    <figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Features Across Dataset Plot.png" alt="" width="375"><figcaption></figcaption></figure>

</details>

<details>

<summary>2 - GO Term Pathway Enrichment Analysis (if applicable)</summary>

Pathway enrichment analysis is performed outside of PANDORA and is a powerful tool to understand the biological themes underlying top predictive GO terms that may be present in your model.

* Pathway Enrichment Analysis Tools:
  * clusterProfiler in R
  * DAVID
  * Metascape
  * Enrichr
*   GO term databases

    * GO
    * KEGG
    * Reactome



Provided below is an example workflow using Metascape:

1. Identify GO terms from your top predictors
   1. Open the Gene Ontology Resource [webpage](https://geneontology.org/)
   2. Search for all your top GO predictive terms in the form GO:#
      1. i.e. `GO:0070206`, `GO:1903214`
   3.  On the page for the GO terms, download a list of all associated gene names

       * Open GO Term page and click download

       <figure><img src="../.gitbook/assets/FF_Phase 6_Download GO Terms (1).png" alt=""><figcaption></figcaption></figure>

       * Select only bioentity

       ![](<../.gitbook/assets/FF_Phase 6_GO Terms Select Fields.png>)

       * Click download
       * Copy and paste terms from report page into a single column in a spreadsheet (continue building this list for all genes in the top GO terms)

1) Run analysis on metascape.org
   1. Open metascape.org
   2. Upload the Excel file containing your list of genes
   3. Select H. Sapiens as species
   4. Click Express Analysis

<figure><img src="../.gitbook/assets/FF_Phase 6_Metascape Config.png" alt=""><figcaption></figcaption></figure>

3. View **Analysis Report Page** to identify biological themes among the top GO terms.

<figure><img src="../.gitbook/assets/FF_Phase 6_Metascape Report.png" alt=""><figcaption></figcaption></figure>

</details>

***

### Summary

You've now identified and analyzed your strongest model through consideration of model performance, biological interpretation, and confounder analysis. By pulling all your analysis together, you have now created a comprehensive picture of your model to draw biologically relevant insights from.
