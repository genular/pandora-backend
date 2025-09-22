---
description: >-
  Understanding why certain machine learning algorithms work well for biomedical
  data
icon: function
---

# Algorithms for biomedical data

As a reminder, for Phase 5 the following families of machine learning algorithms were chosen for the predictive modelling task:&#x20;

* L1 Regularization&#x20;
* L2 Regularization&#x20;
* Partial Least Squares&#x20;
* Random Forest&#x20;
* Support Vector Machines&#x20;

### Generally, what kind of algorithms are suited for biomedical data?&#x20;

There are certain algorithms that perform better for biomedical data because they are able to work with the inherent complex qualities of such datasets. You want to use algorithms that are able to work with the following qualities:&#x20;

* **High dimensionality**: Biomedical datasets can have thousands of genes or proteins for dozens of samples
* **Noisy data**: Often present due to biological variation and measurement error
* **Small sample size**: As clinical trails are very costly and some may have ethical limits, the sample size tends to be in the tens or hundreds.&#x20;
* **Complex relationships**: Biological systems are complex, and hence relationships between variables measured to try to capture the kinetics of the system also tend to be complex.&#x20;
* **Need for interpretability**: Feature importance = clinical insight

### How are those specific algorithms able to navigate working with biomedical data?&#x20;

The aforementioned algorithms are specialized to work with one or more of the features that make biomedical data hard to work with. Here is a brief explanation of each algorithm family and what kind of features/data they are good for:&#x20;

#### **1. L1 Regularization (LASSO)**

LASSO (Least Absolute Shrinkage and Selection Operator), often also known as L1 regularization, is a technique where a **penalty is added to a model's loss function**. This prevents the model from **overfitting**, which means the models learns too specifically to the training data and learn noise instead of real patterns, making the model perform poorly when predicting with new data.&#x20;

**Key Use:** Feature selection in high-dimensional data

* LASSO encourages **sparsity** (use of a small subset of features only) in the model by **shrinking some of the model's coefficients to zero**, essentially eliminating some of the parameters and **selecting a small number of relevant features** (e.g., biomarkers, genes).
* Biomedical datasets often have **many more features** than samples , and LASSO handles this imbalance problem well.
* This family of algorithms is deal when you want to **interpret which variables (e.g., immune markers)** drive an outcome.

***

#### **2. L2 Regularization (Ridge penalty)**

Similar to LASSO, Ridge penalty, or L2 regularization, is a technique where a penalty is added to the model's loss function, but this penalty is less severe than LASSO. The ridge penalty discourages large coefficient values by shrinking the value of all the model's coefficients gradually towards zero, instead of reducing them down to exactly zero like LASSO.

**Key Use:** Handling multicollinearity (highly correlated features), stabilizing regression

* As the ridge penalty doesn't zero out coefficients but shrinks all of them to reduce overfitting, it produces more **stable and generalizable models**.
* Works well when **many features are moderately predictive** (e.g., overlapping immune signatures).
* Good for situations where **feature selection is less important**, and **prediction accuracy** is the priority.

***

#### **3. Sparse Partial Least Squares (sPLS)**

This family of algorithms is a variation of partial least squares (PLS), a dimensionality reduction technique that finds new variables called latent variables to capture the maximum variance in the features that are predictors AND predict the response features. sPLS follows the same concept as PLS but also **enforces sparsity** — meaning that only a small subset of features are used in the model for prediction. &#x20;

**Key Use:** Dimensionality reduction combined with sparsity for prediction&#x20;

* sPLS combines **PLS** (which reduces dimensionality) with **LASSO-type sparsity**.
* These algorithms are especially suited for **multi-omics data integration** (e.g., transcriptomics + proteomics) where variables are collinear and high-dimensional.
* The result of this algorithm is a model that is both **predictive** and **interpretable**, which is ideal for biomedical data where you want to find key genes, proteins, or biomarkers

***

#### **4. Random Forest (RF)**

Random forest algorithms consist of an ensemble of multiple decision trees, a machine learning model that splits data into smaller groups based on specific attributes defined by the predictor features. An ensemble of many decision trees combines their results which makes random forests have improved prediction accuracy and robustness.&#x20;

**Key Use:** Non-linear modeling and obtaining feature importance

* Robust to noise and outliers, and works well with **nonlinear relationships** and **interactions**.
* Performs automatic **feature selection**, ranking variables by importance.
* Handles **imbalanced data** and **missing values** better than many models.
* In relation to biomedical data, it can be used for purposes such as **biomarker discovery**, **disease classification**, or **risk prediction**.

***

#### **5. Support Vector Machines (SVM)**



**Key Use:** High-dimensional classification with kernel trick

* Performs well in **high-dimensional spaces**, especially when the number of features >> number of samples.
* **Kernel trick** allows modeling of **nonlinear relationships** (e.g., in gene expression or immune signatures).
* Tends to have **high generalization** and good performance even with **small sample sizes**, typical in biomedical research.

