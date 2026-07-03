<?php
/**
 * Plugin Name: Load Balancer Compatibility
 * Description: Respect ALB and CloudFront headers
 * Version: 1.4
 */

if (isset($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] === "https") {
    $_SERVER["HTTPS"] = "on";
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

if (!defined("CONCATENATE_SCRIPTS")) {
    define("CONCATENATE_SCRIPTS", false);
}