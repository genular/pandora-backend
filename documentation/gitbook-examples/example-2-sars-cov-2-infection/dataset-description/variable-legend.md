# Variable Legend



<details>

<summary>Timepoint <span data-gb-custom-inline data-tag="emoji" data-code="1f559">🕙</span></summary>

**Variables**&#x20;

* `Timepoint`

**Description**

* This variable represents the day the sample was acquired after a positive SARS-CoV-2 PCR test was received&#x20;
* Most donors had samples taken at&#x20;
  * Day 1: When donor tested positive for SARS-CoV-2 (Within acute phase of infection)
  * Day 28: \~ 1 month post infection (near start of convalescent phase)
  * Day 56: \~ 2 months post infection&#x20;
  * Day 90: \~ 3 months post infection&#x20;
  * Day 120: \~ 4 months post infection&#x20;
  * Day 180: \~ 6 months post infection

</details>

<details>

<summary>Disease Severity <span data-gb-custom-inline data-tag="emoji" data-code="1f637">😷</span></summary>

**Variables**&#x20;

* `Disease severity`

**Description**

* Categorical variable describing the severity of the SARS-CoV-2 symptoms experienced by the donors
* The donors would be classified as `asymptomatic` if no symptoms were present, and symptomatic donors were classified as `mild` or `severe`

</details>

<details>

<summary>Clinical Symptoms <span data-gb-custom-inline data-tag="emoji" data-code="1f321">🌡️</span></summary>

**Variables**&#x20;

* `Fever` , `Cough`, `Change or loss of taste`, `Anosmia`, `Fatigue`, `Shortness of breath`, `Nasal congestion`, `Sore throat`, `Myalgia`, `Arthralgia`, `Headache`, `Diarrhoea`, `Vomiting`, `Nausea`, `Chest pain`, `Anorexia`, `Asthma`

**Description**

* Categorical variables describing whether a donor reported having symptoms specific to SARS-CoV-2 infection&#x20;
* These variables are assigned **binary values**, with `0` indicating the donor did not present that symptom and `1` indicating that the donor reported that symptom when sample was taken

</details>

<details>

<summary>Demographics <span data-gb-custom-inline data-tag="emoji" data-code="1f464">👤</span></summary>

**Variables**&#x20;

* `Sex` , `Age`

**Description**

* **Sex**: Donors were assigned as male (`m`) or female (`f`)
* **Age**: Age of donor determined in years

</details>

<details>

<summary>Pseudo-Neutralisating Antibodies <span data-gb-custom-inline data-tag="emoji" data-code="1f6e1">🛡️</span>🦠</summary>

**Variables**&#x20;

* `pseudoNA Abs`&#x20;

**Description**

* A measurement of the concentration of neutralizing antibodies from a donor sample required to inhibit 50% of the infection by a SARS-CoV-2 pseudovirus&#x20;
* Briefly, this experiment is performed by incubating a plasma sample from a donor with a lentivirus-based SARS-CoV-2 pseudovirus particle expressing the spike protein. The mixture is then incubated with HEK 293 ACE2-transfected cells.
* Neutralisation titers are reported as the reciprocal of the plasma dilution conferring 50% inhibition (ID50) of pseudovirus infection

</details>

<details>

<summary>Antibody-Dependent Effector Functions <span data-gb-custom-inline data-tag="emoji" data-code="1f9ea">🧪</span><span data-gb-custom-inline data-tag="emoji" data-code="1f6e1">🛡️</span></summary>

**Variables**&#x20;

* `ADCD` , `ADMP` , `ADNKA`, `ADNP`

**Description**

* A measurement of the effector function activity of the antibodies in relation to the neutralisation of the virus&#x20;
* Variable names:&#x20;
  * `ADCD`: Antibody-dependent complement deposition&#x20;
  * `ADMP`: Antibody-dependent monocyte phagocytosis
  * `ADNKA`: Antibody-dependent NK cell activation&#x20;
  * `ADNP`: Antibody-dependent neutrophil phagocytosis&#x20;

</details>

<details>

<summary>SARS-CoV-2 protein-specific T cell responses 🦠🔬</summary>

**Variables**&#x20;

* `M T cells elispot` , `NP T cells elispot`, `nsp3b T cells elispot` , `ORF3 T cells elispot`, `S1 T cells elispot`, `S2 T cells elispot`, `Total pos T cells elispot`

**Description**

* These are variables that were measured using interferon-gamma enzyme-linked immunospot (ELISpot) assays. Specifically, this assay was used to measure T cells that recognize varying proteins in the virus
* Variable names:&#x20;
  * `M T cells elispot` , `NP T cells elispot`, `nsp3b T cells elispot` , `ORF3 T cells elispot`, `S1 T cells elispot`, `S2 T cells elispot` : The first term in the variable name (`M`, `NP`, `nsp3b`, `ORF3`, `S1`, `S2`) are **SARS-CoV-2 proteins**. Hence the T cells variables are measuring the number of T cells that specifically respond to their corresponding protein.&#x20;
  * `Total pos T cells elispot`: Total T cells measured using the CEFT positive control peptides

</details>

<details>

<summary>Days post symptoms onset <span data-gb-custom-inline data-tag="emoji" data-code="231b">⌛</span></summary>

**Variables**&#x20;

* `Days pso`&#x20;

**Description**

