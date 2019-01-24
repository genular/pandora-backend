<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 11:55:08
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-04-04 18:01:12
 */
return [
	'settings' => [
		'displayErrorDetails' => true, // set to false in production
		'addContentLengthHeader' => false, // Allow the web server to send the content-length header
		// Renderer settings
		'renderer' => [
			'template_path' => __DIR__ . '/../../templates/',
		],
		// Monolog settings
		'logger' => [
			'name' => 'simon-backend',
			'path' => isset($_ENV['docker']) ? 'php://stdout' : __DIR__ . '/../logs/simon.log',
			'level' => \Monolog\Logger::DEBUG,
		],
		'timezone' => "Europe/London",
	],
];
