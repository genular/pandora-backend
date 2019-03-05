FROM "genular"
MAINTAINER LogIN- "info@genular.com"

# Set a working directory
WORKDIR /tmp

## Run only if Internet is Enabled!
# RUN apt-get update && apt-get upgrade

ARG  analysis_url=http://localhost:3012
ARG  plots_url=http://localhost:3013
ARG  backend_url=http://localhost:3011
ARG  frontend_url=http://localhost:3010

ARG  sendgrid_api=
ARG  s3_key=
ARG  s3_secret=
ARG  s3_bucket=

## 1st let configure frontend
RUN cd /var/www/genular/simon-frontend \
	# && git pull origin master \
	&& yarn run webpack:web:dev \
	--isDemoServer=false \
	--server_frontend=http://localhost:3010 \
	--server_backend=http://localhost:3011 \
	--server_homepage=http://localhost:3010

## 2nd configure backend
RUN cd /var/www/genular/simon-backend \
	# && git pull origin master \
	&& cd /var/www/genular/simon-backend/server/backend/ \
	&& composer post-install composer post-install '{"default":{"sendgrid_api":"${sendgrid_api}","storage":{"s3":{"key":"${s3_key}","secret":"${s3_secret}","bucket":"${s3_bucket}"}}}}'

COPY ["./supervisord.conf", "/etc/supervisor/conf.d/supervisord.conf"]

#
# Expose the nginx port
#
EXPOSE 3010
EXPOSE 3011
EXPOSE 3012
EXPOSE 3013

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# voila!