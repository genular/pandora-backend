---
icon: '3'
---

# CardioBoost Workflow

<details>

<summary>Phase 1: Data Configuration &#x26; Initial Exploration</summary>

**Purpose:** Upload the dataset, inspect its structure, handle missing data (if any), and perform initial exploratory data analysis to understand data distributions and basic relationships between features, treatment, and the `cardio` outcome.

**Actions:**

1. **Launch PANDORA & Upload Data:**
   * Start your PANDORA instance.
   * Navigate to **Workspace**.
   * Upload your `cardioguard_trial_data.csv` dataset (ensure it includes the hypothetical `TreatmentGroup` column: e.g., Placebo=0, CardioGuard=1).
   * Select the uploaded dataset for analysis.
2.  **Initial Data Inspection (Data Overview):**

    * Navigate to **Discovery** -> **Start** -> **Data Overview**.
    * Select key columns for initial review: `TreatmentGroup`, `Age`, `ap_hi`, `ap_lo`, `cholesterol`, `gluc`, `smoke`, `active`, and `cardio`.
    * Examine the **Distribution Plot** and **Table Plot**.
      * Check data types. Note that `cholesterol` and `gluc` are categorical. `Age` is in days; consider if transformation to years is needed outside PANDORA for easier interpretation, though models can handle raw days.
      * Assess distributions for variables like `ap_hi`, `ap_lo`.
      * Note any missing values (NAs).
    * In the **Side Panel**, under **Preprocessing**:
      * If NAs are present: `medianImpute` for numerical features (like `Weight`, `ap_hi`, `ap_lo` if they have NAs) or `knnImpute`. For categorical features with NAs (less common for `cholesterol` or `gluc` if coded 1/2/3, but possible), PANDORA's imputation might convert them or specific handling might be needed (e.g., imputing with mode).
      * Apply `center` and `scale` to numerical predictors, as this is generally good practice for many PANDORA models.
      * `zv` (zero variance) and `nzv` (near-zero variance) can be used.

    _(Conceptual PANDORA Screenshot)_

    ```
    [PANDORA Interface: Discovery -> Data Overview showing columns like 'ap_hi', 'cholesterol', 'TreatmentGroup', 'cardio', with distribution plots. Categorical nature of 'cholesterol' and 'gluc' visible.]
    ```
3.  **Explore Correlations:**

    * Navigate to **Discovery** -> **Correlation**.
    * **Column Selection:** Select `TreatmentGroup` (coded numerically), `Age`, `Height`, `Weight`, `ap_hi`, `ap_lo`, numerically coded versions of `cholesterol` and `gluc` (or understand how PANDORA handles categoricals here – it typically expects numeric input for standard correlation matrices), `smoke`, `alco`, `active`, and `cardio`.
    * **Correlation Method:** `Spearman` can be a good choice given mixed data types and potential non-linearities.
    * **Correlation Settings:**
      * `NA Action`: `pairwise.complete.obs`.
      * `Plot Method`: `circle` or `number`.
    * **Significance:** Enable significance testing and p-value adjustment (e.g., `BH`).
    * Click **Plot Image**.
    * **Interpretation:**
      * Examine the correlation between `TreatmentGroup` and `cardio`. A negative correlation would be hoped for if CardioGuard is effective (less `cardio`=1 in the CardioGuard group).
      * Look at correlations between risk factors (e.g., `ap_hi`, `cholesterol`, `smoke`) and `cardio`.

    _(Conceptual PANDORA Screenshot )_

    ```
    [PANDORA Interface: Discovery -> Correlation showing a correlogram. A circle/number indicating the correlation between a numerically coded 'TreatmentGroup' and 'cardio' would be of key interest, alongside known risk factors and 'cardio'.]
    ```

**Summary of Phase 1:** The dataset is uploaded and initially explored. Basic cleaning is considered. Preliminary correlations might offer early hints about the drug's association with the `cardio` outcome and highlight relationships between risk factors.

</details>

***

<details>

<summary>Phase 2: Understanding the Outcome Variable (`cardio`)</summary>

**Purpose:** The primary outcome variable `cardio` (Presence or absence of cardiovascular disease) is already defined and binary in your dataset. This phase focuses on understanding its prevalence and relationship with key baseline features.

