#!/bin/bash

SSL=0
CERT_AUTH=0

if [[ $PUPPETCASERVER_URL ]] && [[ $PUPPETSERVER_URL ]]; then
    if [[ $(puppet config print ca_server) != ${PUPPETCASERVER_URL} ]]; then
        puppet config set ca_server ${PUPPETcaSERVER_URL}
    fi
    if [[ $(puppet config print server) != ${PUPPETSERVER_URL} ]]; then
        puppet config set server ${PUPPETSERVER_URL}
    fi
    if [[ $PUPPET_ENV ]]; then
        puppet config set environment ${PUPPET_ENV} --section agent
    fi
    if [[ $(find /var/lib/puppet/ssl -name $(facter fqdn).pem | wc -l) -eq 0 ]]; then
        puppet agent -t --waitforcert 60
    else
        puppet agent -t
    fi
    SSL=1
fi

if [[ $SERVER_NAME ]]; then
    SERVER_NAME_CONFIG="server_name                         ${SERVER_NAME};"
fi

if [[ $CERT_AUTH = 1 ]]; then
    SSL_VERIFY="ssl_client_certificate              /var/lib/puppet/ssl/certs/ca.pem;
    ssl_crl                             /var/lib/puppet/ssl/crl.pem;
    ssl_verify_client                   on;
    ssl_verify_depth                    2;"
else
    SSL_VERIFY=""
fi

if [[ $AWS_ACCESS_KEY ]] && [[ $AWS_SECRET_KEY ]] && [[ $AWS_REGION ]] && [[ $AWS_BUCKET ]]; then
    AWS_SIGNING=$(/generate_signing_key -k ${AWS_SECRET_KEY} -r ${AWS_REGION})
    AWS_SIGNING_KEY=$(echo $AWS_SIGNING | awk '{print $1}')
    AWS_KEY_SCOPE=$(echo $AWS_SIGNING | awk '{print $2}')
    AWS_KEY_CONFIG="    aws_access_key                  ${AWS_ACCESS_KEY};
    aws_key_scope                   ${AWS_KEY_SCOPE};
    aws_signing_key                 ${AWS_SIGNING_KEY};
    aws_s3_bucket                   ${AWS_BUCKET};"
        AWS_PROXY_CONFIG="aws_sign;
        proxy_pass                      http://${AWS_BUCKET}.s3.amazonaws.com;
        proxy_set_header                Host '${AWS_BUCKET}.s3.amazonaws.com';
        proxy_set_header                Authorization '';
        proxy_hide_header               x-amz-id-2;
        proxy_hide_header               x-amz-request-id;
        proxy_hide_header               x-amz-meta-server-side-encryption;
        proxy_hide_header               x-amz-server-side-encryption;
        proxy_hide_header               Set-Cookie;
        proxy_ignore_headers            "Set-Cookie";
        proxy_intercept_errors          on;"
fi

if [[ $CACHE_PATH ]]; then
chown -R nginx:root "${CACHE_PATH}"
CACHE_PATH_CONFIG="proxy_cache_path ${CACHE_PATH} levels=1:2 keys_zone=${CACHE_NAME}:1024m max_size=${CACHE_SIZE} inactive=${CACHE_INACTIVE} use_temp_path=off;"
CACHE_CONFIG="proxy_cache                     ${CACHE_NAME};
        proxy_cache_revalidate          on;
        proxy_cache_valid               200 302 404 5m;
        proxy_cache_use_stale           error timeout updating http_500 http_502 http_503 http_504;
        proxy_cache_background_update   on;
        proxy_cache_lock                on;
        proxy_cache_lock_timeout        5m;"
fi

if [[ $SERVER_NAME ]] && [[ $SSL = 1 ]] && [[ $HTTP = 1 ]]; then
    
/bin/cat <<EOF > /etc/nginx/conf.d/${SERVER_NAME}.conf

${CACHE_PATH_CONFIG}

server {
    listen                              80;
    ${SERVER_NAME_CONFIG}
    ${AWS_KEY_CONFIG}

    location /nginx_status {
        stub_status;
    }

    location / {
        root                            /var/www/html;
        ${AWS_PROXY_CONFIG}
        ${CACHE_CONFIG}
    }
}

server {
    listen                              443 ssl;
    ${SERVER_NAME_CONFIG}
    ${AWS_KEY_CONFIG}
    ssl_certificate                     /var/lib/puppet/ssl/certs/${SERVER_NAME}.pem;
    ssl_certificate_key                 /var/lib/puppet/ssl/private_keys/${SERVER_NAME}.pem;
    ${SSL_VERIFY}
    ssl_protocols                       TLSv1.2 TLSv1.1 TLSv1;
    ssl_prefer_server_ciphers           on;
    ssl_ciphers                         "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";

    location / {
        root                            /var/www/html;
        ${AWS_PROXY_CONFIG}
        ${CACHE_CONFIG}
    }
}
EOF

elif [[ $SERVER_NAME ]] && [[ $SSL = 1 ]]; then
    
/bin/cat <<EOF > /etc/nginx/conf.d/${SERVER_NAME}.conf

${CACHE_PATH_CONFIG}

server {
    listen                              443 ssl;
    ${SERVER_NAME_CONFIG}
    ${AWS_KEY_CONFIG}
    ssl_certificate                     /var/lib/puppet/ssl/certs/${SERVER_NAME}.pem;
    ssl_certificate_key                 /var/lib/puppet/ssl/private_keys/${SERVER_NAME}.pem;
    ${SSL_VERIFY}
    ssl_protocols                       TLSv1.2 TLSv1.1 TLSv1;
    ssl_prefer_server_ciphers           on;
    ssl_ciphers                         "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";

    location / {
        root                            /var/www/html;
        ${AWS_PROXY_CONFIG}
        ${CACHE_CONFIG}
    }
}
EOF

elif [[ $SERVER_NAME ]]; then

/bin/cat <<EOF > /etc/nginx/conf.d/${SERVER_NAME}.conf

${CACHE_PATH_CONFIG}

server {
    listen                              80;
    ${SERVER_NAME_CONFIG}
    ${AWS_KEY_CONFIG}

    location / {
        root                            /var/www/html;
        ${AWS_PROXY_CONFIG}
        ${CACHE_CONFIG}
    }
}
EOF

fi

if [[ $AMPLIFY_API_KEY ]]; then

/usr/bin/curl -sS -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh && API_KEY=\'${AMPLIFY_API_KEY}\' sh ./install.sh

fi

/bin/cat <<EOF > /etc/nginx/conf.d/stub_status.conf
server {
    listen 127.0.0.1:80;
    server_name 127.0.0.1;
    location /nginx_status {
        stub_status on;
        allow 127.0.0.1;
        deny all;
    }
}
EOF



/usr/sbin/nginx

sleep infinity
