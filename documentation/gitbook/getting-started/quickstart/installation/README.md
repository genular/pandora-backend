---
description: This guide outlines the procedure for installing PANDORA via Docker.
icon: laptop
---

# Installation

{% tabs %}
{% tab title="Step 1: Install and Configure Docker" %}
**Prerequisites:**

1. **System Requirements**:
   * Operating System: Windows, Linux, or MacOS.
   * Docker Version: Ensure [version 17.05 or later](https://docs.docker.com/engine/installation/) is installed.
2. **Docker Installation**:
   * Download Docker from [docker.com](https://www.docker.com/) and adhere to the official installation instructions.
   * Detailed installation procedures are available on the [Docker website](https://docs.docker.com/get-docker/).
3. **Resource Allocation (Crucial for Performance)**:
   * PANDORA requires sufficient system resources (CPU and RAM) allocated to Docker for optimal performance.
   * Please review and adjust your Docker resource settings as detailed in our [Docker Configuration Guide](docker-configuration.md) _before proceeding_.
{% endtab %}

{% tab title="Step 2: Deploy PANDORA Container" %}
1.
   1. **Open Terminal/PowerShell**:
      * Windows: Launch **PowerShell**.
      * MacOS/Linux: Open **Terminal**.
   2.  **Execute Deployment Command**:

       * Copy the complete command block below. Paste it into your terminal and press **Enter**. This command will download the latest `genular/pandora:latest` image (if not already present) and start the PANDORA container.

       {% code overflow="wrap" %}
       ```bash
           docker run \
             --rm \
             --detach \
             --name genular \
             --tty \
             --interactive \
             --env IS_DOCKER='true' \
             --env TZ=Europe/London \
             --oom-kill-disable \
             --volume genular_frontend_latest:/var/www/genular/pandora \
             --volume genular_backend_latest:/var/www/genular/pandora-backend \
             --volume genular_data_latest:/mnt/usrdata \
             --publish 3010:3010 \
             --publish 3011:3011 \
             --publish 3012:3012 \
             --publish 3013:3013 \
             genular/pandora:latest
       ```
       {% endcode %}

       **Parameter Explanation:**

       * `--rm`: Automatically removes the container when it exits.
       * `--detach`: Runs the container in the background.
       * `--name genular`: Assigns a recognizable name to the container.
       * `--env IS_DOCKER='true'`, `--env TZ=Europe/London`: Sets environment variables within the container.
       * `--oom-kill-disable`: Disables the Out Of Memory killer for this container (use with caution and ensure sufficient host memory).
       * `--volume ...`: Persistently maps host directories (Docker volumes) to container paths for frontend, backend, and user data. This ensures your data and configurations are saved even if the container stops.
       * `--publish ...`: Maps host ports to container ports, enabling access to PANDORA services (e.g., 3010 for the main UI).
       * `genular/pandora:latest`: Specifies the Docker image to use.
   3. **Firewall Configuration** (If Applicable):
      * Your operating system's firewall may prompt for permission to allow Docker to expose the specified ports (3010-3013). Grant the necessary access.
   4. **Initial Access and Account Creation**:
      * Once the container is running (this may take a minute on first launch as the image is downloaded and services initialize), open a web browser.
      * Navigate to `http://localhost:3010`.
      * You will be directed to the PANDORA login screen. Proceed with [Account Creation](../../../general/user-account/account-creation.md) to begin using the platform.
{% endtab %}
{% endtabs %}
