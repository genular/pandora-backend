---
icon: flag-checkered
---

# Phase 6: findings

Report the best model and its test set performance (e.g., AUC). List the top predictors identified via **Variable Importance**. Describe insights from confounder analysis (Phase 3) and **Model Interpretation** (if applicable). Discuss the biological relevance of the top predictors.

<details>

<summary>1. Combine Findings</summary>

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

<summary>2. Analyze GO Terms &#x26; Biological Themes</summary>

The GO terms present in your dataset are a result of pathway enrichment analysis, which is a powerful tool external to PANDORA that helps identify biological themes from gene expression. You can use GO term databases to identify GO terms to uncover overall biological themes in responder groups and model prediction.

* Pathway Enrichment Analysis Tools:
  * clusterProfiler in R
  * DAVID
  * Metascape
  * Enrichr
*   GO term databases

    * GO
    * KEGG
    * Reactome



GO Terms alongside predictive variables can be used to identify biological themes using the following workflow:

1. Identify GO terms from your top predictors
   1. Open the Gene Ontology Resource [webpage](https://geneontology.org/)
   2. Search for all your top GO predictive terms in the form GO:#
      1. i.e. `GO:0070206`, `GO:1903214`
   3. Click term history to see ancestor chart, child terms, and co-occurring terms
   4. Create a list of all biological processes and themes related to your GO Terms
2. Check the expression levels of baseline terms in responder groups
   1. Select your predictive processed dataset from the Workspace (This dataset should only contain baseline features and your responder columns)
   2. Navigate to **Discovery** -> **Start** -> **Hierarchical Clustering**
   3.  Configure Clustering **Column Selection**

       1. Select your Responder column for the **Columns**
       2. Set **First (n) rows** such that it is larger than the total number of baseline features



       <figure><img src="../.gitbook/assets/FF_Phase 6_Clustering Column Selection.png" alt="" width="375"><figcaption></figcaption></figure>
   4.  Configure Clustering **Display Options**

       1. Enable **Grouped display**
       2. Select the responder column for **Grouped column**

       <figure><img src="../.gitbook/assets/FF_Phase 6_Clustering Display Options.png" alt="" width="375"><figcaption></figcaption></figure>
   5. Click **Plot image**
3.  Analyze the resultant heatmap

    1. Take note on how the expression of top predictive variables varies among the responder classes.
    2. With biological themes in mind from predictive variables and top GO terms, consider the biological themes among responder classes.



    <figure><img src="../.gitbook/assets/Baseline Feature Responder Group Heatmap.png" alt="" width="375"><figcaption></figcaption></figure>
4. Make plots reflecting biological themes (optional)
   1. Outside of PANDORA, you may create additional plots, such as radar plots, reflecting the different immune profiles of responder classes based on the baseline or fold change expression levels of features in each class.

</details>

You've now identified and analyzed your strongest model through consideration of model performance, biological interpretation, and confounder analysis. By pulling all your analysis together, you have now created a comprehensive picture of your model to draw biologically relevant insights from.
