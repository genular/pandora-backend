---
cover: >-
  https://images.unsplash.com/photo-1640552435388-a54879e72b28?crop=entropy&cs=srgb&fm=jpg&ixid=M3wxOTcwMjR8MHwxfHNlYXJjaHw1fHxsaW51eHxlbnwwfHx8fDE3NDQzMTE5MTh8MA&ixlib=rb-4.0.3&q=85
coverY: 0
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
