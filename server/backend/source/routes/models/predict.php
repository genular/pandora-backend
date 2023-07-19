<?php

/**
 * @Author: LogIN-
 * @Date:   2019-01-29 13:45:30
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-29 13:53:25
 */

use Slim\Http\Request;
use Slim\Http\Response;

$app->get('/backend/models/predict', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("PANDORA '/backend/models/predict' route");

	// Render index view
	return $this->get('Slim\Views\PhpRenderer')->render($response, 'predict/submit.phtml', $args);
});

