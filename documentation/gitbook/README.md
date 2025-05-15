---
icon: hand-wave
layout:
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: true
---

# Welcome to PANDORA

**PANDORA** is a research platform developed and maintained by [aTomic Lab](https://atomic-lab.org/). It is engineered to leverage advanced statistical methodologies, many specifically designed for the analysis of high-dimensional data prevalent in biomedical research. The platform supports predictive modeling, biomarker discovery, and comprehensive OMICS data analysis, thereby contributing to novel insights in systems biology.

{% include ".gitbook/includes/pandora-overview.md" %}

### Core Capabilities

PANDORA provides a suite of functionalities designed to address the analytical demands of contemporary biomedical research:

* **Data Exploration and Visualization:**
  * Facilitates comprehensive dataset inspection, offering an immediate understanding of data structure and content.
  * Enables rigorous analysis of inter-variable **correlations**.
  * Performs **hierarchical clustering** for systematic grouping of similar samples or features.
  * Implements dimensionality reduction techniques such as **PCA (Principal Component Analysis)**, **t-SNE**, and **UMAP** for effective visualization and pattern identification within high-dimensional datasets (e.g., transcriptomics, proteomics, cytometry data).
* **Predictive Modeling and Biomarker Discovery:**
  * Integrates the **SIMON** toolkit for streamlined development and execution of machine learning models.
  * Supports the construction of models for diverse applications, including outcome prediction (e.g., treatment efficacy, patient stratification) and classification tasks.
  * Aids in the identification of statistically significant **biomarkers** that contribute substantially to model predictions.
* **Model Evaluation and Interpretation:**
  * Provides robust tools for in-depth model assessment, including **variable importance** metrics, **ROC curve analysis** for diagnostic capability evaluation, and advanced **model interpretation** methodologies (Explainable AI).
  * Specifically engineered for the robust analysis of complex **OMICS datasets**, ensuring reliable and reproducible results.

PANDORA is distinguished by the following attributes:

* **Advanced Analytical Power:** Provides access to sophisticated statistical methods and machine learning algorithms through an intuitive graphical user interface, minimizing the need for extensive programming expertise.
* **Biomedical Research Focus:** Optimized for the specific challenges posed by high-dimensional data in fields such as genomics, proteomics, and systems immunology.
* **Integrated Workflow:** Offers a comprehensive, end-to-end environment supporting the entire data analysis pipeline, from initial data exploration and preprocessing to predictive modeling and results interpretation.
* **Simplified Deployment:** Utilizes Docker containerization for streamlined installation and consistent operational environments across various systems.
