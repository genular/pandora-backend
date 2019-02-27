<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:21
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-02-13 09:28:08
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
	$limit = isset($submitData['limit']) ? (int) $submitData['limit'] : 5;
	$sort_by = isset($submitData['sort_by']) ? $submitData['sort_by'] : 'id';
	$sort = isset($submitData['sort']) ? $submitData['sort'] : '+';

	// Full text search string
	$custom = isset($submitData['custom']) ? $submitData['custom'] : "";

	if ($submitData && isset($submitData['page'])) {
		$PublicDatabases = $this->get('SIMON\PublicDatabases\PublicDatabases');
		list($paginatedData, $countData) = $PublicDatabases->getList($user_id, $page, $limit, $sort_by, $sort, $custom);

		// Lets just convert CSV from example field to associative array
		foreach ($paginatedData as $paginatedDataKey => $paginatedDataValue) {
			$csv = array();

			if (isset($paginatedDataValue["example"]) && $paginatedDataValue["example"] !== "") {
				$rows = array_map("str_getcsv", explode("\n", rtrim($paginatedDataValue["example"], "\n")));

				if (is_array($rows)) {
					$header = array_shift($rows);
					if (count($header) < 100) {
						foreach ($rows as $row) {
							$csv[] = array_combine($header, $row);
						}
					}
				}
			}
			$paginatedData[$paginatedDataKey]["example"] = $csv;
		}
		$message["itemsList"] = $paginatedData;
		$message["itemsTotal"] = $countData;
		$success = true;
	}

	return $response->withJson(["success" => $success, "message" => $message]);
});

$app->get('/backend/dataset/import/public/import/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = [];

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = false;

	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	$datasetIDs = isset($submitData['datasetIDs']) ? $submitData['datasetIDs'] : [];

	if ($datasetIDs && count($datasetIDs) > 0) {

		$PublicDatabases = $this->get('SIMON\PublicDatabases\PublicDatabases');
		$Helpers = $this->get('SIMON\Helpers\Helpers');
		$FileSystem = $this->get('SIMON\System\FileSystem');

		foreach ($datasetIDs as $datasetIDsKey => $datasetID) {
			$message[$datasetIDsKey] = [
				"datasetID" => $datasetID,
				"status" => true,
			];
			// Check if user can import specific file

			// Download file from the storage && Extract file from GZ format
			$initial_path = $PublicDatabases->downloadInternalDataset($datasetID);

			if ($initial_path === false) {
				$message[$datasetIDsKey]["status"] = false;
				continue;
			}
			// Validate File Header and rename it t standardize column names!
			$details = $Helpers->validateCSVFileHeader($initial_path);
			// Compress original file tot GZ
			list($renamed_path, $gzipped_path) = $Helpers->compressPath($initial_path);
			// Upload compressed file to the S3 Storage
			$remote_path = $FileSystem->uploadFile($user_id, $gzipped_path, "uploads");
			// Save reference to Database
			$file_id = $FileSystem->insertFileToDatabase($user_id, $details, $initial_path, $renamed_path, $remote_path, "uploads");
			// Delete and cleanup local files
			if (file_exists($initial_path)) {
				@unlink($initial_path);
			}
			if (file_exists($renamed_path)) {
				@unlink($renamed_path);
			}
			if (file_exists($gzipped_path)) {
				@unlink($gzipped_path);
			}
		}
	}

	if (count($message) > 0) {
		$success = true;
	}

	return $response->withJson(["success" => $success, "message" => $message]);
});
