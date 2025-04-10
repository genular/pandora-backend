# Dashboard

### Overview

The Dashboard is a space where the user's attempts of training predictive models through SIMON are stored. It also consists of basic functions to observe the progression of the training and testing of your predictive models along with a summary of training results.&#x20;

<figure><img src="../.gitbook/assets/PANDORA Dashboard.png" alt=""><figcaption></figcaption></figure>

### Key Functionalities

1. **Exploration**: The user is able to access the [Exploration](../data-analysis/predictive/exploration/) tab under [Predictive](../data-analysis/predictive/) by clicking on the desired model row. The user can explore model performances and use PANDORA's explainable AI features here.&#x20;
2.  **Basic Information:**&#x20;

    * **Name**: The user is able to change the name of the dataset uploaded for easy distinction between multiple iterations of the same dataset.&#x20;
    * **Created**: Creation date and time (as per GMT time zone)
    * **Processing time**: Provides the time taken for the models to complete training and testing with the given dataset and samples
    * **Status**: Illustrates how far along has SIMON reached in training and testing the predictive models for the given dataset. This column will convey if there are any errors, if the model training has been cancelled, percent completion during model training progression, and completion.&#x20;

    <figure><img src="../.gitbook/assets/image (1).png" alt=""><figcaption></figcaption></figure>

    * **Sparsity**: Percentage of how sparse the given dataset is. Sparsity below 50% is preferred.
    * **Successful models**: The number of models that were successfully trained and tested out of all the models sent to SIMON for processing.&#x20;
3. **Operations**:

<figure><img src="../.gitbook/assets/image (1) (1).png" alt=""><figcaption></figcaption></figure>

* **More information**: View basic information, processing time and statistics for the successful models&#x20;
  *   Example:

      <figure><img src="../.gitbook/assets/image (3).png" alt=""><figcaption></figcaption></figure>
* **Download queue**: Download the dataset from which predictor and response variables were chosen as a .csv file
* **Delete queue**: Delete the queue if needed to reduce clutter from unsuccessful queues or to free up space
