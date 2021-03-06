#!/bin/bash

if [[ $SERVER_NAME ]]; then
    SERVER_NAME_CONFIG="server_name ${SERVER_NAME};"
fi

if [[ $AWS_ACCESS_KEY ]] && [[ $AWS_SECRET_KEY ]] && [[ $AWS_REGION ]] && [[ $AWS_BUCKET ]]; then

    if [[ $INDEX_FILE ]]; then
        INDEX_FILE_CONFIG="        rewrite ^(.*)/$ \$1/${INDEX_FILE};"
    fi

    AWS_SIGNING=$(/generate_signing_key -k ${AWS_SECRET_KEY} -r ${AWS_REGION})
    AWS_SIGNING_KEY=$(echo $AWS_SIGNING | awk '{print $1}')
    AWS_KEY_SCOPE=$(echo $AWS_SIGNING | awk '{print $2}')
    AWS_KEY_CONFIG="${INDEX_FILE_CONFIG}
        aws_access_key ${AWS_ACCESS_KEY};
        aws_key_scope ${AWS_KEY_SCOPE};
        aws_signing_key ${AWS_SIGNING_KEY};
        aws_s3_bucket ${AWS_BUCKET};"
        AWS_PROXY_CONFIG="aws_sign;
        proxy_pass http://${AWS_BUCKET}.s3.amazonaws.com;
        proxy_set_header Host '${AWS_BUCKET}.s3.amazonaws.com';
        proxy_set_header Authorization '';
        proxy_hide_header x-amz-id-2;
        proxy_hide_header x-amz-request-id;
        proxy_hide_header x-amz-meta-server-side-encryption;
        proxy_hide_header x-amz-server-side-encryption;
        proxy_hide_header Set-Cookie;
        proxy_ignore_headers "Set-Cookie";
        proxy_intercept_errors on;"
fi

if [[ $CACHE_PATH ]]; then
chown -R nginx:root ${CACHE_PATH}
CACHE_PATH_CONFIG="proxy_cache_path ${CACHE_PATH} levels=1:2 keys_zone=${CACHE_NAME}:1024m max_size=${CACHE_SIZE} inactive=${CACHE_INACTIVE} use_temp_path=off;"
CACHE_CONFIG="proxy_cache ${CACHE_NAME};
        proxy_cache_revalidate on;
        proxy_cache_valid 200 302 404 5m;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_cache_background_update on;
        proxy_cache_lock on;
        proxy_cache_lock_timeout 5m;"
fi

if [[ $SERVER_NAME ]]; then
    
/bin/cat <<EOF > /etc/nginx/conf.d/${SERVER_NAME}.conf

${CACHE_PATH_CONFIG}

server {
    listen 80;
    listen 48480;
    ${SERVER_NAME_CONFIG}
    ${AWS_KEY_CONFIG}

    location /nginx_status {
        stub_status;
    }

    location / {
        root   /var/www/html;
        ${AWS_PROXY_CONFIG}
        ${CACHE_CONFIG}
    }
}
EOF

fi

if [[ $AMPLIFY_API_KEY ]]; then

/usr/bin/curl -sS -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh && API_KEY=\'${AMPLIFY_API_KEY}\' sh ./install.sh

/bin/cat <<EOF > /etc/nginx/conf.d/stub_status.conf
server {
    listen 127.0.0.1:80;
    server_name 127.0.0.1;
    location /nginx_status {
        stub_status;
        allow 127.0.0.1;
        deny all;
    }
}
EOF

fi

/usr/sbin/nginx
