<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 11:55:08
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-07 12:51:20
 */
function is_connected() {
	$connected = @fsockopen("www.google.com", 80);
	if ($connected) {
		$is_conn = true; //action when connected
		fclose($connected);
	} else {
		$is_conn = false; //action in connection failure
	}
	return $is_conn;
}
return [
	'settings' => [
		// Check for Docker ENV variable
		'is_docker' => getenv('IS_DOCKER') ? getenv('IS_DOCKER') : false,
		// Do we have Internet connection
		'is_connected' => false, // is_connected(),
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
