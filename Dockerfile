FROM klaemo/couchdb:1.6.1

MAINTAINER Clemens Stolle klaemo@fastmail.fm

ENV COUCHPERUSER_SHA 5d28db3272eea9619d4391b33aae6030f0319ecc54aa2a2f2b6c6a8d448f03f2
RUN apt-get update && apt-get install -y rebar make \
 && mkdir -p /usr/local/lib/couchdb/plugins/couchperuser \
 && cd /usr/local/lib/couchdb/plugins \
 && curl -L -o couchperuser.tar.gz https://github.com/etrepum/couchperuser/archive/1.1.0.tar.gz \
 && echo "$COUCHPERUSER_SHA *couchperuser.tar.gz" | sha256sum -c - \
 && tar -xzf couchperuser.tar.gz -C couchperuser --strip-components=1 \
 && rm couchperuser.tar.gz \
 && cd couchperuser \
 && make \
 && apt-get purge -y --auto-remove rebar make

# use nginx install installation from official dockerfile
# https://github.com/nginxinc/docker-nginx/blob/master/Dockerfile
ENV NGINX_VERSION 1.9.9-1~jessie

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
 && echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
 && apt-get update \
 && apt-get install -y ca-certificates nginx=${NGINX_VERSION} gettext-base \
 && rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

# add config and dummy certificates for localhost
COPY nginx.conf /etc/nginx/
COPY server.crt /etc/nginx/certs/server.crt
COPY server.key /etc/nginx/certs/server.key
COPY dhparams.pem /etc/nginx/certs/dhparams.pem

# create cert chain for OCSP
RUN cd /etc/nginx/certs && cat server.key server.crt dhparams.pem > chain.pem

COPY entrypoint-nginx.sh /

ENTRYPOINT ["/entrypoint-nginx.sh"]
