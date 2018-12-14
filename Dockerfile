FROM ubuntu:18.04

ENV NGINX_VERSION=1.14.2
ENV CACHE_NAME="edge-cache"
ENV CACHE_SIZE="1g"
ENV CACHE_INACTIVE="1d"

RUN apt-get update && \
    apt-get -y install curl build-essential python libpcre3 libpcre3-dev zlib1g-dev libssl-dev git && \
    curl -LO http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    git clone https://github.com/anomalizer/ngx_aws_auth.git && \
    ./configure --with-http_ssl_module --add-module=ngx_aws_auth --prefix=/etc/nginx --conf-path=/var/log/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin/nginx && \
    make install && \
    cp ./ngx_aws_auth/generate_signing_key / && \
    cd /tmp && \
    rm -f nginx-${NGINX_VERSION}.tar.gz && \
    rm -rf nginx-${NGINX_VERSION} && \
    apt-get purge -y git && \
    apt-get autoremove -y && \
    update-rc.d -f nginx remove && \
    rm -f /etc/nginx/sites-enabled/default && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD nginx.conf /etc/nginx/nginx.conf
ADD run.sh /run.sh

VOLUME ["/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]

WORKDIR /etc/nginx

EXPOSE 80
EXPOSE 443

CMD /bin/bash /run.sh
