---
icon: table
---

# Phase 3: Data Preparation for Predictive Modelling

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
