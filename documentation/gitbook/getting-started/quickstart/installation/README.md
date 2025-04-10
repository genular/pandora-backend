---
icon: laptop
---

# Installation

### **Step 1: Install Docker**

1.  **Check Compatibility**:&#x20;

    Make sure your system meets the following requirements:

    * **Operating System**: Windows, Linux, or MacOS.
    * **Docker Version**: Ensure you have Docker [version 17.05 or later](https://docs.docker.com/engine/installation/).
2. **Install Docker**:
   * Download Docker from [docker.com](https://www.docker.com/) and follow their easy installation instructions.
   * If you’re unsure, you can follow these [detailed steps](https://docs.docker.com/get-docker/) on Docker’s site.
   * Make sure Docker is [properly configured](docker-configuration.md).

### **Step 2: Install PANDORA**

1. **Open Your Terminal**:
   * On Windows, search for **PowerShell** in your Start menu and open it.
   * On MacOS or Linux, open the **Terminal** app.
2.  **Run Installation Command**:

    * Copy the command below and paste it into your terminal, then press **Enter**. This command will install and start PANDORA:

    {% code overflow="wrap" %}
    ```bash
    docker run --rm --detach --name genular --tty --interactive --env IS_DOCKER='true' --env TZ=Europe/London --oom-kill-disable --volume genular_frontend_latest:/var/www/genular/pandora --volume genular_backend_latest:/var/www/genular/pandora-backend --volume genular_data_latest:/mnt/usrdata --publish 3010:3010 --publish 3011:3011 --publish 3012:3012 --publish 3013:3013 genular/pandora:latest
    ```
    {% endcode %}
3. **Access PANDORA**:
   * Open your browser and go to [http://localhost:3010](http://localhost:3010) to start using PANDORA.
4. **Allow Firewall Access** (if prompted):
   * Open your browser and go to [http://localhost:3010](http://localhost:3010) to start using PANDORA.

With that, PANDORA is now installed and ready to use!
