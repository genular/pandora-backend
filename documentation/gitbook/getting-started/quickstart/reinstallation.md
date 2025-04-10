---
description: >-
  If you need to reinstall PANDORA for any reason, please follow these steps
  carefully to remove the old version and start fresh. Note: This will delete
  any previous data and settings.
icon: hashtag
---

# Reinstallation

### **Step 1: List and Identify Docker Components**

1. **Open Terminal** (or PowerShell on Windows).
2. **Find Existing PANDORA Containers**:
   * Type `docker ps -a` and press Enter. This will list all containers.
3. **Find Existing PANDORA Images**:
   * Type `docker images` and press Enter. This will list all images.
4. **Find Existing PANDORA Volumes**:
   * Type `docker volume ls` and press Enter. This will list all volumes.

***

### **Step 2: Remove Old PANDORA Components**

1. **Stop and Remove Containers**:
   *   Stop PANDORA:

       ```bash
       docker stop <CONTAINER_ID>
       ```
   *   Remove the container (if needed):

       ```bash
       docker rm <CONTAINER_ID>
       ```
2. **Remove Docker Images**:
   *   Remove the image:

       ```bash
       docker rmi <IMAGE_ID>
       ```
3. **Remove Docker Volumes**:
   *   Remove PANDORA volumes:

       ```bash
       docker volume rm genular_frontend_latest genular_backend_latest genular_data_latest
       ```

***

### **Step 3: Reinstall PANDORA**

After removing all previous components, follow the [**Installation**](installation/) steps to install a clean version of PANDORA.

***

That’s it! Your PANDORA installation should now be ready for use.
