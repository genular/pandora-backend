<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 11:55:02
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:14:48
 */

require 'source/routes/users/main.php';
require 'source/routes/users/dashboard.php';

require 'source/routes/system/main.php';
require 'source/routes/system/validation.php';
require 'source/routes/system/filesystem.php';
require 'source/routes/system/simon.php';

require 'source/routes/organization/main.php';
require 'source/routes/models/main.php';
require 'source/routes/models/variableImportance.php';
require 'source/routes/dataset/main.php';

$app->options('/{routes:.+}', function ($request, $response, $args) {
	return $response;
});

// $app->add(function ($req, $res, $next) {
// 	$response = $next($req, $res);
// 	return $response
// 		->withHeader('Access-Control-Allow-Origin', '*')
// 		->withHeader('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type, Accept, Origin, Authorization')
// 		->withHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
// });

// Catch-all route to serve a 404 Not Found page if none of the routes match
// NOTE: make sure this route is defined last
// $app->map(['GET', 'POST', 'PUT', 'DELETE', 'PATCH'], '/{routes:.+}', function ($req, $res) {
// 	$handler = $this->notFoundHandler; // handle using the default Slim page not found handler
// 	return $handler($req, $res);
// });
