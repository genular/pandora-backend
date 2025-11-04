---
description: >-
  How to isolate certain part of the data for our predictive model for
  determining early parameters that lead to durable immunity
hidden: true
icon: table
---

# Phase 4: Data pre-processing

The goal of our predictive model is to determine early immune signatures that can predict the durability of person's immune response to SARS-CoV-2 infection. In terms of our data, we aim to use an early timepoint, specifically **28 days post onset of SARS-CoV-2 symptoms** (days 21-41 for asymptomatic samples), to predict the **responder status** of the health care workers, which was calculated based on the **titer of the anti-nucleocapsid-specific antibodies measured 6 months post symptoms onset.**&#x20;

Below provided in the procedure on how to filter the data for this task. This step requires data manipulation **outside** of PANDORA using programming tools like Python and R. An example of the procedure using Python has also been provided below.&#x20;

<details>

<summary>Procedure for data manipulation </summary>

* Start with the original [durability.csv](../../).
* **Filter Samples:** Select only the samples corresponding to an _**early**_**&#x20;timepoint**, specifically **Day 28 post-symptom onset** ( `Days pso` = 28)or equivalent for asymptomatic (`Days pso` roughly between 21-41).
* **Select Features:** Keep all **immunological assay** columns, relevant baseline demographics (`Age`, `Sex`), and initial `Disease severity`.
* **Merge Outcome:** For each unique Donor ID in the filtered Day 28 dataset, find the corresponding `Responder` status value (which is defined based on the Day 180 measurement for that donor) and add it as a new column to the Day 28 data.&#x20;

{% hint style="warning" %}
Ensure each Donor ID appears only once in the final predictive dataset
{% endhint %}

* **Save:** Save this curated table as a new CSV file&#x20;
  * Example: `durability_day28_predictors_month6_outcome.csv`

</details>

<details>

<summary>Python example for filtering data </summary>

```python
import pandas as pd

# Load the original dataset
df = pd.read_csv('covid_pitch.csv')

# Step 1: Filter Samples - select samples corresponding to an early timepoint, specifically Day 28 pso or equivalent (Days pso roughly between 21-41)
day28_df = df[(df['Days pso'] >= 21) & (df['Days pso'] <= 41)].copy()

# Step 2: Select Features
# Remove all columns that are not immunological assay columns, demographics (Age, Sex), Disease severity, Donor ID, and Days pso
remove_columns = ['Fever', 'Cough', 'Change or loss of taste', 'Anosmia', 'Fatigue', 
                  'Shortness of breath', 'Nasal congestion', 'Sore throat', 'Myalgia', 
                  'Arthralgia', 'Headache', 'Diarrhoea', 'Vomiting', 'Nausea', 
                  'Chest pain', 'Anorexia', 'Asthma', 'Timepoint', 'Responder']

# Keep all columns except the remove columns 
feature_columns = [col for col in df.columns if col not in remove_columns] 
day28_df = day28_df[feature_columns]

# Step 3: Obtain and merge Responder status from Day 180
day180_df = df[df['Timepoint'] == 180][['ID', 'Responder']].dropna()
final_df = day28_df.merge(day180_df, on='ID', how='inner')

# Ensure each Donor ID appears only once (should already be the case since we filtered via Days pso)
final_df = final_df.drop_duplicates(subset=['ID'])

# Step 4: Save the curated table
final_df.to_csv('covid_pitch_day28_predictors_month6_outcome.csv', index=False)
```



</details>

Now that we have our filtered dataset, we are ready to start the predictive modelling on the next phase!&#x20;
