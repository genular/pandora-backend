---
description: >-
  Allows users to configure machine learning models by selecting predictors,
  responses, model types, and preprocessing options to suit their specific
  analytical needs.
icon: message-bot
---

# Machine Learning

### Overview

The **Predictive - Start** tab in SIMON simplifies the process of setting up and running predictive models, making it accessible to users with various levels of expertise. Its intuitive interface and extensive model selection provide flexibility for both exploratory and targeted predictive analysis.

<figure><img src="../../../.gitbook/assets/predictive-simon.png" alt=""><figcaption></figcaption></figure>

### Key Functionalities

#### 1. Analysis Properties

* **Classification / Regression / Time Series**: Choose the type of analysis you want to perform. Only available options are displayed based on your dataset and selected variables.
* **Predictor Variables**: Select the independent variables (predictors) for the model. Enable the switch to select all columns, or specify individual columns by typing their names.
* **Response**: Define the dependent variable (response) that the model will predict or classify.
* **Exclude Predictors**: Specify any predictor variables that should be excluded from the analysis.
* **Training/Testing Dataset Partition (%)**: Adjust the partition between training and testing datasets using a slider (default: 75%). This enables you to set the ratio for model validation.
* **Additional Exploration Classes**: Add exploratory variables that are not used in the model training but are available for analysis.
* **Preprocessing**: Apply preprocessing methods such as centering or scaling to standardize data before training the model. You can select multiple options from the dropdown menu.

#### 2. Model Selection and Customization

* **Available Packages**: Choose from a variety of machine learning models available in SIMON. Each model displays its name, type (classification, regression, etc.), and key characteristics.
  * **AdaBoost.M1**: An example of a model available under **Boosted Classification Trees**, with tags like Tree-Based Model, Ensemble Model, Boosting, and more.
* **Model Filtering**: Filter models by type or features to narrow down the list of packages.
* **Selected Packages**: Displays the list of selected models for analysis. You can choose multiple models for comparison and evaluation.

#### 3. Advanced Options

* **Multi-Set Intersection**: Enable this option to intersect multiple sets in a Venn-like manner, useful for combining features from different models.
* **Feature Selection**: Enable feature selection to automatically reduce dimensionality and retain only the most relevant features for the model.
* **Timeout**: Set a timeout (in minutes) to limit the execution time for model training, preventing lengthy computations.

#### 4. Additional Controls

* **Reset Features & Selection**: Clears all selected features, models, and settings, allowing you to start with a fresh configuration.

### Example Workflow

1.  **Select Analysis Properties**: Choose your predictor and response variables, configure preprocessing, and set the training/testing split.

    * **Select Predictor variables:** In this case, all predictor variables are selected, and the "exclude predictors" is used to remove non-contributing features from the analysis, such as arbitrary sample ids.&#x20;

    <div data-full-width="true"><figure><img src="../../../.gitbook/assets/ML_Example_PredictorSelection.png" alt=""><figcaption></figcaption></figure></div>

    * **Select Response Variables**: Select the desired response variable. In a classification model, this is the outcome the model is trying to predict based on the predictor features.



    <figure><img src="../../../.gitbook/assets/ML_Example_ResponseSelection.png" alt=""><figcaption></figcaption></figure>

    * **Set Training/Testing Dataset partition**: Use the slider to adjust the partition between training and testing. In this case, we will keep the standard 75% partition, though it may make sense to vary the partition based on the machine learning package used.

    <div align="center" data-full-width="true"><figure><img src="../../../.gitbook/assets/ML_Example_Partition.png" alt=""><figcaption></figcaption></figure></div>

    * **Configure Preprocessing:** Select preprocessing methods to appropriately standardize data based on your dataset and the machine learning packages you plan to use.

    <figure><img src="../../../.gitbook/assets/ML_Example_Preprocessing.png" alt=""><figcaption></figcaption></figure>
2. **Choose Models**: Select one or more models from the **Available Packages** list and add them to **Selected Packages**.
3. **Run Analysis**: Configure advanced options like feature selection and multi-set intersection as needed, then initiate the analysis.

