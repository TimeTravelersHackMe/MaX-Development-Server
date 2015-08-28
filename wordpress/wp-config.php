<?php

/* ***************************************** */
/*     SECURITY CREDENTIALS AND SETTINGS     */
/* ***************************************** */
	

/* Database connection settings */
define( 'DB_NAME', '{DATABASE_NAME}' );
define( 'DB_USER', '{DATABASE_USER}' );
define( 'DB_PASSWORD', '{DATABASE_PASSWORD}' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

/* Custom database format */
$table_prefix = '{DATABASE_PREFIX}_';
//define( 'CUSTOM_USER_TABLE', $table_prefix . 'CUSTOM_USER_TABLE_HANDLE' );
//define( 'CUSTOM_USER_META_TABLE', $table_prefix . 'CUSTOM_USER_META_TABLE_HANDLE' );

/* SSL (HTTPS) settings */
//define( 'FORCE_SSL_LOGIN', TRUE );
//define( 'FORCE_SSL_ADMIN', TRUE );

/* Authentication keys and salts */
// Key generator tool: https://api.wordpress.org/secret-key/1.1/salt/
{AUTH-KEYS-SALTS}

/* Security tweaks */
// Experiment with this for security purposes
define( 'DISALLOW_FILE_MODS', FALSE );
// Disallow unfiltered_html for all users
define( 'DISALLOW_UNFILTERED_HTML', FALSE );
// Allow uploads of filtered file types to admins
define( 'ALLOW_UNFILTERED_UPLOADS', TRUE );
// Do not block internet requests
define( 'WP_HTTP_BLOCK_EXTERNAL', FALSE );
// Whitelist hosts for when WP_HTTP_BLOCK_EXTERNAL is true
//define( 'WP_ACCESSIBLE_HOSTS', 'api.wordpress.org');


/* ***************************************** */
/* LANGUAGE AND DIRECTORY STRUCTURE SETTINGS */
/* ***************************************** */


/* Localized language */
// U.S. English (en_US) by default
define( 'WPLANG', '' );
//define( 'WP_LANG_DIR', dirname(__FILE__) . '/languages');

/* Theme settings */
define('WP_DEFAULT_THEME', 'sage' );
//define('TEMPLATEPATH', '/absolute/path/to/wp-content/themes/active-theme');
//define('STYLESHEETPATH', '/absolute/path/to/wp-content/themes/active-theme');

/* Directory structure settings */
// Get SERVER_NAME from URL if the actual nginx server name is something else
if($_SERVER['SERVER_NAME'] = 'localhost') {define('SERVER_NAME', $_SERVER['HTTP_HOST']);} else {define('SERVER_NAME', $_SERVER['SERVER_NAME']);}
// Defines the site URL to minimize database transactions
define( 'WP_SITEURL', 'http://' . SERVER_NAME .'/wp');
// Defines home URL to minimize database transactions
define( 'WP_HOME', 'http://' . SERVER_NAME );
// Custom content directory
define( 'WP_CONTENT_DIR', dirname( __FILE__ ) . '/assets' );
define( 'WP_CONTENT_URL', 'http://' . SERVER_NAME . '/assets' );
// Custom plugin directory
define( 'WP_PLUGIN_DIR', dirname( __FILE__ ) . '/assets/addons' );
define( 'WP_PLUGIN_URL', 'http://' . SERVER_NAME . '/assets/addons' );
// For compatibility with older scripts
define( 'PLUGINDIR', WP_PLUGIN_DIR );
// Custom must-use plugin directory
define( 'WPMU_PLUGIN_DIR', dirname( __FILE__ ) . '/assets/includes' );
define( 'WPMU_PLUGIN_URL', 'http://' . SERVER_NAME . '/assets/includes' );
// Upload directory relative to WP install directory
define( 'UPLOADS', 'media' );


/* ***************************************** */
/* 		MULTISITE AND COOKIE SETTINGS 		 */
/* ***************************************** */
	

/* Multisite settings */
// Allow multisite
//define( 'WP_ALLOW_MULTISITE', TRUE );
// Network setup (FIDDLE WITH THIS FOR QUERY REDUCTION)
//define( 'MULTISITE', TRUE );
//define( 'SUBDOMAIN_INSTALL', TRUE );
//define('DOMAIN_CURRENT_SITE', '{WEBSITE_NAME}');
//define('PATH_CURRENT_SITE', '/');
//define('SITE_ID_CURRENT_SITE', 1);
//define('BLOG_ID_CURRENT_SITE', 1);

/* Cookie settings */
//define( 'ADMIN_COOKIE_PATH', '/' );
// Important for multisite without domain mapping plugin
//define( 'COOKIE_DOMAIN', '' );
//define( 'COOKIEPATH', '' );
//define( 'SITECOOKIEPATH', '' );


/* ***************************************** */
/*      CONTENT AND PERFORMANCE SETTINGS     */
/* ***************************************** */


/* Content settings */
// Disables post revisions
//define( 'WP_POST_REVISIONS', FALSE );
// Total revisions to keep per post
define( 'WP_POST_REVISIONS', 15 );
// Number of seconds inbetween autosaves
define( 'AUTOSAVE_INTERVAL', 120 );
// Enable trash for media
define( 'MEDIA_TRASH', TRUE );
// Empty trash every X days
define( 'EMPTY_TRASH_DAYS', 15 );

/* Memory settings */
define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );

