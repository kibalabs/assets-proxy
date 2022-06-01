#!/usr/bin/env bash
set -e -o pipefail

envsubst '${NAME} ${VERSION}' < /app/nginx.conf > /etc/nginx/nginx.conf

exec nginx -g 'daemon off;'
