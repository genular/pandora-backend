# Dataset Description

The dataset contains **predictor variables** (baseline immune data, demographics, and transcriptomics) and **outcome variables** (vaccine responsiveness).

<figure><img src="../../.gitbook/assets/baseline predictive modeling overview.png" alt=""><figcaption><p> <strong>Figure 2. Overview of the baseline measurements included in the dataset.</strong></p></figcaption></figure>

### Predictor variables

These variables comprise demographic characteristics (e.g., age, sex, ethnicity) and pre-vaccination immune features measured before vaccine administration (baseline).

<details>

<summary><strong>🧬 Baseline Immune Features</strong></summary>



* **Blood Transcriptomics**: Pathway activity captured by **Gene Ontology (GO)** terms, e.g., `blood_baseline_go.0006415` (translation).

- **Nasal Transcriptomics**: Pathway activity in nasal samples, e.g., `nasal_baseline_go.0006968` (defense response to virus).

* **Immune Cell Subsets**:
  * `v0_mdcs`: Myeloid dendritic cells (mDCs).
  * `v0_pdcs`: Plasmacytoid dendritic cells (pDCs).
  * `v0_classical_monocytes`, `v0_intermediate_monocytes`, `v0_nonclassical_monocytes`: Monocyte subsets.
* **T cell Cytokine Production:**
  * `v0_cd4` : Measure of cytokine production by CD4+ T cells in response to influenza antigens
  * `v0_cd8` : Measure of cytokine production by CD8+ T cells in response to influenza antigens
  * Further classified by cytokines measured (`ifng`, `il2`) cells and the associated influenza strains (`h3`, `hmnp`, `hab`, `bmnp`)
    * ie. `h1_v0_cd4_ifng`,  `h3_v0_cd4_il2`

- **Viral and Bacterial Load**:
  * `v0_resp_virus_positive`: Presence of 14 different respiratory viruses (flu, adenoviruses, rhinoviruses, coronaviruses, etc.) detected via RT-PCR at baseline.
  * `v0_pneumo_ng_log10copies_ul`: Nasal _Streptococcus pneumoniae_ density (log10 copies per µL).
- **Nutrition Status:**
  * `z_score_continuous`: Weight-for-height Z-score (nutritional status).

</details>

### Outcome variables

These variables measure vaccine-induced immune responses across humoral, cellular, and mucosal immunity. Fold change corresponds to the magnitude change between measurements at baseline and measurements 21 days post-vaccination.

<details>

<summary><span data-gb-custom-inline data-tag="emoji" data-code="1f9ea">🧪</span> Humoral Responses</summary>



* `h1_hai_gmt_fold_change`: Responsiveness in HAI titers for H1N1 (serum antibody response blocking virus-host interaction).

- `h3_hai_gmt_fold_change`: Responsiveness in HAI titers for H3N2.

* `ph1n1_ha_iga_fold_change`: Responsiveness in mucosal IgA binding to H1N1 hemagglutinin.

</details>

<details>

<summary><span data-gb-custom-inline data-tag="emoji" data-code="1f9eb">🧫</span> Cellular Responses</summary>

Fold change response variables for T-cell cytokine levels:

* Classified by cytokines measured (`ifng`, `il2`) cells and the associated influenza strains (`h1`, `h3`, `hmnp`, `hab`, `bmnp`)

- All CD4+ T cell fold change responses: `h1_cd4_ifng_fold_change`, `h1_cd4_il2_fold_change`, `h3_cd4_ifng_fold_change`, `h3_cd4_il2_fold_change`, `hmnp_cd4_ifng_fold_change`, `hmnp_cd4_il2_fold_change`, `hab_cd4_ifng_fold_change`, `hab_cd4_il2_fold_change`, `bmnp_cd4_ifng_fold_change`, `bmnp_cd4_il2_fold_change`
- All CD8+ T cell fold change responses: `h1_cd8_ifng_fold_change`, `h1_cd8_il2_fold_change` , `h3_cd8_ifng_fold_change`, `h3_cd8_il2_fold_change` , `hmnp_cd8_ifng_fold_change`, `hmnp_cd8_il2_fold_change` , `hab_cd8_ifng_fold_change`, `hab_cd8_il2_fold_change` , `bmnp_cd8_ifng_fold_change`, `bmnp_cd8_il2_fold_change`

</details>

<details>

<summary><span data-gb-custom-inline data-tag="emoji" data-code="1f9f2">🧲</span> IVPM Antibody Binding</summary>

`nc99_ivpm_h1_fold_change`: Responsiveness in antibody binding to HA from A/New Caledonia/20/1999, measured using a high-throughput HA microarray platform which allows to test the presence of antibodies that can bind vaccine-formulated influenza strains and historical and drifted influenza strains not included in the vaccine formulation.

</details>

For more information about all variables contained in the Flu Fighters dataset, please see the [Variable Legend](variable-legend.md)
