<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:28:25
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-05 15:26:00
 */
use Slim\Http\Request;
use Slim\Http\Response;

$app->add(function (Request $request, Response $response, $next) use ($container) {
	$config = $container->get('Noodlehaus\Config');

	$headers = [
		'Access-Control-Allow-Origin' => $config->get('default.frontend.server.url'),
		'Access-Control-Allow-Credentials' => 'true',
		'Access-Control-Max-Age' => '60',
		'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD',
		'Access-Control-Allow-Headers' => 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Origin,Accept,X-Token',
	];

	if (!$request->isOptions()) {
		// this continues the normal flow of the app, and will return the proper body
		$results = $next($request, $response);
		foreach ($headers as $key => $value) {
			$results = $results->withHeader($key, $value);
		}
		return $results;
	} else {
		//stops the app, and sends the response
		$results = $response;
		foreach ($headers as $key => $value) {
			$results = $results->withHeader($key, $value);
		}
		return $results;
	}
});