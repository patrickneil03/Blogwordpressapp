#!/bin/bash
set -e

if [ -f /var/www/html/wp-config.php ]; then
    cat /var/www/html/wp-config-docker.php /var/www/html/wp-config.php > /tmp/wp-config-combined.php
    mv /tmp/wp-config-combined.php /var/www/html/wp-config.php
    echo "[Docker] Applied private subnet configuration"
fi

exec docker-entrypoint.sh "$@"