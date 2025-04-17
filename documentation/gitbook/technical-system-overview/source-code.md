---
icon: suse
---

# Source Code

### Technical Details

#### Operating Environment & Build Process

* **Standardized Environment:** PANDORA runs within a Docker container based on a custom Debian Linux image. This ensures all versions operate with identical software dependencies, providing a consistent experience.
* **Build Script:** The image is built using the `make_image.sh` script.
* **Pre-installation:** This build process includes pre-installing the PANDORA software directly into the Docker image.
* **Base Image:** The resulting base Docker image is published to Docker Hub and serves as the foundation for all official PANDORA releases.

#### Source Code Structure

The PANDORA source code is organized into two main GitHub repositories:

* **Frontend:** [`genular/pandora`](https://github.com/genular/pandora)
  * Contains the user interface application.
  * Developed using the Vue.js framework.
* **Backend:** [`genular/pandora-backend`](https://github.com/genular/pandora-backend)
  * Houses the core backend logic.
  * Includes modules written in PHP, R, and Python to handle data processing, statistical analysis, and server-side operations.

This separation allows for independent development and deployment cycles for the UI and the core analysis engine. Both components are bundled together in the final Docker image during the build process.

<img src="../.gitbook/assets/file.excalidraw.svg" alt="Structure" class="gitbook-drawing">
