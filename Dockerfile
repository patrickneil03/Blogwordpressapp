FROM public.ecr.aws/docker/library/wordpress:php8.2-apache
LABEL maintainer="you@example.com"

ARG WP_CLI_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"

# Install minimal tools, fetch WP-CLI, create session dir, set ownership
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    curl -fsSL "$WP_CLI_URL" -o /usr/local/bin/wp; \
    chmod +x /usr/local/bin/wp; \
    mkdir -p /var/lib/php/sessions; \
    chown -R www-data:www-data /var/lib/php/sessions; \
    rm -rf /var/lib/apt/lists/*

# PHP session configuration (HTTP-only)
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

# Improved Load Balancer Compatibility MU Plugin
RUN mkdir -p /var/www/html/wp-content/mu-plugins && \
    printf '%s\n' \
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
    '    define("WP_HOME", "https://blog.baylenwebsite.xyz");' \
    '}' \
    'if (!defined("WP_SITEURL")) {' \
    '    define("WP_SITEURL", "https://blog.baylenwebsite.xyz");' \
    '}' \
    '' \
    '// Additional security headers for reverse proxy setups' \
    'if (!defined("CONCATENATE_SCRIPTS")) {' \
    '    define("CONCATENATE_SCRIPTS", false);' \
    '}' \
    > /var/www/html/wp-content/mu-plugins/load-balancer-compat.php && \
    chown -R www-data:www-data /var/www/html/wp-content/mu-plugins

# ============================================
# SIMPLE FIX: All configurations in one file
# ============================================
RUN cat > /var/www/html/wp-config-docker.php << 'EOF'
<?php
// ============================================
// DOCKER CONFIGURATION FOR PRIVATE SUBNET
// ============================================

// BLOCK EXTERNAL CALLS - Prevents 30s timeouts
define("WP_HTTP_BLOCK_EXTERNAL", true);

// DISABLE UPDATES - No internet access
define("AUTOMATIC_UPDATER_DISABLED", true);
define("WP_AUTO_UPDATE_CORE", false);

// USE SYSTEM CRON INSTEAD
define("DISABLE_WP_CRON", true);

// REVERSE PROXY CONFIGURATION
if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] == "https") {
    $_SERVER["HTTPS"] = "on";
    $_SERVER["SERVER_PORT"] = 443;
}
if (isset($_SERVER["HTTP_X_FORWARDED_HOST"])) {
    $_SERVER["HTTP_HOST"] = $_SERVER["HTTP_X_FORWARDED_HOST"];
}

// LOAD BALANCER SETTINGS
if (!defined("FORCE_SSL_ADMIN")) {
    define("FORCE_SSL_ADMIN", false);
}
if (!defined("COOKIE_DOMAIN")) {
    define("COOKIE_DOMAIN", "blog.baylenwebsite.xyz");
}
if (!defined("WP_HOME")) {
    define("WP_HOME", "https://blog.baylenwebsite.xyz");
}
if (!defined("WP_SITEURL")) {
    define("WP_SITEURL", "https://blog.baylenwebsite.xyz");
}
EOF

# Create a SIMPLE entrypoint that always works
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '' \
    '# Always include Docker config if wp-config.php exists' \
    'if [ -f /var/www/html/wp-config.php ]; then' \
    '    # Prepend our Docker config to the existing wp-config.php' \
    '    cat /var/www/html/wp-config-docker.php /var/www/html/wp-config.php > /tmp/wp-config-combined.php' \
    '    mv /tmp/wp-config-combined.php /var/www/html/wp-config.php' \
    '    echo "[Docker] Applied private subnet configuration"' \
    'fi' \
    '' \
    '# Call the original entrypoint' \
    'exec docker-entrypoint.sh "$@"' \
    > /usr/local/bin/custom-entrypoint.sh && \
    chmod +x /usr/local/bin/custom-entrypoint.sh

# Add healthcheck endpoint
RUN echo '<?php http_response_code(200); echo "OK"; ?>' > /var/www/html/health.php

EXPOSE 80

# Healthcheck: internal probe, container checks itself
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fS --max-time 5 http://localhost/health.php || exit 1

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["apache2-foreground"]