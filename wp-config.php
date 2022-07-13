<?php 

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

define('DB_DIR', ABSPATH . 'wp-content/database');
define('DB_FILE', getenv('DB_FILE') ?: 'db');

$table_prefix  = 'wp_';

/**
 * If we're behind a proxy server and using HTTPS, we need to alert WordPress of that fact
 * see also https://wordpress.org/support/article/administration-over-ssl/#using-a-reverse-proxy
 */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https') {
    $_SERVER['HTTPS'] = 'on';
}
if (isset($_SERVER['HTTP_X_FORWARDED_HOST'])) {
    $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';