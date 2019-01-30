<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:21
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-29 17:02:01
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

$app->get('/backend/dataset/3rdparty/list/openml', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = [];

	$fileSystem = $this->get('SIMON\System\FileSystem');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$page = (int) $request->getQueryParam('page', 1);
	$limit = (int) $request->getQueryParam('limit', 5);
	$offset = $page * $limit;

	$HTTPClient = $this->get('GuzzleHttp\Client');
	$RequestOptions = $this->get('GuzzleHttp\RequestOptions');

	$requestResults = $HTTPClient->request('GET', "https://www.openml.org/api/v1/json/data/list/limit/" . $limit . "/offset/" . $offset . "",
		['verify' => false,
			'connect_timeout' => 1200,
			'timeout' => 1200,
			'debug' => false,
			'headers' =>
			[
				'Accept' => "application/json",
				'User-Agent' => "test",
			],
		]);

	if ($requestResults->getStatusCode() === 200) {
		$dataResponse = json_decode($requestResults->getBody()->getContents(), true);
		$dataResponse = $dataResponse["data"]["dataset"];
		$allQualityMesurments = [];

		foreach ($dataResponse as $dataResponseKey => $dataResponseValue) {

			$requestDetailsResults = $HTTPClient->request('GET', "https://www.openml.org/api/v1/json/data/" . $dataResponseValue["did"],
				['verify' => false, 'connect_timeout' => 30, 'timeout' => 30, 'debug' => false, 'headers' => ['Accept' => "application/json", 'User-Agent' => "test"]]
			);
			// list dataset only if dataset details are provided
			if ($requestDetailsResults->getStatusCode() === 200) {
				$detailsResponse = json_decode($requestDetailsResults->getBody()->getContents(), true);
				$detailsResponse = $detailsResponse["data_set_description"];

				$dataResponse[$dataResponseKey]["description"] = $detailsResponse["description"];
				$dataResponse[$dataResponseKey]["url"] = $detailsResponse["url"];
				$dataResponse[$dataResponseKey]["file_id"] = $detailsResponse["file_id"];
				$dataResponse[$dataResponseKey]["tag"] = implode(", ", $detailsResponse["tag"]);

				if (isset($dataResponseValue["quality"])) {
					foreach ($dataResponseValue["quality"] as $qualityItem) {
						if (!isset($allQualityMesurments[$qualityItem["name"]])) {
							$allQualityMesurments[$qualityItem["name"]] = true;
						}
					}
				}
			} else {
				unset($dataResponse[$dataResponseKey]);
			}

		}
		$message = ["dataset" => $dataResponse, "qualityMesurments" => $allQualityMesurments];
		$success = true;
	}

	return $response->withJson(["success" => $success, "message" => $message]);

});
