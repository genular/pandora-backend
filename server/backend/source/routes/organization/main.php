<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:21
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-06 15:14:41
 */

use Slim\Http\Request;
use Slim\Http\Response;

$app->post('/backend/organization/', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$fileSystem = $this->get('SIMON\System\FileSystem');
	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	if (isset($post['selectedDirectory'])) {
		$selectedDirectory = urldecode(base64_decode($post['selectedDirectory']));
	} else {
		$selectedDirectory = urldecode(base64_decode($post['selectedDirectory']));
	}

	return $response->withJson(["success" => $success, "data" => $user_id]);

});
