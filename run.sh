#!/bin/bash

SERVER_NAME="munki-test.diller.com"
AWS_SECRET_KEY="AKIAIWJGZCNATFU4S5FA"
AWS_REGION="eu-central-10"
AWS_BUCKET="bestseller-munki-repo"
CACHE_PATH="/cache/munki"
CACHE_NAME="edge-cache"
CACHE_SIZE="1g"
CACHE_INACTIVE="1d"
CACHE_CONFIG_PATH=""
CACHE_CONFIG=""

if [[ $AMPLIFY_API_KEY ]]; then

curl -sS -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh && API_KEY='${AMPLIFY_API_KEY}' sh ./install.sh

cat <<EOF > /etc/nginx/conf.d/stub_status.conf
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

fi

if [[ $AWS_SECRET_KEY ]] && [[ $AWS_REGION ]]; then
	AWS_SIGNING=$(./generate_signing_key -k ${AWS_SECRET_KEY} -r ${AWS_REGION})
	AWS_SIGNING_KEY=$(echo $AWS_SIGNING | awk '{print $1}')
	AWS_KEY_SCOPE=$(echo $AWS_SIGNING | awk '{print $2}')
fi

if [[ $CACHE_PATH ]]; then
CACHE_CONFIG="proxy_cache_path ${CACHE_PATH} levels=1:2 keys_zone=${CACHE_NAME}:1024m max_size=${CACHE_SIZE} inactive=${CACHE_INACTIVE} use_temp_path=off;
        proxy_cache ${CACHE_NAME};
        proxy_cache_revalidate on;
        proxy_cache_valid 200 302 404 5m;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_cache_background_update on;
        proxy_cache_lock on;
        proxy_cache_lock_timeout 5m;"
fi

if [[ $SERVER_NAME ]] && [[ $AWS_BUCKET ]] && [[ $AWS_SIGNING_KEY ]]; then
echo "DILLER"
#cat <<EOF > /etc/nginx/conf.d/${SERVER_NAME}.conf
cat <<EOF > ./${SERVER_NAME}.conf
server {
    listen 80;
    server_name ${SERVER_NAME};
    aws_access_key ${AWS_SECRET_KEY};
    aws_key_scope ${AWS_KEY_SCOPE};
    aws_signing_key ${AWS_SIGNING_KEY};
    aws_s3_bucket ${AWS_BUCKET};

    location / {
        aws_sign;
        proxy_pass http://${AWS_BUCKET}.s3.amazonaws.com;
        proxy_set_header Host '${AWS_BUCKET}.s3.amazonaws.com';
        proxy_set_header Authorization '';
        proxy_hide_header x-amz-id-2;
        proxy_hide_header x-amz-request-id;
        proxy_hide_header x-amz-meta-server-side-encryption;
        proxy_hide_header x-amz-server-side-encryption;
        proxy_hide_header Set-Cookie;
        proxy_ignore_headers "Set-Cookie";
        proxy_intercept_errors on;
        ${CACHE_CONFIG}
    }
}
EOF

fi

#/usr/sbin/nginx
