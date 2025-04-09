# Dataset Description

The dataset contains **predictor variables** (baseline immune data, demographics, and transcriptomics) and **outcome variables** (vaccine responsiveness).

<figure><img src="../.gitbook/assets/baseline predictive modeling overview.png" alt=""><figcaption><p> <strong>Figure 2. Overview of the baseline measurements included in the dataset.</strong></p></figcaption></figure>

**🧑‍🔬 Demographics**

* `subid1`: Unique participant ID.
* `sex` (🔵/🔴): Biological sex (`M` or `F`).
* `age_months`: Age of the participant in months.
* `z_score_continuous`: Weight-for-height Z-score (nutritional status).
* `year`: Year of sample collection (2017 or 2018).

**🧬 Baseline Immune Features**

* **Blood Transcriptomics**: Pathway activity captured by **Gene Ontology (GO)** terms, e.g., `blood_baseline_go.0006415` (translation).
* **Nasal Transcriptomics**: Pathway activity in nasal samples, e.g., `nasal_baseline_go.0006968` (defense response to virus).
* **Immune Cell Subsets**:
  * `v0_mdcs`: Myeloid dendritic cells (mDCs).
  * `v0_pdcs`: Plasmacytoid dendritic cells (pDCs).
  * `v0_classical_monocytes`, `v0_intermediate_monocytes`, `v0_nonclassical_monocytes`: Monocyte subsets.
* **Viral and Bacterial Load**:
  * `v0_resp_virus_positive`: Presence of 14 different respiratory viruses (flu, adenoviruses, rhinoviruses, coronaviruses, etc.) detected via RT-PCR at baseline.
  * `v0_pneumo_ng_log10copies_ul`: Nasal _Streptococcus pneumoniae_ density (log10 copies per µL).

**🎯 Outcome Variables**

**🔬 Vaccine Responsiveness**

These variables measure vaccine-induced immune responses across humoral, cellular, and mucosal immunity:

**Humoral Responses**

* `h1_hai_gmt_fold_change`: Responsiveness in HAI titers for H1N1 (serum antibody response blocking virus-host interaction).
* `h3_hai_gmt_fold_change`: Responsiveness in HAI titers for H3N2.
* `ph1n1_ha_iga_fold_change`: Responsiveness in mucosal IgA binding to H1N1 hemagglutinin.

**Cellular Responses**

* `h1_cd4_ifng_fold_change`: Responsiveness in CD4+ IFN-γ T cell responses for H1N1 (cellular immunity indicator).
* `h3_cd8_il2_fold_change`: Responsiveness in CD8+ IL-2 T cell responses for H3N2.

**IVPM Antibody Binding**

* `nc99_ivpm_h1_fold_change`: Responsiveness in antibody binding to HA from A/New Caledonia/20/1999, measured using a high-throughput HA microarray platform which allows to test presence of antibodies that can bind vaccine-formulated influenza starins and historical and drifted inlfuenza strains not included in the vaccine forumation.