/* Performance tweaks */
// Compression for JS and styles. We use PageSpeed so let's turn these off.
define( 'CONCATENATE_SCRIPTS', FALSE );
define( 'COMPRESS_SCRIPTS', FALSE );
define( 'COMPRESS_CSS', FALSE );
define( 'ENFORCE_GZIP', FALSE );


/* ***************************************** */
/*     FTP AND PROXY CONNECTION SETTINGS     */
/* ***************************************** */


/* Proxy settings */
//define( 'WP_PROXY_HOST', '10.28.123.4' );
//define( 'WP_PROXY_PORT', '8080' );
//define( 'WP_PROXY_USERNAME', 'username123' );
//define( 'WP_PROXY_PASSWORD', 'password123' );
//define( 'WP_PROXY_BYPASS_HOSTS', 'localhost' );

/* FTP settings */
//define( 'FTP_HOST', '' );
//define( 'FTP_USER', 'username123' );
//define( 'FTP_PASS', 'password123' );
//define( 'FTP_SSL', FALSE );


/* ***************************************** */
/*               DEBUG SETTINGS              */
/* ***************************************** */

// For Stage Switcher
$envs = array(
  'development' => 'http://{WEBSITE_NAME_MINUS_TLD}.dev',
  'staging'     => 'http://staging.{WEBSITE_NAME}',
  'production'  => 'http://{WEBSITE_NAME}'
);
define('ENVIRONMENTS', serialize($envs));

// Conflicts with WP-CLI
// Set to dev for developement settings and live for production settings
define('WP_ENV', 'development');
switch( WP_ENV ){
	// Development debug settings
	case 'development':
		define( 'WP_CACHE', FALSE );
		define( 'WP_DEBUG', TRUE );
		define( 'DISALLOW_FILE_EDIT', FALSE );
		define( 'SAVEQUERIES', TRUE );
		/* View queries in the footer of your theme with the following snippet:
			<?php
				if ( current_user_can( 'administrator' ) ) {
					global $wpdb;
					echo "<pre>";
					print_r( $wpdb->queries );
					echo "</pre>";
				}
			?>
		*/
		error_reporting(E_ALL | E_WARNING | E_ERROR);
		// display errors
		@ini_set('log_errors','On');
		@ini_set('display_errors','On');
		// Notes on this ini_set stuff: http://digwp.com/2009/07/monitor-php-errors-wordpress/
		@ini_set('error_log','/usr/local/nginx/html/{WEBSITE_NAME}/logs/wordpress_php_error.log');
		define( 'WP_DEBUG_LOG', TRUE );
		define( 'WP_DEBUG_DISPLAY', TRUE );
		define( 'SCRIPT_DEBUG', TRUE );
	break;
// Production debug settings
	case 'live':
		define( 'WP_CACHE', TRUE );
		define( 'WP_DEBUG', FALSE );
		define( 'DISALLOW_FILE_EDIT', TRUE );
		define( 'SAVEQUERIES', FALSE );
		error_reporting(E_WARNING | E_ERROR);
		// log errors in a file (content/debug.log), don't show them to end-users.
		@ini_set('log_errors','On');
		@ini_set('display_errors','Off');
		define( 'WP_DEBUG_LOG', TRUE );
		define( 'WP_DEBUG_DISPLAY', FALSE );
		define( 'SCRIPT_DEBUG', FALSE );
	break;
}


/* ***************************************** */
/*              UPDATE SETTINGS              */
/* ***************************************** */

// Skip content directory when upgrading to a new WordPress version
define( 'CORE_UPGRADE_SKIP_NEW_BUNDLED', TRUE );

/* Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) );

/* Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');