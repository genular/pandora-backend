<?php

/**
 * @Author: LogIN-
 * @Date:   2019-01-22 10:16:35
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-24 09:22:32
 */

if (PHP_SAPI == 'cli-server') {
	// To help the built-in PHP dev server, check if the request was actually for
	// something which should probably be served as a static file
	$url = parse_url($_SERVER['REQUEST_URI']);
	$file = __DIR__ . $url['path'];
	if (is_file($file)) {
		return false;
	}
}
require __DIR__ . '/../vendor/autoload.php';

// Bootstrap the app environment.
chdir(dirname(__DIR__));

// Turn on debug.
error_reporting(E_ALL);
ini_set('display_errors', 'On');

// Start the session.
session_cache_limiter(false);
session_start();

// Instantiate the app
$settings = require 'source/config/settings.php';

/** Check if application is called from command line
 *	and add command line support should be called like this:
 *  php simon-backend/server/backend/public/index.php backend/system/status/bb5dc8842ca31d4603d6aa11448d1654
 *  php public/index.php backend/system/cron
 */
if (PHP_SAPI == 'cli') {
	$argv = $GLOBALS['argv'];
	array_shift($argv);

	$pathInfo = implode('/', $argv);
	$env = \Slim\Http\Environment::mock(['REQUEST_METHOD' => 'GET', 'REQUEST_URI' => '/' . $pathInfo]);
	$settings['environment'] = $env;
}

// Using a different container
// http://discourse.slimframework.com/t/using-a-different-container/1029
// https://akrabat.com/replacing-pimple-in-a-slim-3-application/
$container = new \League\Container\Container;
$container->delegate(new \Slim\Container($settings));

// Required to enable auto wiring.
// https://jenssegers.com/73/dependency-injection-with-league-s-new-container
$container->delegate(
	new \League\Container\ReflectionContainer
);

$app = new \Slim\App($container);
// Register routes
require 'source/routes/main.php';

// Set up dependencies
require 'source/dependencies/main.php';

// Register middleware
require 'source/middlewares/main.php';

// Run app
$app->run();
