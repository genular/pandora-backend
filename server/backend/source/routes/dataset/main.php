<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:21
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-31 15:24:07
 */

use Slim\Http\Request;
use Slim\Http\Response;

$app->post('/backend/dataset/', function (Request $request, Response $response, array $args) {
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

$app->get('/backend/dataset/import/public/list/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = [];

	$fileSystem = $this->get('SIMON\System\FileSystem');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = false;

	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	$page = isset($submitData['page']) ? (int) $submitData['page'] : 1;
	$limit = isset($submitData['limit']) ? (int) $submitData['limit'] : 10;
	$sort = isset($submitData['sort']) ? $submitData['sort'] : '+';

	$custom = isset($submitData['custom']) ? $submitData['custom'] : "";

	if ($submitData && isset($submitData['page'])) {
		$DatasetDatabase = $this->get('SIMON\Dataset\DatasetDatabase');
		list($paginatedData, $countData) = $DatasetDatabase->getList($user_id, $page, $limit, $sort, $custom);

		$message["itemsList"] = $paginatedData;
		$message["itemsTotal"] = $countData;
		$success = true;
	}

	return $response->withJson(["success" => $success, "message" => $message]);
});