* This variable refers to the number of days after the onset of symptoms for a donor&#x20;

</details>

<details>

<summary>Immunoglobin Assays - Antibody responses <span data-gb-custom-inline data-tag="emoji" data-code="1f6e1">🛡️</span><span data-gb-custom-inline data-tag="emoji" data-code="1f52c">🔬</span></summary>

**Variables**&#x20;

* `S-IgA` , `S-IgG1` ,`S-IgG2` ,`S-IgG3` , `S-IgG4` , `S-IgM` ,  `S-IgA memB SARS-CoV2` , `S-IgG memB SARS-CoV2` , `N-IgG`, `S-IgG`

**Description**

* These variables refer to the concentrations of various immunoglobin antibodies with different targets&#x20;
* Variable names:&#x20;
  * `S-IgA`: Concentration of immunoglobin A antibodies targeting the spike protein&#x20;
  * `S-IgG`: Concentration of immunoglobin G antibodies targeting the spike protein
  * `S-IgG1` ,`S-IgG2` ,`S-IgG3` , `S-IgG4`: Concentration of immunoglobin G subclasses targeting the spike protein
  * `S-IgM`: Concentration of immunoglobin M antibodies targeting the spike protein&#x20;
  * `S-IgA memB SARS-CoV2`: Concentration of immunoglobin A antibodies produced by memory B cells specific to the spike protein&#x20;
  * `S-IgG memB SARS-CoV2`: Concentration of immunoglobin G antibodies produced by memory B cells specific to the spike protein&#x20;
  * `N-IgG`: Concentration of immunoglobin G antibodies targeting the nucleoprotein

</details>

<details>

<summary>Spike-specific IgG+ Memory B cells <span data-gb-custom-inline data-tag="emoji" data-code="1f4ad">💭</span>🦠</summary>

**Variables**&#x20;

* `memB 229E` , `memB HKU1` ,`memB NL63` ,`MemB OC43` , `B cells elispot`

**Description**

* These variables refer to the concentration of memory B cells that react to various spike proteins in different types of coronavirus
* Variable names:&#x20;
  * `B cells elispot`refers to the number of memory B cells specific to the general SARS-CoV-2 spike glycoprotein
  * `memB 229E` , `memB HKU1` ,`memB NL63` ,`MemB OC43`refer to the number of memory B cells specific to the coronavirus strain in the variable name. These are seasonal coronaviruses&#x20;

</details>

<details>

<summary>Meso Scale Discovery (MSD) Assays<span data-gb-custom-inline data-tag="emoji" data-code="1f52c">🔬</span><span data-gb-custom-inline data-tag="emoji" data-code="1f9ea">🧪</span></summary>

**Variables**&#x20;

* `229e MSD` , `SARS-CoV1 S MSD`, `SARS-CoV2 N MSD`, `SARS-CoV2 RBD MSD`, `SARS-CoV2 S MSD`, `HcoV-HKU1 S MSD`, `MERS S MSD`, `NL63 S MSD`, `OC43 S MSD`

**Description**

* These variables are the measurements of antibody levels to various virus spike proteins and other relevant antigens via a MSD multiplexed immunoassay&#x20;
* Variable names:&#x20;
  * `229e MSD`, `HcoV-HKU1 S MSD`, `NL63 S MSD`, `OC43 S MSD`: Antibody levels in response to seasonal coronavirus spike proteins
  * `SARS-CoV1 S MSD`: Antibody levels in response to SARS-CoV-1 coronavirus spike protein
  * `SARS-CoV2 S MSD`: Antibody levels in response to SARS-CoV-2 coronavirus spike protein
  * `SARS-CoV2 N MSD`: Antibody levels in response to SARS-CoV-2 coronavirus nucleoprotein
  * `SARS-CoV2 RBD MSD`: Antibody levels in response to SARS-CoV-2 coronavirus receptor-binding domain&#x20;
  * `MERS S MSD`: Antibody levels in response to Middle East Respiratory Syndrome (MERS) spike protein

</details>

<details>

<summary>T cell proliferative responses 🦠🔬</summary>

**Variables**&#x20;

* `Proliferation M CD4`, `Proliferation M CD8`, `Proliferation NP CD4`, `Proliferation NP CD8`, `Proliferation ORF3 CD4`, `Proliferation ORF3 CD8`, `Proliferation ORF8 CD4`, `Proliferation ORF8 CD8`, `Proliferation S1 CD4`, `Proliferation S1 CD8`, `Proliferation S2 CD4`, `Proliferation S2 CD8`

**Description**

* These variables are the measurement of T cell (specifically CD4 and CD8 T cells) proliferative responses against various SARS-CoV-2 proteins&#x20;

</details>

<details>

<summary>Responder <span data-gb-custom-inline data-tag="emoji" data-code="1f6e1">🛡️</span><span data-gb-custom-inline data-tag="emoji" data-code="1f4aa">💪</span></summary>

**Variables**&#x20;

* `Responder`&#x20;

**Description**

* This variable refers to the outcome of immune response durability. A donor is assigned a status of `low` or `high` responder&#x20;
* Responder status was calculated based on the titer of the anti-nucleocapsid-specific antibodies measured 6 months post symptoms onset.
* anti-N Ab titer ≥ 1.4 = High responder (seropositive). Low responders were donors who were seronegative&#x20;



</details>
