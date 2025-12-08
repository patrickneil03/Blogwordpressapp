FROM public.ecr.aws/docker/library/wordpress:php8.2-apache
LABEL maintainer="you@example.com"

ARG WP_CLI_URL="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"

# ============================================
# STAGE 1: INSTALL DEPENDENCIES & TOOLS
# ============================================
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        less \
        nano \
        jq \
        redis-tools \
        gnupg \
        lsb-release; \
    curl -fsSL "$WP_CLI_URL" -o /usr/local/bin/wp; \
    chmod +x /usr/local/bin/wp; \
    mkdir -p /var/lib/php/sessions; \
    chown -R www-data:www-data /var/lib/php/sessions; \
    rm -rf /var/lib/apt/lists/*

# ============================================
# STAGE 2: PHP CONFIGURATION
# ============================================

# PHP session configuration
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

# PHP PERFORMANCE OPTIMIZATIONS (CRITICAL FOR SPEED)
RUN printf '%s\n' \
    '; ===========================================' \
    '; PHP PERFORMANCE OPTIMIZATION' \
    '; ===========================================' \
    'opcache.enable=1' \
    'opcache.memory_consumption=256' \
    'opcache.interned_strings_buffer=16' \
    'opcache.max_accelerated_files=10000' \
    'opcache.revalidate_freq=2' \
    'opcache.fast_shutdown=1' \
    'opcache.enable_cli=0' \
    'opcache.validate_timestamps=0' \
    'opcache.save_comments=1' \
    'opcache.consistency_checks=0' \
    '' \
    'realpath_cache_size=4096K' \
    'realpath_cache_ttl=600' \
    '' \
    'max_execution_time=300' \
    'max_input_time=180' \
    'memory_limit=256M' \
    'post_max_size=100M' \
    'upload_max_filesize=100M' \
    '' \
    'expose_php=Off' \
    'display_errors=Off' \
    'log_errors=On' \
    'error_log=/var/log/php_errors.log' \
    > /usr/local/etc/php/conf.d/performance.ini

# Install PHP Redis extension for object caching
RUN apt-get update && \
    apt-get install -y --no-install-recommends php-redis && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# STAGE 3: WORDPRESS CONFIGURATION
# ============================================

# Improved Load Balancer Compatibility MU Plugin
RUN mkdir -p /var/www/html/wp-content/mu-plugins && \
    printf '%s\n' \
    '<?php' \
    '/**' \
    ' * Plugin Name: Load Balancer Compatibility' \
    ' * Description: Respect ALB and CloudFront headers' \
    ' * Version: 1.4' \
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
    '' \
    '// Enable Redis Object Cache if available' \
    'if (!defined("WP_REDIS_HOST")) {' \
    '    define("WP_REDIS_HOST", "127.0.0.1");' \
    '}' \
    'if (!defined("WP_REDIS_PORT")) {' \
    '    define("WP_REDIS_PORT", 6379);' \
    '}' \
    'if (!defined("WP_REDIS_TIMEOUT")) {' \
    '    define("WP_REDIS_TIMEOUT", 1);' \
    '}' \
    'if (!defined("WP_REDIS_READ_TIMEOUT")) {' \
    '    define("WP_REDIS_READ_TIMEOUT", 1);' \
    '}' \
    '' \
    '// Disable WordPress embeds (reduces external calls)' \
    'function disable_embeds_code_init() {' \
    '    remove_action("wp_head", "wp_oembed_add_discovery_links");' \
    '    remove_action("wp_head", "wp_oembed_add_host_js");' \
    '}' \
    'add_action("init", "disable_embeds_code_init");' \
    '' \
    '// Use local gravatar fallback' \
    'function local_gravatar($avatar, $id_or_email, $size, $default, $alt, $args) {' \
    '    return "<img src=\"/wp-content/uploads/default-avatar.png\" width=\"$size\" height=\"$size\" alt=\"$alt\" class=\"avatar\" />";' \
    '}' \
    'add_filter("get_avatar", "local_gravatar", 1, 6);' \
    '' \
    '// Preconnect to local domains only' \
    'function remove_external_resource_hints($hints, $relation_type) {' \
    '    if ("dns-prefetch" === $relation_type || "preconnect" === $relation_type) {' \
    '        return array_filter($hints, function($hint) {' \
    '            return strpos($hint, "blog.baylenwebsite.xyz") !== false ||' \
    '                   strpos($hint, "localhost") !== false ||' \
    '                   strpos($hint, "127.0.0.1") !== false;' \
    '        });' \
    '    }' \
    '    return $hints;' \
    '}' \
    'add_filter("wp_resource_hints", "remove_external_resource_hints", 10, 2);' \
    > /var/www/html/wp-content/mu-plugins/load-balancer-compat.php && \
    chown -R www-data:www-data /var/www/html/wp-content/mu-plugins

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

# ============================================
# STAGE 4: PRIVATE SUBNET CONFIGURATION
# ============================================
RUN printf '%s\n' \
    '<?php' \
    '// ===========================================' \
    '// PRIVATE SUBNET CONFIGURATION' \
    '// Critical for WordPress without internet access' \
    '// ===========================================' \
    '' \
    '// BLOCK ALL EXTERNAL HTTP REQUESTS (prevents 30s timeouts)' \
    'define("WP_HTTP_BLOCK_EXTERNAL", true);' \
    '' \
    '// DISABLE ALL AUTOMATIC UPDATES (no internet access)' \
    'define("AUTOMATIC_UPDATER_DISABLED", true);' \
    'define("WP_AUTO_UPDATE_CORE", false);' \
    '' \
    '// DISABLE EXTERNAL WP-CRON - Use system cron instead' \
    'define("DISABLE_WP_CRON", true);' \
    '' \
    '// DISABLE XML-RPC (security + prevents external calls)' \
    'if (!defined("XMLRPC_ENABLED")) {' \
    '    define("XMLRPC_ENABLED", false);' \
    '}' \
    '' \
    '// FORCE SSL for admin (behind ALB/CloudFront)' \
    'if (!defined("FORCE_SSL_ADMIN")) {' \
    '    define("FORCE_SSL_ADMIN", true);' \
    '}' \
    'if (!defined("FORCE_SSL_LOGIN")) {' \
    '    define("FORCE_SSL_LOGIN", true);' \
    '}' \
    '' \
    '// OPTIMIZE DATABASE QUERIES' \
    'if (!defined("SAVEQUERIES")) {' \
    '    define("SAVEQUERIES", false);' \
    '}' \
    '' \
    '// ENABLE DEBUG LOGGING (temporarily)' \
    'if (!defined("WP_DEBUG")) {' \
    '    define("WP_DEBUG", true);' \
    '}' \
    'if (!defined("WP_DEBUG_LOG")) {' \
    '    define("WP_DEBUG_LOG", true);' \
    '}' \
    'if (!defined("WP_DEBUG_DISPLAY")) {' \
    '    define("WP_DEBUG_DISPLAY", false);' \
    '}' \
    '' \
    '// COMPRESSION SETTINGS' \
    'if (!defined("COMPRESS_CSS")) {' \
    '    define("COMPRESS_CSS", true);' \
    '}' \
    'if (!defined("COMPRESS_SCRIPTS")) {' \
    '    define("COMPRESS_SCRIPTS", true);' \
    '}' \
    'if (!defined("CONCATENATE_SCRIPTS")) {' \
    '    define("CONCATENATE_SCRIPTS", false);' \
    '}' \
    'if (!defined("ENFORCE_GZIP")) {' \
    '    define("ENFORCE_GZIP", true);' \
    '}' \
    '' \
    '// DISABLE POST REVISIONS' \
    'if (!defined("WP_POST_REVISIONS")) {' \
    '    define("WP_POST_REVISIONS", 3);' \
    '}' \
    '' \
    '// DISABLE TRASH' \
    'if (!defined("EMPTY_TRASH_DAYS")) {' \
    '    define("EMPTY_TRASH_DAYS", 1);' \
    '}' \
    '' \
    '// MEDIA SETTINGS' \
    'if (!defined("IMAGE_EDIT_OVERWRITE")) {' \
    '    define("IMAGE_EDIT_OVERWRITE", true);' \
    '}' \
    '' \
    '// DISABLE HEARTBEAT (reduces AJAX calls)' \
    'if (!defined("WP_DISABLE_HEARTBEAT")) {' \
    '    define("WP_DISABLE_HEARTBEAT", true);' \
    '}' \
    '' \
    '// DISABLE SCRIPT CONCATENATION (better for CDN)' \
    'if (!defined("CONCATENATE_SCRIPTS")) {' \
    '    define("CONCATENATE_SCRIPTS", false);' \
    '}' \
    '?>' \
    > /var/www/html/wp-config-private.php

# ============================================
# STAGE 5: APACHE CONFIGURATION
# ============================================

# Apache performance optimizations
RUN printf '%s\n' \
    '# Apache Performance Settings' \
    'Timeout 30' \
    'KeepAlive On' \
    'MaxKeepAliveRequests 100' \
    'KeepAliveTimeout 5' \
    '' \
    '<IfModule mpm_prefork_module>' \
    '    StartServers 5' \
    '    MinSpareServers 5' \
    '    MaxSpareServers 10' \
    '    MaxRequestWorkers 150' \
    '    MaxConnectionsPerChild 10000' \
    '</IfModule>' \
    '' \
    '# Enable compression' \
    '<IfModule mod_deflate.c>' \
    '    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/json' \
    '    BrowserMatch ^Mozilla/4 gzip-only-text/html' \
    '    BrowserMatch ^Mozilla/4\.0[678] no-gzip' \
    '    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html' \
    '</IfModule>' \
    '' \
    '# Enable caching' \
    '<IfModule mod_expires.c>' \
    '    ExpiresActive On' \
    '    ExpiresByType image/jpg "access plus 1 year"' \
    '    ExpiresByType image/jpeg "access plus 1 year"' \
    '    ExpiresByType image/gif "access plus 1 year"' \
    '    ExpiresByType image/png "access plus 1 year"' \
    '    ExpiresByType text/css "access plus 1 month"' \
    '    ExpiresByType application/pdf "access plus 1 month"' \
    '    ExpiresByType text/javascript "access plus 1 month"' \
    '    ExpiresByType application/javascript "access plus 1 month"' \
    '    ExpiresByType application/x-javascript "access plus 1 month"' \
    '    ExpiresByType application/x-shockwave-flash "access plus 1 month"' \
    '    ExpiresByType image/x-icon "access plus 1 year"' \
    '    ExpiresDefault "access plus 2 days"' \
    '</IfModule>' \
    > /etc/apache2/conf-available/performance.conf && \
    a2enconf performance.conf

# ============================================
# STAGE 6: ENTRYPOINT & HEALTHCHECK
# ============================================

# Create a custom entrypoint wrapper that includes our configs
RUN printf '%s\n' \
    '#!/bin/bash' \
    'set -e' \
    '' \
    '# Create debug log file with proper permissions' \
    'touch /var/www/html/wp-content/debug.log' \
    'chown www-data:www-data /var/www/html/wp-content/debug.log' \
    'chmod 644 /var/www/html/wp-content/debug.log' \
    '' \
    '# Include private subnet configuration' \
    'if [ -f /var/www/html/wp-config.php ] && [ -f /var/www/html/wp-config-private.php ]; then' \
    '    if ! grep -q "wp-config-private.php" /var/www/html/wp-config.php; then' \
    '        sed -i '\''1a // Private subnet configuration\\nrequire_once(ABSPATH . "wp-config-private.php");'\'' /var/www/html/wp-config.php' \
    '    fi' \
    'fi' \
    '' \
    '# Include reverse proxy config in wp-config.php if it exists' \
    'if [ -f /var/www/html/wp-config.php ] && [ -f /var/www/html/wp-config-reverse-proxy.php ]; then' \
    '    if ! grep -q "wp-config-reverse-proxy.php" /var/www/html/wp-config.php; then' \
    '        sed -i '\''2a // Reverse proxy configuration\\nrequire_once(ABSPATH . "wp-config-reverse-proxy.php");'\'' /var/www/html/wp-config.php' \
    '    fi' \
    'fi' \
    '' \
    '# Start Redis if installed (for object caching)' \
    'if command -v redis-server >/dev/null 2>&1; then' \
    '    echo "Starting Redis server..."' \
    '    redis-server --daemonize yes --maxmemory 256mb --maxmemory-policy allkeys-lru' \
    'fi' \
    '' \
    '# Call the original entrypoint' \
    'exec docker-entrypoint.sh "$@"' \
    > /usr/local/bin/custom-entrypoint.sh && \
    chmod +x /usr/local/bin/custom-entrypoint.sh

# Add healthcheck endpoint
RUN echo '<?php \
    header("Content-Type: application/json"); \
    http_response_code(200); \
    echo json_encode(["status" => "ok", "timestamp" => time()]); \
?>' > /var/www/html/health.php

# Create a performance test endpoint
RUN echo '<?php \
    $start = microtime(true); \
    $memory_start = memory_get_usage(); \
    \
    // Test database connection \
    global $wpdb; \
    $db_status = $wpdb ? "connected" : "disconnected"; \
    \
    // Test Redis if available \
    $redis_status = "not_available"; \
    if (class_exists("Redis")) { \
        try { \
            $redis = new Redis(); \
            if ($redis->connect("127.0.0.1", 6379, 1)) { \
                $redis_status = "connected"; \
                $redis->close(); \
            } \
        } catch (Exception $e) { \
            $redis_status = "error"; \
        } \
    } \
    \
    $memory_end = memory_get_usage(); \
    $time_end = microtime(true); \
    \
    header("Content-Type: application/json"); \
    echo json_encode([ \
        "status" => "ok", \
        "response_time_ms" => round(($time_end - $start) * 1000, 2), \
        "memory_used_kb" => round(($memory_end - $memory_start) / 1024, 2), \
        "database" => $db_status, \
        "redis" => $redis_status, \
        "opcache_enabled" => ini_get("opcache.enable"), \
        "php_version" => phpversion(), \
        "timestamp" => time() \
    ]); \
?>' > /var/www/html/performance-test.php

EXPOSE 80

# Healthcheck: internal probe, container checks itself
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fS --max-time 5 http://localhost/health.php || exit 1

# ============================================
# STAGE 7: FINAL CLEANUP
# ============================================
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["apache2-foreground"]