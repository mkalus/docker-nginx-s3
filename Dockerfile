FROM ubuntu:19.04

ENV NGINX_VERSION=1.14.2

RUN apt-get update && \
    apt-get -y install curl build-essential libpcre3 libpcre3-dev zlib1g-dev libssl-dev git && \
    curl -LO http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    git clone https://github.com/anomalizer/ngx_aws_auth.git && \
    ./configure --with-http_ssl_module --add-module=ngx_aws_auth --prefix=/etc/nginx --conf-path=/var/log/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin/nginx && \
    make install && \
    cp generate_signing_key / && \
    cd /tmp && \
    rm -f nginx-${NGINX_VERSION}.tar.gz && \
    rm -rf nginx-${NGINX_VERSION} && \
    apt-get purge -y curl git && \
    apt-get autoremove -y && \
    update-rc.d -f nginx remove && \
    rm -f /etc/nginx/sites-enabled/default && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD run.sh /run.sh

WORKDIR /etc/nginx

EXPOSE 80
EXPOSE 443

CMD /bin/bash /run.sh
