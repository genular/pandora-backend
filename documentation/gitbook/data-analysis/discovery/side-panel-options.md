# Side Panel Options

The **Side Panel Options** presents the common tools and settings the user can find in the side panels for the tabs in Discovery

{% tabs %}
{% tab title="Column Selection" %}

{% endtab %}

{% tab title="Preprocessing" %}

{% endtab %}

{% tab title="Theme " %}

{% endtab %}
{% endtabs %}

1. **Columns**: Input specific columns for analysis. The dropdown is filterable and searchable to quickly find columns in large datasets.

<figure><img src="../../.gitbook/assets/image (10).png" alt=""><figcaption></figcaption></figure>

2. **First (n) columns**: Select the number of initial columns to display and analyze. This number can be adjusted using the input field

<figure><img src="../../.gitbook/assets/image (11).png" alt=""><figcaption></figcaption></figure>

3. **Exclude columns**: Some tabs have the option to remove columns the user does not want to include in their analysis. The dropdown for this option is also filterable and searchable

<figure><img src="../../.gitbook/assets/image (12).png" alt=""><figcaption></figcaption></figure>

### Preprocessing&#x20;

PANDORA has several preprocessing options for preparing the user's dataset for analysis. The user can choose one or a combination of the following options:&#x20;

* **Center**: Subtracting the mean of the data from the values
* **Scale**: Dividing your values by the standard deviation of the data
* **knnImpute**: Estimate missing values using the nearest neighbors with similar patterns to the row with the missing value
* **bagImpute**: Estimate missing values using a bagged ensemble of regression trees
* **medianImpute**: Estimate missing values using the median of the existing values of the variable&#x20;
* **corr**: Stands for **correlation filtering**, which involves computing correlation between variables and removing redundant ones, which simplifies data and reduces computational cost
* **zv**: Stands for **remove** **zero variance**, which involves removing any variables with no variance to simplify data for predictive modelling as zero-variance features do not provide any useful information for predictive models&#x20;
* **nzv**: Stands for **remove** **near-zero variance**, which involves removing any variables with variance close to zero to simplify data for predictive modelling

### Display Settings

PANDORA allows for several themes and display settings for plots to accommodate a variety of audiences and potential applications of the figures produced.&#x20;

* **Theme:** This consists of options that alter gridlines, background and plot details to suit various applications such as presentations and manuscript publications
* **Color**: Various color options that the user can pick to suit their preferences. This also includes options for those who are colorblind, and can be found by hovering over the information icon next to the color option and looking for ones that say 'colorblind: true'
* **Font size**: Adjust the font size of the plot by clicking on the '+' or '-' options or input a number in the field.&#x20;
* **Plot ratio**: Adjust the size of the plot&#x20;
