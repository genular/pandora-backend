---
icon: '1'
---

# Introduction

This workflow demonstrates how to use PANDORA to analyze data from a hypothetical clinical trial for "[CardioGuard](https://www.kaggle.com/datasets/sulianova/cardiovascular-disease-dataset)," a new investigational drug designed to reduce the risk or impact of cardiovascular disease.

**The primary objectives are to:**

1. Assess the effectiveness of CardioGuard by modeling its impact on the presence or absence of cardiovascular disease (`cardio` target variable).
2. Develop a predictive model to identify individuals at higher or lower risk of cardiovascular disease, and how CardioGuard modifies this risk.
3. Explore baseline patient characteristics and examination features that predict cardiovascular disease status in the context of the trial.



The dataset contain data from a cohort of individuals, some of whom might be at risk for cardiovascular disease. They are randomized to receive either CardioGuard or a placebo.

{% file src="../.gitbook/assets/cardioguard_trial_data.csv" %}
The dataset consists of 70 000 records of patients data, 11 features + target.
{% endfile %}
