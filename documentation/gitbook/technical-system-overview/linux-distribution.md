---
icon: linux
---

# Linux Distribution

**Custom Linux Environment**

To guarantee consistent behavior and dependency management across different deployments and versions, PANDORA operates within a custom Debian-based Linux environment.

**Image Build Pipeline:**\
We utilize a specific build pipeline, defined in the make\_image.sh script, to create this custom environment. The primary advantage of this approach is precise control over the operating system and all installed software packages, ensuring every PANDORA instance runs with the exact same dependencies.

**PANDORA Pre-installation:**\
During the image build process, the PANDORA application itself is pre-installed into the environment.

**Base Docker Image:**\
The final output of this pipeline is a base Docker image containing the customized OS and the pre-installed PANDORA software. This base image is published on Docker Hub and acts as the core component upon which final PANDORA releases are built.
