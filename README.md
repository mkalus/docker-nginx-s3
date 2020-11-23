# Nginx with AWS Authentication Plugin

This Docker image runs Ubuntu with Nginx compiled with ngx_aws_auth module.
It uses Amazons V4 API for authentication against an S3 bucket

This docker image uses nginx 1.19.4 and is additionally compiled with http_image_filter_module.

# Settings

Several options are customizable using environment variables.

* ``AWS_BUCKET``: The name of you S3 Bucket.
* ``AWS_ACCESS_KEY``: The Access Key that gives access to your S3 Bucket.
* ``AWS_SECRET_KEY``: The Secret Key that gives access to your S3 Bucket.
* ``AWS_REGION``: The Region that your bucket is hosted at.
* ``INDEX_FILE``: Set default index filename to rewrite requests for directories, paths ending with ``/``.  Defaults to ``index.html``.
* ``AMPLIFY_API_KEY``: If you want your container monitored by Amplify, add your API key. Might be a good idea to set a hostname on the container.
* ``SERVER_NAME``: Set a server name if you want to have a unique name set in your Nginx config.  If set, nginx will listen on both port ``80`` and ``48480``, the latter so it's unlikely to conflict.
* ``CACHE_PATH``: Set a path for a cache folder if you wan't to enable the caching for Nginx.
* ``CACHE_NAME``: If you want a unique name for your cache (in cacse of multiple). Defaults to ``edge-cache``.
* ``CACHE_SIZE``: Set a max size for you cache. Defaults to ``1g``.
* ``CACHE_INACTIVE``: Set how long to keep things in cache. Defaults to ``1d``.
