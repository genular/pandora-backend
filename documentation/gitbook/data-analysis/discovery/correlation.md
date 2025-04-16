---
description: Enables users to analyze correlations between variables within a dataset.
---

# Correlation

### Overview&#x20;

The **Correlation** tab in PANDORA produces correlograms that display the correlation in the dataset, allowing users to visualize important relationships between variables along with the statistical significance and confidence interval of the relationship.&#x20;

<figure><img src="../../.gitbook/assets/image (18).png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="1. Correlation Setup" %}
For generic setup steps and preprocessing options, please see the [Side Panel Options](side-panel-options.md) page. Information about the settings unique to Correlation setup is provided below:

* **Correlation Method**: In the Column Selection tab, the user can choose between the _Pearson_, _Kendall_, and _Spearman_ methods to calculate correlation.&#x20;
* **Correlation Settings**:&#x20;
  * **NA Action**: Provides the user with options for processing of NA values in the dataset. The default is 'everything', where the NA values are left as is, however the user can choose the method that best suits their dataset. For reference, the [cor( ) documentation](https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/cor) talks about the options in detail.
  * **Plot method**: Consists of several shapes and shading options for the correlogram and visualization of the correlation matrix
  * **Plot Type**: The user can view their plot as the whole plot, or as the upper or lower half of the plot (split along the diagonal of value 1).&#x20;
  *   **Reorder Correlation**: Provides the options to choose the order of the variables for the plot, consisting of mathematical and alphabetical options.&#x20;

      * _**Hierarchical clustering**_: If the user chooses this option, more fields specific to it will appear. The user can choose the clustering method and the number of rectangles (clusters) for their plot.



      <figure><img src="../../.gitbook/assets/image (19).png" alt=""><figcaption></figcaption></figure>


  * **Text size**: Adjust the test size of the variables on the axes&#x20;
{% endtab %}

{% tab title="2. Correlogram" %}
A correlogram is a visual representation of the correlation matrix produced by the processing performed through the correlation setup. Below is a correlogram of a few variables:&#x20;

<figure><img src="../../.gitbook/assets/image (21).png" alt=""><figcaption></figcaption></figure>

* **Size**: The size of the circle represents the magnitude of the correlation value between the two variables&#x20;
* **Color**: Colors in red spectrum represent positive correlation and colors in the blue spectrum represent negative correlation. The shade of the circle corresponds to the correlation value, which can be estimated using the color legend.&#x20;

The correlogram in PANDORA can be used to visualize correlations in larger datasets as well, as shown below:&#x20;

<figure><img src="../../.gitbook/assets/image (20).png" alt=""><figcaption><p> </p></figcaption></figure>
{% endtab %}

{% tab title="3. Significance" %}
Along with producing a visualization for the correlation matrix, PANDORA allows users to visualize the significance and confidence interval of the correlation:&#x20;

*   **Significance Test**: Perform a test to visualize whether the correlation between each variable is statistically significant.

    * **Significance Level**: Adjust the threshold for determining statistical significance
    * **Insignificant Action**: These are options that determine how the insignificant correlations are represented in the plot. For example, the below images shows the significance test with the **pch** setting, where a cross (X) is used to mark the insignificant correlations



    <figure><img src="../../.gitbook/assets/image (22).png" alt=""><figcaption></figcaption></figure>



    * **P-value comparisons (BH)**: Use the Benjamini-Hochberg (BH) method to adjust the p-values when the correlation matrix has a large number of variables
*   Confidence Interval: Provides options for calculating and visualizing the confidence interval of the correlations

    * Confidence Level: Adjust the width of the confidence interval based on desired certainty&#x20;
    * Plotting Method: Choose the shape to visually represent the confidence interval of the correlations in the plot
    * Example: A correlogram with visualization of insignificance using **pch**, **0.95 confidence level**, and the **square** plotting method



    <figure><img src="../../.gitbook/assets/image (23).png" alt=""><figcaption></figcaption></figure>
{% endtab %}
{% endtabs %}

**Download Options**: Users can download the raw data and plot images for offline analysis. Images are available in SVG format for scalability.

