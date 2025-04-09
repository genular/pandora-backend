---
description: >-
  Provides users an easy way and visual way to assess diagnostic capabilities of
  their machine learning models
---

# ROC Curve Analysis

### Overview

The **ROC Curve Analysis** tab in PANDORA provides a clear interface for visualizing the classification performance of predictive models. Its intuitive design allows users to easily compare individual or multiple models at once, and provides comprehensive customization options for ROC Curve visualization.



<figure><img src="../../../.gitbook/assets/Exploration_ROC Curves.png" alt=""><figcaption></figcaption></figure>

### Key Functionalities

1. **ROC Curves:**
   * **Training ROC Curve:** Shows the model's ability to correctly classify outcomes within the training dataset. A curve close to the top-left indicates a good balance of sensitivity and specificity.
   * **Testing ROC Curve:** Demonstrates the model's performance on correctly classifying outcomes with the unseen testing dataset. A curve that remains close to the top-left indicates good learning and ability to generalize to new data.
   * **Overview:** Snippet of text at the bottom of the page explaining briefly how to interpret and understand the ROC curves.
2. **Display Options:**
   * **Side Panel:** Toggle visuals on the displayed graph, such as color and font, see the [Side Panel Options](../../discovery/side-panel-options.md) section for more information.
   * **One vs All:** Displays ROC Curves of each outcome for only the selected model.
     * **Model Display:** Choose which model to display the ROC Curve for.
   * **Comparison:** Displays ROC Curves of all selected models on one graph.

