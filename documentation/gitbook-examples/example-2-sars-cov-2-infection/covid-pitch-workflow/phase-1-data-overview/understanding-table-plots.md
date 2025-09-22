---
description: >-
  Look into the importance of table plots and how to analyze the plots produced
  by PANDORA, particularly with a mix of categorical and numerical variables
icon: head-side-gear
---

# Understanding table plots

### Why are table plots important?&#x20;

Table plots also provide vital information to understand the structure of the dataset, which is especially important when working with large datasets in biomedical research. However, table plots preserve individual-level or close to individual-level (depending on number of objects per bin) data,  unlike distribution plots which provide summary statistics. Hence, table plots allow the user to:&#x20;

* Observe heterogeneity in variables that can be hidden in averages&#x20;
* Visualize and examine aggregated distribution patterns across multiple variables&#x20;
* Identify variables with missing data and outliers&#x20;

### What does PANDORA's tables plots show?&#x20;

Generally the table plot will consist of the following features:&#x20;

* **Sorting variable:** The first plot will be the sorting variable that will determine the position of the samples.
* **Y-axis**: The position of a sample in the sorted list (0-100% quantiles). Hence earlier datapoints are present on top of the graph while later datapoints are present in the bottom.&#x20;
* **Table bins information:** Present in the bottom left of the plot. Provides information about:&#x20;
  * Number of row bins&#x20;
  * Number of objects&#x20;
  * Rounded number of objects per bin&#x20;
* **Plot title**: Showing the variable that is plotted following the order of the sorting variable. Some variables will be _log-transformed_ to normalize the distribution for better visualization.&#x20;

<figure><img src="../../../.gitbook/assets/CP_table plot example.png" alt=""><figcaption></figcaption></figure>

### What features to observe to obtain information from a table plot?

As an example, let us look at a table plot with **days after positive SARS-Cov-2 test a sample was taken** (`Timepoint`) as the **sorting variable** and variables of interest as&#x20;

* `Disease severity` : the severity of disease symptoms
* `S-IgG` : immunoglobin G antibodies specific to the SARS-CoV-2 spike protein
* `Total pos T cell elispot` : total activated T cell count
* `Responder`: outcome of immune response durability at 6 months

Here are the features to look for each type of variable:&#x20;

* Numerical variables
  * **Log transformation:** The title of the graph can appear as the variable name, or log (variable name), like seen with `log(S.IgG)` in the plot below (third graph).&#x20;
    * Log transformation makes data, especially skewed data, more symmetrical that allows for better visualization.&#x20;
  * **Length of bars:** Spread/magnitude of the values for the objects within the bin.&#x20;
    * Shorter bars correspond to lower values while longer bars correspond to larger values.&#x20;
  * **Mean of bin:** Shown as the black vertical line in the middle of the bar
    * These help visualize trends such increasing/decreasing values as you go down the plot, consistency of values, and so on.&#x20;
  * **Lack of bins:** A lack of bins can indicate several possibilities:&#x20;
    * The objects consist of discrete values (such as the first graph Timepoint) and hence is likely a categorical variable instead of numerical.&#x20;
    * There are **missing values present in the particular variable**, as seen in the fourth graph, `log(Total.pos.T.cells.elispot)` where the gaps between 20-33%, 60-67% and 86-100% percentiles (y-axis) indicate there is no available values from the T cell ELISpot at certain timepoints.&#x20;
* Categorical variables
  * **Bar colors**: Instead of having values indicated by the x-axis, the bars are color-coded by category.&#x20;
    * These bar colors give a general indication of the distribution of data within each category. It can also indicate missing values when present
    * For example, in the second graph of `Disease.severity`, it is clear a higher number of blue bars are present compared to orange and yellow
  * **Legend:** Provides name of the category corresponding to each color and includes missing values&#x20;
    * For example in the fifth graph of the `Responder` variable, we can see that there are about the same numbers of high and low responders and a few missing values

<figure><img src="../../../.gitbook/assets/CP_table plot explanation.png" alt=""><figcaption></figcaption></figure>
