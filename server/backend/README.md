# PANDORA PHP Backend

The PANDORA PHP Backend is a robust component of the PANDORA machine learning web-based software, designed to facilitate advanced data analysis and modeling capabilities. Built with the Slim PHP framework, it serves as the backbone of the application.

## Features

- **Modular Route Handling**: Organized endpoints for models, datasets, users, system, and organization management.
- **Dynamic CORS Middleware**: Custom middleware to handle Cross-Origin Resource Sharing (CORS), ensuring secure and flexible cross-domain requests.
- **Configurable Settings**: Utilizes environmental variables and application settings for dynamic configuration, enhancing security and adaptability.
- **Comprehensive Logging**: Integrated with Monolog for detailed logging, aiding in debugging and system monitoring.
- **Template Rendering**: Supports server-side rendering with customizable paths for templates, facilitating dynamic content generation.

## Example nginx configuration:

```nginx
## server {
##     listen 443 ssl;
##     server_name dashboard.genular.org;
## 
##     ssl_certificate /etc/letsencrypt/live/dashboard.genular.org/fullchain.pem;
##     ssl_certificate_key /etc/letsencrypt/live/dashboard.genular.org/privkey.pem;
##     ssl_trusted_certificate /etc/letsencrypt/live/dashboard.genular.org/fullchain.pem;
## 
##     ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
##     ssl_ciphers         HIGH:!aNULL:!MD5;
## 
##     ## Development mode with in-build server
##     ## cd /var/www/genular/pandora && yarn run start:web
##     ## location / {
##     ##     proxy_pass https://localhost:8080;
##     ##     proxy_set_header Host $host;
##     ##     proxy_set_header X-Real-IP $remote_addr;
##     ##     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
##     ##     proxy_set_header X-Forwarded-Proto $scheme;
##     ## }
## 
##     ## Production mode with statics in place
##     ## cd /var/www/genular/pandora && yarn run webpack:web:prod
##     root /var/www/genular/pandora/compiled/web;
##     index index.html;
##     charset utf-8;
##     
##     location / {
##         try_files $uri $uri/ =404;
##     }
## 
##     error_log  /var/log/nginx/dashboard.genular.org_error.log warn;
## }
```
