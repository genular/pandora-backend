# Phase 5: Predictive Results

### Purpose

Assess and compare model performance using statistical metrics like AUC, and explainable AI techniques to understand model predictions. This allows for identification of the most reliable models and extraction of biologically meaningful insights from models.

***

### Action

{% stepper %}
{% step %}
### Navigate to Results

1. Navigate to the **Dashboard** and select your predictive analysis from the queue
   1. The queue number selected is indicated in the pink box at the top right of the PANDORA interface

<figure><img src="../.gitbook/assets/FF_ Phase 5_Dashboard_Select Queue.png" alt=""><figcaption></figcaption></figure>

2. Navigate to **Predictive** -> **Exploration**

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Navigate.png" alt=""><figcaption></figcaption></figure>

3. Configure **Exploration** space
   1. Select all Response outcomes
   2. Select metrics of interest
   3. Select dataset
   4. Select models to evaluate

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Configure Space.png" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}
### Evaluate Model Performance

4. Compare metrics
   1. Compare models based on the metrics selected in 3.b that are shown in the table from part 3.d. Special attention can be given to `Predictive AUC` and `Training AUC` scores for each model
      1. `Predictive AUC` and `Training AUC` should be similar values to assure the model is neither underfit nor overfit
      2. A guide to interpreting AUC values is provided below:

| AUC Value                | Interpretation |
| ------------------------ | -------------- |
| $$AUC \geq 0.9$$         | Excellent      |
| $$0.8 \leq AUC \gt 0.9$$ | Good           |
| $$0.7 \leq AUC \gt 0.8$$ | Fair           |
| $$0.6 \leq AUC \gt 0.7$$ | Poor           |
| $$AUC \leq 0.6$$         | Fail           |

4. Select the **ROC Curve Analysis** tab in Exploration
   1. Compare ROC Curves for each model to assess classification performance and identify the best models

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_ROC Curves_v2.png" alt=""><figcaption></figcaption></figure>

5. Ensure multiple models are selected, then select the **Training Summary** tab in Exploration
   1. Compare the metrics shown on the box plots for multiple models
   2. The **Performance measurements** section can help determine if there are significant differences between model metric values.
   3. The **Model fitting results summary** provides the five-number summary of each model that is visualized in the box plots

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Training Summary.png" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}
### Identify Key Predictors

6. Select the top model and select the **Variable Importance** tab in Exploration
7. While on the Variable Importance tab, locate the **Variable Importance** sub-tab
   1. A bar plot will appear showing the top features and their contributions to model variance

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Variable Importance.png" alt=""><figcaption></figcaption></figure>

6. List the top predictors for your model
   1. In this example, the top predictors, as shown in the bar graph below, are:
      1. `h3_hai_v0_gmt`
      2. `hmnp_v0_cd4_ifng`
      3. `z_score_continuous`
      4. `h1_v0_cd4_ifng`

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Variable Importance Plot_white background.png" alt=""><figcaption></figcaption></figure>

9. Locate the **Features across dataset** sub-tab
10. Select the top features you had listed in part 8, and click the **redraw plot** button

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Features Across Dataset Config.png" alt=""><figcaption></figcaption></figure>

11. Examine the **dot plots** to visualize how the top predictive features vary between responder outcomes
    1. The dot plot below is based on features in the example from part 8

<figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Features Across Dataset Plot.png" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}
### Interpret Model Behavior

12. Navigate to the **Model Interpretation** tab
13. Utilize the various analysis tools to understand how features in the model influence predictions.

    1. Example (Heatmap): Helps the user understand how joint variations of two variables may influence predictions
       1. In **Vars**, select 2 features of interest like `h3_hai_v0_gmt` & `hmnp_v0_cd4_ifng`
       2. Select `Heatmap` from the **Analysis** options
       3. Click the **Plot Image** button



    <figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Model Interpretation_Heatmap.png" alt=""><figcaption></figcaption></figure>
{% endstep %}

{% step %}
### Synthesize Findings

After evaluating the models and identifying the best model, it is time to report your findings.

1.  Save results for your best model, which may include the following. (You can save most graphs and plots by right-clicking and saving the image as a PNG, or hovering your cursor over the image until a green box appears to download the graph as an SVG)

    1. Table of performance metrics for your model
    2. Box plots comparing performance metrics for top models



    <figure><img src="../.gitbook/assets/FF_Phase 5_Training Summary Box Plots.png" alt="" width="375"><figcaption></figcaption></figure>

    1. Training and Testing ROC Curves



    <figure><img src="../.gitbook/assets/FF_Phase 5_Combined ROC Curves RF.png" alt="" width="563"><figcaption></figcaption></figure>

    1. Model Interpretation Plots



    <figure><img src="../.gitbook/assets/FF_Phase 5_Model Interp Heatmap RF.png" alt="" width="375"><figcaption></figcaption></figure>

    1. Variable Importance bar plot (top predictive features)



    <figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Variable Importance Plot_white background.png" alt="" width="375"><figcaption></figcaption></figure>

    1. Features across dataset dot plots



    <figure><img src="../.gitbook/assets/FF_ Phase 5_Exploration_Features Across Dataset Plot.png" alt="" width="375"><figcaption></figcaption></figure>
2. Identify biological themes associated with the top baseline predictors
   1. Research and discuss biological relevance of top predictors
   2. Consider whether top predictors are exhibited as high or low (upregulated or downregulated) for each responder group
3. Compile all your findings into a report on your model.
{% endstep %}
{% endstepper %}

***

### Summary

You've now assessed model performance using AUC scores, ROC curves, and summary statistics, followed by deeper exploration of variable importance and feature-level patterns. By selecting top predictors and visualizing their variation across outcome groups, you've gained insight into how specific biological variables drove your model's decisions.
