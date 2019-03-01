FROM "genular"
MAINTAINER LogIN- "info@genular.com"

# Set a working directory
WORKDIR /tmp
# RUN apt-get update && apt-get upgrade

## 1st let configure frontend
RUN cd /var/www/genular/simon-frontend \
	# && git pull origin master \
	&& yarn run webpack:web:dev

## 2nd configure backend
#RUN cd /var/www/genular/simon-backend \
	# && git pull origin master \
	# && cd /var/www/genular/simon-backend/server/backend/
	# && composer update


COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

#
# Expose the SSH port
#
EXPOSE 22

#
# Expose the nginx port
#
EXPOSE 80

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# voila!