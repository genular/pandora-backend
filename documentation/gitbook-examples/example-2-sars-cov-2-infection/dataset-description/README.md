---
icon: '2'
---

# Dataset Description

This dataset contains a mixture of categorical **clinical parameters** (clinical symptoms, disease severity) and numerical **immunological parameters** (immunoglobin, T cells, memory B cells, antibodies) taken over a period of 6 months, denoted by timepoint and days post onset of symptoms, along with basic demographics (age, sex) for each donor.&#x20;

For more details about each variable, see the [**variable legend**](variable-legend.md) for this dataset&#x20;

<figure><img src="../../.gitbook/assets/CP_Dataset overview_natcomm paper.png" alt=""><figcaption><p>Figure 1. Clinical study overview (<em>Tomic, A et al. NatComm, 2022)</em></p></figcaption></figure>

### Clinical Parameters&#x20;

These variables consist of clinical symptoms most commonly associated with SARS-CoV-2 infection, along with the severity of disease experienced by the donors&#x20;

<details>

<summary><span data-gb-custom-inline data-tag="emoji" data-code="1f4cb">📋</span>Clinical Symptoms </summary>

Common symptoms for SARS-CoV-2 infection:

* `Fever`&#x20;
* `Cough`
* `Change or loss of taste`&#x20;
* `Anosmia` : Complete loss of sense of smell
* `Fatigue`&#x20;
* `Shortness of breath`
* `Nasal congestion`
* `Sore throat`
* `Myalgia` : Muscle pain or soreness
* `Arthralgia` : Joint pain&#x20;
* `Headache`
* `Diarrhoea`
* `Vomiting`
* `Nausea`
* `Chest pain`
* `Anorexia` : Excessive weight loss
* `Asthma`

</details>

<details>

<summary><span data-gb-custom-inline data-tag="emoji" data-code="1f637">😷</span>Disease Severity </summary>

* `Asymptomatic`: Donor presents on symptoms while infected&#x20;
* `Mild`: Donor presents with moderate symptoms upon infection&#x20;
* `Severe`: Donor presents with more extreme symptoms upon infection

</details>

### Immunological Parameters&#x20;

These variables comprise of various immunological assays that quantify immune parameters such as T cells, memory B cells, antibodies and associated processes to obtain a comprehensive view of the cellular and humoral adaptive immune responses.&#x20;

<details>

<summary><span data-gb-custom-inline data-tag="emoji" data-code="1f6e1">🛡️</span>Antibodies </summary>

* **Pseudo-Neutralisating Antibodies (**`pseudoNA Abs`**)**: Concentration of neutralizing antibodies to inhibit infection by a SARS-CoV-2 pseudovirus determines efficacy of the donor's antibodies
* **Antibody-Dependent Effector Functions**: Effector functions such as monocyte phagocytosis (`ADMP`) and NK cell activation (`ADNKA`) give insight to how antibodies are neutralizing the virus&#x20;
* **Immunoglobin Assays**: Provides measurements of antibodies specific to SARS-CoV-2 proteins both in the mucous membranes (`S-IgA`) and circulating in the blood (`N-IgG`, `S-IgG` )
* **Meso Scale Discovery (MSD) Assays**: Gives insight to whether the donor's antibodies provide protection against various coronavirus strains (e.g. 229e, NL63) and other respiratory viruses (e.g. MERS)

</details>

<details>

<summary>🦠T cells</summary>

* **SARS-CoV-2 protein-specific T cell responses**: Conveys proteins of the SARS-CoV-2 virus the T cells of the donor reacts to most by measuring concentration of T cells specifically responding to each protein (e.g. ORF3, nsp3b, S1)&#x20;
* **T cell proliferative responses**: Provides insight into which SARS-CoV-2 proteins are most targeted by the CD4 and CD8 cells by measuring their proliferation for each protein&#x20;

</details>

<details>

<summary><span data-gb-custom-inline data-tag="emoji" data-code="1f9ea">🧪</span>B cells</summary>

* **Spike-specific IgG+ Memory B cells**: Concentration of memory B cells specific to seasonal coronavirus stains gives insight to the durable immunity the body has to the various viruses

</details>

### Responder Status&#x20;

The **seropositivity** of the donors at 6 months post symptoms onset determined whether the donor was a **low or high responder**. This seropositivity was calculated by the titer of the anti-nucleocapsid-specific antibodies. A titer of greater than or equal to 1.4 indicated seropositivity.&#x20;

### Demographic and Time variables&#x20;

<details>

<summary><span data-gb-custom-inline data-tag="emoji" data-code="1f465">👥</span>Demographics</summary>

* Age
* Sex

</details>

<details>

<summary><span data-gb-custom-inline data-tag="emoji" data-code="23f3">⏳</span>Time</summary>

* `Timepoint`: Day after positive infection diagnosis when sample was taken
* `Days pso`: Days after onset of symptoms&#x20;

</details>
