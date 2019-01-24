<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:06
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-10-08 10:39:19
 */
use Slim\Http\Request;
use Slim\Http\Response;

/**
 * Get simple user related statistics
 */
$app->get('/backend/dashboard/stats', function (Request $request, Response $response, array $args) {
	$status = 200;
	$success = false;
	$config = $this->get('Noodlehaus\Config');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$Models = $this->get('SIMON\Models\Models');
	$statistics = $Models->getStatistics($user_id);

	$data = array(
		'status' => 'success',
		'data' => $statistics,
	);

	return $response->withJson($data);
});
