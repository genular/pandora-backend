<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:10
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-05 13:37:10
 */

use Slim\Http\Request;
use Slim\Http\Response;
/**
 * Index page
 */
$app->get('/', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("SIMON '/' route");
	// Render index view
	return $this->get('Slim\Views\PhpRenderer')->render($response, 'index.phtml', $args);
});

$app->get('/backend/system/status/{secret:.*}', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("SIMON '/system/status/{secret:.*}' route");

	$status = 301;
	$success = false;

	$system = $this->get('SIMON\System\System');
	$config = $this->get('Noodlehaus\Config');

	$configData = $config->all();
	$server_details = [];

	foreach ($configData["default"] as $configItemKey => $configItemValue) {
		$server_name = $configItemKey;
		if (is_array($configItemValue) && isset($configItemValue["server"])) {
			if (isset($configItemValue["server"]["url"])) {
				$server_details[] = [
					"type" => $server_name,
					"url" => $configItemValue["server"]["url"],
				];
			}
		}
	}
	if (count($server_details) > 2) {
		$success = true;
	}

	return $response->withJson(["success" => $success, "servers" => $server_details]);
});

/**
 * Initialize system with default values
 */
$app->get('/init/{secret:.*}', function (Request $request, Response $response, array $args) {
	$status = 301;
	$success = false;

	$config = $this->get('Noodlehaus\Config');
	$systemSecret = $config->get('default.secret');

	$requestSecret = $args['secret'];
	if (strcmp($systemSecret, $requestSecret) == 0) {
		$system = $this->get('SIMON\System\System');
		$system->init();
		// $system->scrapeHelpDocumentation();
		$status = 200;
		$success = true;
	}

	$response->getBody()->write(json_encode(["success" => $success]));
	return $response->withStatus($status);
});

/**
 * Delete default values
 */
$app->get('/reset/{secret:.*}', function (Request $request, Response $response, array $args) {
	$status = 301;
	$success = false;
	$config = $this->get('Noodlehaus\Config');
	$systemSecret = $config->get('default.secret');

	$userSecret = $args['secret'];
	if (strcmp($systemSecret, $userSecret) == 0) {
		$system = $this->get('SIMON\System\System');
		$system->reset();
		$status = 200;
		$success = true;
	}

	$response->getBody()->write(json_encode(["success" => $success]));
	return $response->withStatus($status);
});