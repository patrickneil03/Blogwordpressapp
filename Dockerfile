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
RUN cat > /usr/local/etc/php/conf.d/sessions.ini <<'PHP'
session.save_path = /var/lib/php/sessions
session.cookie_lifetime = 86400
session.gc_maxlifetime = 86400
session.cookie_secure = 0
session.use_strict_mode = 1
session.cookie_httponly = 1
session.cookie_samesite = Lax
session.name = WORDPRESS_SESSION
PHP

# Improved Load Balancer Compatibility MU Plugin
RUN cat > /var/www/html/wp-content/mu-plugins/load-balancer-compat.php <<'PHP'
<?php
/**
 * Plugin Name: Load Balancer Compatibility
 * Description: Respect ALB and CloudFront headers
 * Version: 1.3
 */

// Trust forwarded proto from ALB/CloudFront
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

// Trust forwarded host
if (isset($_SERVER['HTTP_X_FORWARDED_HOST'])) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
}

// Ensure WordPress respects the forwarded protocol
if (!defined('FORCE_SSL_ADMIN')) {
    define('FORCE_SSL_ADMIN', false);
}

// Set cookie domain for your domain
if (!defined('COOKIE_DOMAIN')) {
    define('COOKIE_DOMAIN', 'blog.baylenwebsite.xyz');
}

// Fix for WordPress redirect loops behind reverse proxies
if (!defined('WP_HOME')) {
    define('WP_HOME', 'http://blog.baylenwebsite.xyz');
}
if (!defined('WP_SITEURL')) {
    define('WP_SITEURL', 'http://blog.baylenwebsite.xyz');
}

// Additional security headers for reverse proxy setups
if (!defined('CONCATENATE_SCRIPTS')) {
    define('CONCATENATE_SCRIPTS', false);
}
PHP

# WordPress configuration for reverse proxy setup
RUN cat > /var/www/html/wp-config-reverse-proxy.php <<'PHP'
<?php
// Reverse proxy configuration for CloudFront/ALB
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
    $_SERVER['HTTPS'] = 'on';
    $_SERVER['SERVER_PORT'] = 443;
}

if (isset($_SERVER['HTTP_X_FORWARDED_HOST'])) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
}
PHP

# Modify the default WordPress entrypoint to include our reverse proxy config
RUN sed -i '/^<?php/a require_once("wp-config-reverse-proxy.php");' /usr/local/bin/docker-entrypoint.sh

# Ensure correct ownership
RUN chown -R www-data:www-data /var/www/html/wp-content/mu-plugins /var/lib/php/sessions

# Add healthcheck endpoint
RUN echo '<?php http_response_code(200); echo "OK"; ?>' > /var/www/html/health.php

EXPOSE 80

# Healthcheck: internal probe, container checks itself
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fS --max-time 5 http://localhost/health.php || exit 1