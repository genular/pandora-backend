---
icon: '2'
---

# Dataset Description

The dataset contains **input features** (Objective, Examination, Subjective) and a **target variable** indicating the presence or absence of cardiovascular disease. For our hypothetical trial, we will add a `TreatmentGroup` column.

<figure><img src="https://placehold.co/600x300/EBF4FF/7F9CF5?text=Figure+1:+CardioGuard+Trial+Data+Structure" alt="Figure 1: CardioGuard Trial Data Structure"><figcaption><p><strong>Figure 1. CardioGuard Trial Data Structure.</strong> This includes baseline patient data, lifestyle factors, examination results, treatment allocation, and the cardiovascular disease outcome.</p></figcaption></figure>

#### Input Features (Baseline & Examination)

These variables are measured at baseline or during examination periods.

<details>

<summary><strong>👤 Objective Features</strong></summary>

* `PatientID` (Hypothetical): Unique identifier for each patient.
* `Age`: Age | int (days)
* `Height`: Height | int (cm)
* `Weight`: Weight | float (kg)
* `Gender`: Gender | categorical code (e.g., 1 for male, 2 for female, or similar coding)
* `TreatmentGroup` (Hypothetical, added for the trial): Assigned treatment (`CardioGuard` or `Placebo`). **This is the key variable for assessing drug efficacy.**

</details>

<details>

<summary><strong>🩺 Examination Features</strong></summary>

* `ap_hi`: Systolic blood pressure | int
* `ap_lo`: Diastolic blood pressure | int
* `cholesterol`: Cholesterol level | 1: normal, 2: above normal, 3: well above normal (categorical)
* `gluc`: Glucose level | 1: normal, 2: above normal, 3: well above normal (categorical)

</details>

<details>

<summary><strong>📝 Subjective Features</strong></summary>

* `smoke`: Smoking | binary (0: no, 1: yes)
* `alco`: Alcohol intake | binary (0: no, 1: yes)
* `active`: Physical activity | binary (0: no, 1: yes)

</details>

#### Target Variable

This variable indicates the primary outcome of interest.

<details>

<summary><strong>❤️ Cardiovascular Disease Status</strong></summary>

* `cardio`: Presence or absence of cardiovascular disease | binary (0: no, 1: yes)

</details>
