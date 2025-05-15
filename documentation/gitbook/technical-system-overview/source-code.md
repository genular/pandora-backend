---
icon: suse
---

# Source code

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
