---
icon: linux
---

# Linux distribution

PANDORA runs inside a specific, controlled environment to ensure consistent behavior and manage dependencies across different systems and versions.

#### Build Process

* **Environment:** We use a custom Debian based Linux environment.
* **Pipeline:** This environment is created using a dedicated build pipeline, defined in the `make_image.sh` script. This gives us precise control over the operating system and all installed software packages.
* **Consistency:** This approach guarantees that every PANDORA instance runs with the exact same dependencies.
* **PANDORA Preinstallation:** The PANDORA application itself is pre-installed into the environment during the image build process.

#### Base Docker Image

* The final output of the build pipeline is a **base Docker image**. This image contains the customized OS and the pre-installed PANDORA software.
* This base image is published on Docker Hub.
* It serves as the core component upon which final PANDORA releases are built.