**Actions:**

1. **Assess Prevalence of `cardio`:**
   * In **Discovery** -> **Data Overview**, select the `cardio` column.
   * The table plot or distribution plot (for a binary variable, it will show counts/proportions) will indicate the number of individuals with (`cardio`=1) and without (`cardio`=0) cardiovascular disease. This is important for understanding class balance for the subsequent classification modeling.
2.  **Initial Stratification (using PCA/t-SNE for visualization):**

    * Navigate to **Discovery** -> **Start** -> **PCA Analysis**.
    * **Column Selection:** Select all baseline predictor variables (Objective, Examination, Subjective features, excluding `PatientID` and `TreatmentGroup` from the PCA calculation itself).
    * **Preprocessing:** Ensure `center` and `scale` are applied to numerical features. Handle NAs. PANDORA should manage categorical features like `cholesterol`, `gluc`, `Gender` appropriately for PCA (often via MCA for categorical variables or dummy coding if numerical PCA is forced).
    * **PCA Settings:**
      * `Grouping Variable`: Select `cardio`.
      * Observe if individuals with and without cardiovascular disease form distinct clusters or overlap based on their baseline characteristics.
    * Click **Plot Image**.
    * **Interpretation:** This provides a visual sense of whether baseline profiles inherently separate those with and without the `cardio` outcome.

    _(Conceptual PANDORA Screenshot for PCA)_

    ```
    [PANDORA Interface: Discovery -> PCA Analysis -> Individuals Plot, with points colored by 'cardio' status. This helps visualize if baseline features differentiate those with vs. without cardiovascular disease.]
    ```

**Summary of Phase 2:** The prevalence of the `cardio` outcome is assessed, and initial visualizations explore how baseline characteristics relate to this outcome.

</details>

***

<details>

<summary>Phase 3: Confounding Variable Check</summary>

**Purpose:** Assess whether key baseline characteristics (e.g., `Age`, `Gender`, `Weight`, `ap_hi`, `cholesterol`) are evenly distributed across the `TreatmentGroup` (CardioGuard vs. Placebo). Significant imbalances in a randomized trial would be concerning.

**Actions:**

1. **Visualize Distributions by Treatment Group (using PCA or t-SNE):**
   * Navigate to **Discovery** -> **Start** -> **PCA Analysis** (or **t-SNE Analysis**).
   * **Column Selection:** Select all relevant baseline predictor variables (Objective, Examination, Subjective features).
   * **Preprocessing:** Ensure `center` and `scale` are applied to numerical features. Handle NAs.
   * **PCA Settings / t-SNE Settings:**
     * `Grouping Variable`: Select `TreatmentGroup`.
     * Observe if the CardioGuard and Placebo arms form distinct clusters or overlap significantly based on baseline characteristics. In a well-randomized trial, they should largely overlap.
   * Click **Plot Image**.
2.  **Compare Individual Confounders (Manual review or using Correlation if applicable):**

    * **Data Overview:** While PANDORA's Data Overview might not directly provide grouped summary statistics (e.g., mean age for placebo vs. mean age for CardioGuard), you can select individual confounders and visually inspect distributions.
    * **Correlation (from Phase 1):** Check the correlation matrix. Was there any strong, unexpected correlation between a baseline feature like `Age` and the numerically coded `TreatmentGroup`? This would be an issue.

    _(Conceptual PANDORA Screenshot for PCA)_

    ```
    [PANDORA Interface: Discovery -> PCA Analysis -> Individuals Plot, with points colored by 'TreatmentGroup'. Ideally, Placebo and CardioGuard groups should largely overlap, indicating good baseline balance from randomization.]
    ```

**Summary of Phase 3:** Potential confounding variables are checked for imbalances across treatment groups. This step is crucial for validating the randomization process.

</details>

***

<details>

<summary>Phase 4: Predictive Modeling for Cardiovascular Disease (`cardio`)</summary>

**Purpose:** Build a **classification model** to predict the `cardio` outcome (presence/absence of cardiovascular disease). The key goal is to determine if `TreatmentGroup` (CardioGuard vs. Placebo) is an important predictor.

