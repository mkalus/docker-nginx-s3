FROM ubuntu:bionic

ENV NGINX_VERSION=1.15.10
ENV CACHE_NAME="edge-cache"
ENV CACHE_SIZE="1g"
ENV CACHE_INACTIVE="1d"
ENV HTTP=0

RUN apt-get update && \
    apt-get -y install ca-certificates curl build-essential python sudo libpcre3 libpcre3-dev zlib1g-dev libssl-dev git distro-info-data libmpdec2 libpython3-stdlib libpython3.6-minimal libpython3.6-stdlib lsb-release python3 python3-minimal python3.6 python3.6-minimal && \
    curl -LO http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    git clone https://github.com/anomalizer/ngx_aws_auth.git && \
    ./configure --with-http_ssl_module --user=nginx --group=nginx --with-http_stub_status_module --add-module=ngx_aws_auth --prefix=/etc/nginx --conf-path=/var/log/nginx --conf-path=/etc/nginx/nginx.conf --sbin-path=/usr/sbin/nginx && \
    make install && \
    cp ./ngx_aws_auth/generate_signing_key / && \
    rm -f /nginx-${NGINX_VERSION}.tar.gz && \
    rm -rf /nginx-${NGINX_VERSION} && \
    apt-get purge -y git && \
    apt-get autoremove -y && \
    update-rc.d -f nginx remove && \
    rm -f /etc/nginx/sites-enabled/default && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    useradd --comment 'Nginx' --shell /bin/false --home /dev/null nginx

ADD https://apt.puppetlabs.com/puppet-release-bionic.deb /puppet-release-bionic.deb
RUN dpkg -i /puppet-release-bionic.deb && apt-get update
RUN rm -f /puppet-release-bionic.deb
RUN apt-get install -y puppet
ADD csr_attributes.yaml /etc/puppet/csr_attributes.yaml

ADD nginx.conf /etc/nginx/nginx.conf
ADD nginx.service /etc/systemd/system/nginx.service
ADD run.sh /run.sh

VOLUME ["/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html", "/etc/puppet", "/var/cache/puppet"]

WORKDIR /etc/nginx

EXPOSE 80
EXPOSE 443

CMD /bin/bash /run.sh
