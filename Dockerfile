FROM public.ecr.aws/docker/library/wordpress:php8.2-apache
LABEL maintainer="you@example.com"

ARG WP_CLI_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"

# Install tools and fetch WP-CLI safely
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    curl -fsSL "$WP_CLI_URL" -o /usr/local/bin/wp; \
    chmod +x /usr/local/bin/wp; \
    mkdir -p /var/lib/php/sessions /var/www/html/wp-content/mu-plugins; \
    chown -R www-data:www-data /var/lib/php/sessions; \
    rm -rf /var/lib/apt/lists/*

# Copy security sessions setup
RUN printf '%s\n' \
    'session.save_path = /var/lib/php/sessions' \
    'session.cookie_lifetime = 86400' \
    'session.gc_maxlifetime = 86400' \
    'session.cookie_secure = 1' \
    'session.use_strict_mode = 1' \
    'session.cookie_httponly = 1' \
    'session.cookie_samesite = Lax' \
    'session.name = WORDPRESS_SESSION' \
    > /usr/local/etc/php/conf.d/sessions.ini

# Copy structured config items directly into place
COPY config/load-balancer-compat.php /var/www/html/wp-content/mu-plugins/load-balancer-compat.php
COPY config/wp-config-docker.php /var/www/html/wp-config-docker.php
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh
COPY health.php /var/www/html/health.php

# Correct permissions across filesystem assets
RUN chmod +x /usr/local/bin/custom-entrypoint.sh \
    && chown -R www-data:www-data /var/www/html

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fS --max-time 5 http://localhost/health.php || exit 1

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["apache2-foreground"]