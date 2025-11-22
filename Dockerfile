FROM wordpress:php8.2-apache
LABEL maintainer="you@example.com"

ARG WP_CLI_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"

# Install minimal tools, fetch WP-CLI, create session and mu-plugins dirs, set ownership
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    curl -fsSL "$WP_CLI_URL" -o /usr/local/bin/wp; \
    chmod +x /usr/local/bin/wp; \
    mkdir -p /var/lib/php/sessions /var/www/html/wp-content/mu-plugins; \
    chown -R www-data:www-data /var/lib/php/sessions /var/www/html/wp-content/mu-plugins; \
    rm -rf /var/lib/apt/lists/*

# PHP session configuration (HTTP-only)
RUN printf '%s\n' \
    'session.save_path = /var/lib/php/sessions' \
    'session.cookie_lifetime = 86400' \
    'session.gc_maxlifetime = 86400' \
    'session.cookie_secure = 0' \
    'session.use_strict_mode = 1' \
    'session.cookie_httponly = 1' \
    'session.cookie_samesite = Lax' \
    'session.name = WORDPRESS_SESSION' \
    > /usr/local/etc/php/conf.d/sessions.ini

# Improved Load Balancer Compatibility MU Plugin
RUN printf '%s\n' \
    '<?php' \
    '/**' \
    ' * Plugin Name: Load Balancer Compatibility' \
    ' * Description: Respect ALB and CloudFront headers' \
    ' * Version: 1.3' \
    ' */' \
    '' \
    '// Trust forwarded proto from ALB/CloudFront' \
    'if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] === "https") {' \
    '    $_SERVER["HTTPS"] = "on";' \
    '}' \
    '' \
    '// Trust forwarded host' \
    'if (isset($_SERVER["HTTP_X_FORWARDED_HOST"])) {' \
    '    $_SERVER["HTTP_HOST"] = $_SERVER["HTTP_X_FORWARDED_HOST"];' \
    '}' \
    '' \
    '// Ensure WordPress respects the forwarded protocol' \
    'if (!defined("FORCE_SSL_ADMIN")) {' \
    '    define("FORCE_SSL_ADMIN", false);' \
    '}' \
    '' \
    '// Set cookie domain for your domain' \
    'if (!defined("COOKIE_DOMAIN")) {' \
    '    define("COOKIE_DOMAIN", "blog.baylenwebsite.xyz");' \
    '}' \
    '' \
    '// Fix for WordPress redirect loops behind reverse proxies' \
    'if (!defined("WP_HOME")) {' \
    '    define("WP_HOME", "http://blog.baylenwebsite.xyz");' \
    '}' \
    'if (!defined("WP_SITEURL")) {' \
    '    define("WP_SITEURL", "http://blog.baylenwebsite.xyz");' \
    '}' \
    '' \
    '// Additional security headers for reverse proxy setups' \
    'if (!defined("CONCATENATE_SCRIPTS")) {' \
    '    define("CONCATENATE_SCRIPTS", false);' \
    '}' \
    > /var/www/html/wp-content/mu-plugins/load-balancer-compat.php

# WordPress configuration for reverse proxy setup
RUN printf '%s\n' \
    '<?php' \
    '// Reverse proxy configuration for CloudFront/ALB' \
    'if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] == "https") {' \
    '    $_SERVER["HTTPS"] = "on";' \
    '    $_SERVER["SERVER_PORT"] = 443;' \
    '}' \
    '' \
    'if (isset($_SERVER["HTTP_X_FORWARDED_HOST"])) {' \
    '    $_SERVER["HTTP_HOST"] = $_SERVER["HTTP_X_FORWARDED_HOST"];' \
    '}' \
    > /var/www/html/wp-config-reverse-proxy.php

# Create a custom entrypoint wrapper that includes our reverse proxy config
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '' \
    '# Include reverse proxy config in wp-config.php if it exists' \
    'if [ -f /var/www/html/wp-config.php ] && [ -f /var/www/html/wp-config-reverse-proxy.php ]; then' \
    '    if ! grep -q "wp-config-reverse-proxy.php" /var/www/html/wp-config.php; then' \
    '        sed -i '\''1a require_once(ABSPATH . "wp-config-reverse-proxy.php");'\'' /var/www/html/wp-config.php' \
    '    fi' \
    'fi' \
    '' \
    '# Call the original entrypoint' \
    'exec docker-entrypoint.sh "$@"' \
    > /usr/local/bin/custom-entrypoint.sh

RUN chmod +x /usr/local/bin/custom-entrypoint.sh

# Ensure correct ownership
RUN chown -R www-data:www-data /var/www/html/wp-content/mu-plugins /var/lib/php/sessions

# Add healthcheck endpoint
RUN echo '<?php http_response_code(200); echo "OK"; ?>' > /var/www/html/health.php

EXPOSE 80

# Healthcheck: internal probe, container checks itself
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fS --max-time 5 http://localhost/health.php || exit 1

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["apache2-foreground"]