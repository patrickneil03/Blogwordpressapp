<?php
// ============================================
// DOCKER CONFIGURATION FOR PRIVATE SUBNET
// ============================================

define("WP_HTTP_BLOCK_EXTERNAL", true);

define("AUTOMATIC_UPDATER_DISABLED", true);
define("WP_AUTO_UPDATE_CORE", false);

define("DISABLE_WP_CRON", true);

if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] == "https") {
    $_SERVER["HTTPS"] = "on";
    $_SERVER["SERVER_PORT"] = 443;
}
if (isset($_SERVER["HTTP_X_FORWARDED_HOST"])) {
    $_SERVER["HTTP_HOST"] = $_SERVER["HTTP_X_FORWARDED_HOST"];
}

if (!defined("FORCE_SSL_ADMIN")) {
    define("FORCE_SSL_ADMIN", false);
}

// 🔐 DYNAMIC COUPLING: Read variables injected by ECS Fargate Task Definition
$wp_domain = getenv('WORDPRESS_DOMAIN') ?: 'blog.baylenwebsite.xyz';
$wp_home   = getenv('WP_HOME') ?: 'https://' . $wp_domain;
$wp_siteurl = getenv('WP_SITEURL') ?: 'https://' . $wp_domain;

if (!defined("COOKIE_DOMAIN")) {
    define("COOKIE_DOMAIN", $wp_domain);
}
if (!defined("WP_HOME")) {
    define("WP_HOME", $wp_home);
}
if (!defined("WP_SITEURL")) {
    define("WP_SITEURL", $wp_siteurl);
}