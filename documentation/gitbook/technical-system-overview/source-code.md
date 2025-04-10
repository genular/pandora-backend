# Source Code

**Technical Details**

**Operating Environment & Build Process**

PANDORA runs within a standardized environment based on a custom Debian Linux image. This ensures that all PANDORA versions operate with identical software dependencies, eliminating environment-related inconsistencies.

The image is constructed using a dedicated script (`make_image.sh`). This process includes pre-installing the PANDORA software directly into the image. The resulting artifact is a base Docker image, which is published to Docker Hub and serves as the foundation for all official PANDORA releases.

**Source Code Structure**

The PANDORA source code is organized into two distinct GitHub repositories:

1. **Frontend:** ([`genular/pandora`](https://github.com/genular/pandora)) This repository contains the user interface application, developed using the Vue.js framework.
2. **Backend:** ([`genular/pandora-backend`](https://github.com/genular/pandora-backend)) This repository houses the backend logic, which consists of multiple modules written in PHP, R, and Python to handle data processing, analysis, and server-side operations.

This separation allows for independent development and deployment of the user interface and the core processing components. Both components are ultimately included in the final Docker image build.
