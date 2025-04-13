---
description: >-
  Displays key data output from the principal component analysis (PCA) for the
  user to view.
---

# PCA Output

### Overview

The **PCA Output** tab in PANDORA allows users to view a snippet of the numerical output data for the principal component eigenvalues,  individuals, and variables.

<figure><img src="../../../.gitbook/assets/PCA_PCA Output.png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="Eigenvalues" %}
Under "Eigenvalues" in the terminal output, the variance contributions for each eigenvalue and its corresponding principal component are shown. The rows of the table are explained below:

* **Variance:** Provides a variance value for the eigenvalue associated with the dimension (principal component).
* **% of var:** The proportion of the total variance among all principal components that the eigenvalue contributes is shown
* **Cumulative % of var:** Each successive principal component or dimension down the table adds to the total variance; the cumulating variance is shown in this column.

<figure><img src="../../../.gitbook/assets/PCA Output_Eigenvalues.png" alt=""><figcaption></figcaption></figure>
{% endtab %}

{% tab title="Individuals" %}
Under "Individuals" in the terminal output, results from PCA for the first ten individuals are displayed. Data on dist,  dim x, ctr, and cos2 are provided for these individuals.

* **Dist:** A measure of the distance from the centroid of the individuals in the variable space to the individual point.
* **Dim.X:** For dimension X, provides the coordinate location of the individual on the principal component.
* **Ctr:** Provides a measure of the individual's contribution to the principal component.
* **Cos2:** The cos2 value indicates how well an individual is represented on the principal component. A value closer to one indicates better representation.

<figure><img src="../../../.gitbook/assets/PCA Output_Individuals.png" alt=""><figcaption></figcaption></figure>
{% endtab %}

{% tab title="Variables" %}
Under "Variables" in the terminal output, results from PCA for the first ten variables are displayed. Data on dim.X, ctr, and cos2 are provided for these individuals.

* **Dim.X:** For dimension X, provides the normalized coordinate location of the variable on the principal component.
* **Ctr:** Provides a measure of the variable's contribution to the principal component.
* **Cos2:** The cos2 value indicates how well a variable is represented on the principal component. A value closer to one indicates better representation.

<figure><img src="../../../.gitbook/assets/PCA Output_Variables.png" alt=""><figcaption></figcaption></figure>
{% endtab %}
{% endtabs %}

