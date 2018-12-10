# Nginx with AWS Authentication Plugin

This Docker image runs Ubuntu with Nginx compiled with ngx_aws_auth module.
It uses Amazons V4 API for authentication agains an S3 bucket

# Settings

Several options are customizable using environment variables.

* ``AWS_BUCKET``: The name of you S3 Bucket.
* ``AWS_SECRET_KEY``: The Secret Key that gives access to your S3 Bucket.
* ``AWS_REGION``: The Region that your bucket is hosted at.
* ``AMPLIFY_API_KEY``: If you want your container monitored by Amplify, add your API key.
* ``SERVER_NAME``: Set a server name if you want to have a unique name for Amplify. Defaults to ``20003``.
* ``CACHE_PATH``: Set a path for a cache folder if you wan't to enable the caching for Nginx.
* ``CACHE_NAME``: If you want a unique name for your cache (in cacse of multiple). Defaults to ``edge-cache``.
* ``CACHE_SIZE``: Set a max size for you cache. Defaults to ``1g``.
* ``CACHE_INACTIVE``: Set how long to keep things in cache. Defaults to ``1d``.

```
