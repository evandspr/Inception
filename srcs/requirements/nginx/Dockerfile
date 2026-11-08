FROM debian:bookworm

RUN apt-get update \
	&& apt-get install -y --no-install-recommends nginx openssl \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -f /etc/nginx/sites-enabled/default

COPY conf/nginx.conf /etc/nginx/conf.d/inception.conf.template
COPY tools/start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/start.sh"]
