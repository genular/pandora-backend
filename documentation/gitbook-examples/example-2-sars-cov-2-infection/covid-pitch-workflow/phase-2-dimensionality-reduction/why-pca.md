---
description: >-
  An explanation of PCA and why it is useful for analyzing this data for our
  particular purposes
icon: info
---

# Why PCA?

### What Is PCA?&#x20;

PCA (Principal Component Analysis) is a method for **linearly reducing the dimension of a dataset** and transforming the features of the dataset into new features called **principal components.** These principal components are **orthogonal** (unrelated) to each other and **capture the most explained variance** in different directions along the data.&#x20;

### What are the general advantages of PCA?

* **Dimensionality reduction**: Reducing dimensions of the data makes it easier to visualize and interpret by reducing the data and keeping the most important information. Other common dimensionality reduction techniques are UMAP and t-SNE. which are non-linear methods while PCA is linear&#x20;
* **Variable contribution analysis:**  PCA quantifies how much each original variable contributes to each principal component, hence providing information about which variables are the most significant contributors to the differences within the dataset&#x20;
* **Sample projection**: PCA creates a fixed coordinate system that allows projection of new samples such as new individuals or timepoints into existing PCs

### Why do we use PCA to gain insight into immunological differences?&#x20;

There are several features of PCA that allows us to specifically gain insight into immune differences and trajectories that is significantly harder to do with other dimensional reduction techniques:

* **Linearity**: PCA is linear, and its components are linear combinations of original variables. This makes it easier to trace back which immunological features are contributing to the observed separations
* **Feature ranking**: As PCA quantifies how much each variable contributes to each principal component, you can rank features based on how much they explain variance in the data and use these rankings for feature selection and hypothesis generation.
  * For our purposes of understanding the overall immune landscape and understand immune trajectories, feature rankings provide information about which immune assays, specific antibody functions and types drive the separation between observed groups in the PCA space.&#x20;
* **Structure preservation**: PCA preserves the **global relationships** between samples and thus if groups cluster separately in PCA space, they likely differ in overall immune profiles.

These features make it easier to identify notable immune correlates of protection or severity and visualize disease progression or vaccine responses over time. They also provide the option to select features of importance based on their contribution to the principal components and compare immune profiles across groups.&#x20;

***

####