**Actions (using PANDORA Predictive - SIMON):**

1. **Navigate to Predictive Modeling:**
   * Select your dataset in **Workspace**.
   * Navigate to **Predictive** -> **Start**.
2. **Setup for CLASSIFICATION Model (Predicting `cardio`):**
   * **Analysis Properties:**
     * Select **Classification** as the analysis type.
     * **Predictor Variables:**
       * **Include `TreatmentGroup` (ensure numerically coded: e.g., Placebo=0, CardioGuard=1).**
       * Include all other baseline Objective, Examination, and Subjective features (`Age`, `Height`, `Weight`, `Gender`, `ap_hi`, `ap_lo`, `cholesterol`, `gluc`, `smoke`, `alco`, `active`).
     * **Response:** Select `cardio`.
     * **Training/Testing Dataset Partition (%):** e.g., 75% for training, 25% for testing.
     * **Preprocessing:** Apply `center`, `scale` (for numerical predictors), appropriate NA handling (e.g., `medianImpute` or `knnImpute`), `zv`, `nzv`. PANDORA's models or preprocessing steps should handle the categorical nature of `cholesterol`, `gluc`, and `Gender` (e.g., through internal dummy coding).
   * **Model Selection and Customization:**
     * Select models suitable for binary classification (e.g., `glm` for logistic regression, `rf` - Random Forest Classifier, `C5.0`, `AdaBoost.M1`, `mlp` - Neural Network Classifier).
   * **Advanced Options:**
     * Consider enabling **Feature Selection**. This will help identify which variables (hopefully including `TreatmentGroup`) are most important for predicting `cardio`.
   * Click **Validate data**, then **Process**. Name this task appropriately (e.g., "CardioGuard\_Cardio\_Prediction").
3.  **Monitor Progress:** Check the **Dashboard** for model training completion.

    _(Conceptual PANDORA Screenshot for SIMON Setup)_

    ```
    [PANDORA Interface: Predictive -> Start (SIMON) showing 'Classification' selected. 'cardio' as Response. 'TreatmentGroup', 'Age', 'ap_hi', 'cholesterol', 'smoke', etc., as Predictors. Preprocessing options checked.]
    ```

**Summary of Phase 4:** A classification model is configured and run to predict cardiovascular disease status. The `TreatmentGroup` variable is included as a key predictor to assess the drug's potential impact.

</details>

***

<details>

<summary>Phase 5: Analyzing Predictive Results &#x26; Drug Effect</summary>

**Purpose:** Evaluate the performance of the trained classification models and, most importantly, interpret the role and importance of the `TreatmentGroup` variable in predicting `cardio` status.

**Actions (using PANDORA Predictive - Exploration):**

1. **Select Queue for Exploration:**
   * Navigate to the **Dashboard**. Select your completed "CardioGuard\_Cardio\_Prediction" task.
   * Navigate to **Predictive** -> **Exploration**.
   * **Configure Exploration Space:** Select `cardio` as the response outcome, relevant metrics (e.g., `PredictAUC`, `TrainAUC`, `BalancedAccuracy`, `F1-Score`, `Precision`, `Recall`), the dataset, and the models to evaluate.
2. **Evaluate Model Performance:**
   * Examine the metrics table for the **test set**.
   * **ROC Curve Analysis:** Compare Training ROC and Testing ROC curves. A higher Test AUC indicates better model discrimination for predicting `cardio` status. Check for overfitting.
   * **Training Summary:** Compare different models if multiple were run.
