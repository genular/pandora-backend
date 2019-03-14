<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 11:55:08
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-13 17:21:35
 */

use \SIMON\Helpers\Helpers as Helpers;

return [
	'settings' => [
		// Check for Docker ENV variable
		'is_docker' => getenv('IS_DOCKER') ? true : false,
		// Do we have Internet connection
		'is_connected' => Helpers::is_connected(),
		'displayErrorDetails' => true, // set to false in production
		'addContentLengthHeader' => false, // Allow the web server to send the content-length header
		// Renderer settings
		'renderer' => [
			'template_path' => __DIR__ . '/../../templates/',
		],
		// Monolog settings
		'logger' => [
			'name' => 'simon-backend',
			'path' => getenv('IS_DOCKER') ? 'php://stdout' : __DIR__ . '/../logs/simon.log',
			'level' => \Monolog\Logger::DEBUG,
		],
		'timezone' => date_default_timezone_get(),
	],
];
