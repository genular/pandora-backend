FROM "genular"

RUN \\
  apt-get update && \\
  apt-get install nginx

WORKDIR /etc/nginx

CMD ["nginx", "-g", "daemon off;"]

EXPOSE 80