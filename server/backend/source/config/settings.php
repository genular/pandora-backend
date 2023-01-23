<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 11:55:08
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-04-05 16:59:10
 */

use \PANDORA\Helpers\Helpers as Helpers;

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
			'name' => 'pandora-backend',
			'path' => __DIR__ . '/../logs/pandora.log',
			'level' => \Monolog\Logger::DEBUG,
		],
		'timezone' => getenv('TZ') ? getenv('TZ') : date_default_timezone_get(),
	],
];
