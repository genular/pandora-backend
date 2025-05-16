---
icon: bullseye-arrow
---

# Phase 5: model evaluation

Assess and compare model performance using statistical metrics like AUC, and explainable AI techniques to understand model predictions. This allows for identification of the most reliable models and extraction of biologically meaningful insights from models.

<details>

<summary>1. Select queue for exploration</summary>

1. Navigate to the **Dashboard** and select your predictive analysis from the queue
   1. The queue number selected is indicated in the pink box at the top right of the PANDORA interface.

<figure><img src="../.gitbook/assets/FF_ Phase 5_Dashboard_Select Queue.png" alt=""><figcaption></figcaption></figure>

2. Navigate to **Predictive** -> **Exploration**

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Navigate.png" alt=""><figcaption></figcaption></figure>

3. Configure **Exploration** space
   1. Select all Response outcomes
   2. Select metrics of interest
   3. Select dataset
   4. Select models to evaluate

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Configure Space.png" alt=""><figcaption></figcaption></figure>

</details>

<details>

<summary>2. Evaluate performance of the models</summary>

1. Compare metrics
   1. Compare models based on the metrics selected in 3.b that are shown in the table from part 3.d. Special attention can be given to `Predictive AUC` and `Training AUC` scores for each model **(Area Under the ROC Curve)**. More info about metrics [here](https://app.gitbook.com/s/9LdC62ZpkxqvCBTPwVZU/data-analysis/predictive/exploration#model-metrics).

2) Select the **ROC Curve Analysis** tab in Exploration
3) Compare ROC Curves for each model to assess classification performance and identify the best models.

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_ROC Curves_v2.png" alt=""><figcaption></figcaption></figure>

4. Ensure multiple models are selected, then select the **Training Summary** tab in Exploration
   1. Compare the metrics shown on the box plots for multiple models.
   2. The **Performance measurements** section can help determine if there are significant differences between model metric values.
   3. The **Model fitting results summary** provides the five-number summary of each model that is visualized in the box plots.

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Training Summary.png" alt=""><figcaption></figcaption></figure>

</details>

<details>

<summary>3. Identify key predictors (Variable Importance score)</summary>

1. Select the top model and select the **Variable Importance** tab in **Exploration**.

2) While on the Variable Importance tab, locate the **Variable Importance** sub-tab
   1. A bar plot will appear showing the top features and their contributions to model variance

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Variable Importance.png" alt=""><figcaption></figcaption></figure>

3. List the top predictors for your model
   1. In this example, the top predictors, as shown in the bar graph below, are:
      1. `h3_hai_v0_gmt`
      2. `hmnp_v0_cd4_ifng`
      3. `z_score_continuous`
      4. `h1_v0_cd4_ifng`

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Variable Importance Plot_white background.png" alt=""><figcaption></figcaption></figure>

4. Locate the **Features across dataset** sub-tab

5) Select the top features you had listed in part 8, and click the **redraw plot** button

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Features Across Dataset Config.png" alt=""><figcaption></figcaption></figure>

6. Examine the **dot plots** to visualize how the top predictive features vary between responder outcomes
   1. The dot plot below is based on features from step 3.a

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Features Across Dataset Plot.png" alt=""><figcaption></figcaption></figure>



</details>

<details>

<summary>4. Interpret the model - Explainable AI (xAI)</summary>

1. Navigate to the **Model Interpretation** tab

2) Utilize the various analysis tools to understand how features in the model influence predictions.
   1. Example (Heatmap): Helps the user understand how joint variations of two variables may influence predictions
      1. In **Vars**, select 2 features of interest like `h3_hai_v0_gmt` & `hmnp_v0_cd4_ifng`
      2. Select `Heatmap` from the **Analysis** options
      3. Click the **Plot Image** button

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Model Interpretation_Heatmap.png" alt=""><figcaption></figcaption></figure>



</details>

You've now assessed model performance using AUC scores, ROC curves, and summary statistics, followed by deeper exploration of variable importance and feature-level patterns. By selecting top predictors and visualizing their variation across outcome groups, you've gained insight into how specific biological variables drove your model's decisions.
