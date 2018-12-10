FROM ubuntu:18.04

ENV NGINX_VERSION=1.14.2
ENV CACHE_NAME="edge-cache"
ENV CACHE_SIZE="1g"
ENV CACHE_INACTIVE="1d"

RUN apt-get update && \
    apt-get -y install curl build-essential libpcre3 libpcre3-dev zlib1g-dev libssl-dev git python2.7 && \
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
    curl -fs http://nginx.org/keys/nginx_signing.key | apt-key add - &&\
    codename=`lsb_release -cs` && \
    os=`lsb_release -is | tr '[:upper:]' '[:lower:]'` && \
    echo "deb http://packages.amplify.nginx.com/${os}/ ${codename} amplify-agent" > \
    /etc/apt/sources.list.d/nginx-amplify.list &&\
    apt-get update &&\
    apt-get install nginx-amplify-agent &&\
    rm -f /etc/nginx/sites-enabled/default && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#ADD nginx.conf /etc/nginx/nginx.conf
ADD run.sh /run.sh

VOLUME /etc/nginx/conf.d

WORKDIR /etc/nginx

EXPOSE 80
EXPOSE 443

CMD /bin/bash /run.sh
