#!/usr/bin/env bash
set -e -o pipefail

envsubst '${NAME} ${VERSION}' < nginx.conf > /etc/nginx/nginx.conf

nginx -g 'daemon off;'
