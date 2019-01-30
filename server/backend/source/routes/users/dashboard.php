<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:06
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-28 09:41:16
 */
use Slim\Http\Request;
use Slim\Http\Response;

/**
 * Get simple user related statistics
 */
$app->get('/backend/dashboard/stats', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = array();

	$config = $this->get('Noodlehaus\Config');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$Models = $this->get('SIMON\Models\Models');
	$statistics = $Models->getStatistics($user_id);
	if ($statistics) {
		$message = $statistics;
		$success = true;
	}

	$data = array(
		'status' => $success,
		'message' => $message,
	);

	return $response->withJson($data);
});
