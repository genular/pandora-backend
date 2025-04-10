---
description: Enables users to analyze feature importance in machine learning models.
---

# Variable Importance

### Overview

The **Variable Importance** tab in PANDORA provides robust tools to investigate the contribution of predictor variables to the variance of the predictive models. Users can seamlessly select variables with the filter settings, visualize feature values across outcomes in the dataset, and identify top features through an interactive bar plot.

<figure><img src="../../../.gitbook/assets/Variable Importance.png" alt=""><figcaption></figcaption></figure>

### Key Functionalities

1. **Feature Filtering**
   * **Class:** Only show features associated with predictions for the selected binary outcomes.
   * **Order:** Choose to sort the feature table by various options, including but not limited to rank, name, and feature variance score.
     * Toggle the adjacent switch next to sort in ascending or descending order.
2. **Features Across Dataset**
   * **Define Features:** Select a maximum of 25 features from the table to use in the analysis.
   * **Dot Plots:** For the selected features, shows the distribution of feature values for each outcome in both the training and testing datasets.
   * **Theme:** Users can select from various themes, affecting the visual style of the plots.
   * **Color:** Choose a color palette to enhance visual clarity, with options for colorblind accessibility.
   * **Font:** Customize font size to ensure readability.
   * **Dot:** Alter the data point size for enhanced clarity
   * **Ratio:** Adjust the plot’s aspect ratio for optimal display and to fit various screen resolutions.
3. &#x20;**Variable Importance**
   * Bar plot showing feature importance in descending order. For Clarity, users can hover over bars to view the associated feature name and exact variable importance score.

{% embed url="https://www.youtube.com/watch?v=E2KSBN1GST0" %}