3.  **Assess Drug Effectiveness (Importance of `TreatmentGroup`):**

    * **Variable Importance Tab:**
      * Select your best performing model(s).
      * Examine the bar plot of feature importance. **Is `TreatmentGroup` a significant predictor of `cardio`?** A high rank and importance score would suggest CardioGuard influences the likelihood of having cardiovascular disease.
      * _(Conceptual Interpretation: If CardioGuard reduces risk, and 'TreatmentGroup' (CardioGuard=1) is negatively associated with 'cardio'=1, it should appear as an important feature.)_
      * Use the "Features across dataset" sub-tab to select `TreatmentGroup` and other top predictors. Visualize how their values differ between individuals with `cardio`=0 and `cardio`=1.

    _(Conceptual PANDORA Screenshot for Variable Importance)_

    ```
    [PANDORA Interface: Predictive -> Exploration -> Variable Importance, showing a bar chart where 'TreatmentGroup' has a notable importance score for predicting 'cardio'.]
    ```

    * **Model Interpretation Tab (Explainable AI - xAI):**
      * Select your best model.
      * **For `TreatmentGroup`:**
        * **PDP (Partial Dependence Plots) / ICE (Individual Conditional Expectation) Plots:** Plot the predicted probability of `cardio`=1 based on the `TreatmentGroup` variable. This will visually show the average effect of CardioGuard vs. Placebo on the likelihood of having cardiovascular disease.
        * _(Conceptual Interpretation: An ICE plot for 'TreatmentGroup' might show that when TreatmentGroup changes from 0 (Placebo) to 1 (CardioGuard), the predicted probability of 'cardio'=1 decreases, indicating a protective effect.)_
        * **LIME Plot:** Explain predictions for individual hypothetical patients to see how `TreatmentGroup` contributed to their predicted `cardio` status.

    _(Conceptual PANDORA Screenshot for PDP/ICE Plot)_

    ```
    [PANDORA Interface: Predictive -> Exploration -> Model Interpretation, showing a PDP/ICE plot for 'TreatmentGroup'. The y-axis shows predicted probability of 'cardio'=1. A lower probability for the CardioGuard group would suggest a positive drug effect.]
    ```

**Summary of Phase 5:** Model performance is assessed. The importance and effect of `TreatmentGroup` are investigated to understand if and how CardioGuard influences the `cardio` outcome.

</details>

***

<details>

<summary>Phase 6: Synthesizing Findings</summary>

**Purpose:** Combine all analyses to report on the potential effectiveness of CardioGuard in relation to cardiovascular disease status, the performance of predictive models, and insights into relevant risk factors.

**Actions & Report Structure (Conceptual):**

1. **Overall Drug Effect on `cardio` Outcome:**
   * Summarize the findings on the importance of `TreatmentGroup` from the classification models.
   * Report the effect observed from PDP/ICE plots (e.g., "CardioGuard was associated with an X% reduction in the predicted probability of having cardiovascular disease (`cardio`=1) compared to Placebo.").
2. **Best Predictive Model(s) for `cardio`:**
   * Report the best-performing model based on test set metrics (e.g., Test AUC, Balanced Accuracy).
   * Include key plots: ROC curves, Variable importance plots (highlighting `TreatmentGroup` and other top predictors like `ap_hi`, `cholesterol`, `smoke`, etc.).
3. **Key Predictors of Cardiovascular Disease (Risk Factors):**
   * List other baseline variables that were consistently important in predicting `cardio` (e.g., `Age`, `ap_hi`, `cholesterol`, `smoke`, `active`).
   * Discuss insights from "Features across dataset" plots or Model Interpretation plots regarding these risk factors.
4. **Confounding Assessment:**
   * Briefly mention the results of the confounding checks (Phase 3).
5. **Limitations:**
   * Acknowledge limitations (e.g., hypothetical nature of data, specific features available, cross-sectional `cardio` outcome rather than incident disease over time if that were the true trial design).
6. **Conclusion & Future Directions:**
   * Conclude on the evidence for CardioGuard's potential effect on cardiovascular disease status based on the PANDORA analysis.
   * Suggest if the predictive models are useful for risk stratification.



**Example Conclusion:**\
&#xNAN;_&#x50;ANDORA analysis of the hypothetical CardioGuard trial suggests that treatment with CardioGuard is an important factor associated with a reduced likelihood of having cardiovascular disease (best model Test AUC: 0.75). The `TreatmentGroup` variable was a key predictor, and PDP/ICE plots indicated an estimated 15% absolute risk reduction in predicted `cardio` status for the CardioGuard group. Other significant predictors included `ap_hi`, `cholesterol` (level 3 vs 1), and `smoke`. These findings warrant further investigation into CardioGuard as a cardiovascular protective agent._

</details>
