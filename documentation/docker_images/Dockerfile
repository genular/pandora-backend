## 1st import docker image - https://docs.docker.com/engine/reference/commandline/import/#import-from-a-remote-location
## docker import http://example.com/exampleimage.tgz
FROM "genular"
MAINTAINER genular

ARG GIT_FRONTEND="https://github.com/genular/simon-frontend.git"
ARG GIT_BACKEND="https://github.com/genular/simon-backend.git"

ARG server_frontend="http://dashboard.genular.local"
ARG server_backend="http://backend.api.genular.local"
ARG server_homepage="https://genular.org"

ARG NODE_ENV="production"

USER genular
ENV NODE_ENV=$NODE_ENV

# Set a working directory
WORKDIR /tmp

RUN apt-get update

## 1st let configure frontend
RUN cd /var/www/genular/simon-frontend && git pull origin master
## Compile static front-end files!
RUN yarn run webpack:web:dev --server_frontend=$server_frontend --server_backend=$server_backend --server_homepage=$server_homepage

## 2nd configure backend
RUN cd /var/www/genular/simon-backend && git pull origin master

EXPOSE 80