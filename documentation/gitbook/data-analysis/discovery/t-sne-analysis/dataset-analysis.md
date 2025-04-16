# Dataset analysis



<figure><img src="../../../.gitbook/assets/tSNE_Dataset Analysis_Highres-min_annotated.png" alt=""><figcaption></figcaption></figure>

{% tabs %}
{% tab title="1. Analysis Graph" %}
Based on the selected dataset analysis type, either a heatmap or a hierarchical clustering analysis plot is generated comparing feature values among each cluster generated in the clustered t-SNE analysis

### Heatmap

When "dataset analysis type" is set to heatmap, a heatmap is generated to compare each cluster's feature values. The clusters are shown in the columns, and the features are shown in the rows. The coloring on the heatmap is according to normalized feature values.

This plot can be downloaded as SVG files or right-clicked and saved as a PNG in PANDORA.

<figure><img src="../../../.gitbook/assets/tSNE_Data analysis_Heatmap.png" alt="" width="375"><figcaption></figcaption></figure>

### Hierarchical Clustering Analysis

When "dataset analysis type" is set to hierarchical clustering analysis, the same heatmap described above is generated; however, now hierarchical clusters are portrayed among the clusters, and among the features.

This plot can be downloaded as SVG files or right-clicked and saved as a PNG in PANDORA.

<figure><img src="../../../.gitbook/assets/tSNE_Data analysis_Hierarchical clustering.png" alt="" width="375"><figcaption></figcaption></figure>
{% endtab %}

{% tab title="2. Actions" %}
The user can take several actions with the new clustered dataset to allow for further exploration of feature contributions to clusters.&#x20;

1. **Start ML Analysis**

This action allows the user to create predictive models that classify individuals according to the identified clusters. The user can then utilize PANDORA's [exploration](../../predictive/exploration/) features to uncover insights and assess the performance of these models.

2. **Download**

Users can download a dataset with an added variable for the cluster classification of individuals.&#x20;

3. S**ave to Workspace**

Saves the new clustered dataset into the PANDORA workspace for the use to use later.
{% endtab %}
{% endtabs %}





