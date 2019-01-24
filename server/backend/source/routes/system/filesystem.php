<?php

/**
 * @Author: LogIN-
 * @Date:   2018-06-08 15:11:00
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-24 12:17:19
 */

use Slim\Http\Request;
use Slim\Http\Response;

$app->post('/backend/system/filesystem/upload', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = array();

	$FileSystem = $this->get('SIMON\System\FileSystem');
	$ResumableUpload = $this->get('SIMON\System\ResumableUpload');
	$Helpers = $this->get('SIMON\Helpers\Helpers');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	$uploadedFiles = $request->getUploadedFiles();

	if (!empty($_FILES)) {
		foreach ($_FILES as $file) {
			if ($file['error'] != 0) {
				$message[] = 'File error';
				continue;
			}
			if (!$file['tmp_name']) {
				$message[] = 'Tmp file not found';
				continue;
			}
			$initial_path = $file['tmp_name'];
			$filename = (isset($file['filename'])) ? $file['filename'] : $file['name'];
			// Check if chunk upload
			if (isset($post['dzuuid'])) {
				$chunks_res = $ResumableUpload->resumableUpload($initial_path, $filename, $post);
				if ($chunks_res['final'] === true) {
					// Last chunk uploaded and file constructed
					$success = true;
					$initial_path = $chunks_res['path'];
				}
			} else {
				// File is not chunk is complete file
				$initial_path = $ResumableUpload->moveUploadedFile($initial_path, $filename);
				if ($initial_path !== false) {
					$success = true;
				}
			}
		}
	}
	// File upload is finished!
	if ($success === true) {
		// Validate File Header and rename it t standardize column names!
		$details = $Helpers->validateCSVFileHeader($initial_path);

		list($renamed_path, $gzipped_path) = $Helpers->compressPath($initial_path);

		// 1. Upload to cloud
		$remote_path = $FileSystem->uploadFile($user_id, $gzipped_path, "uploads");

		if (file_exists($gzipped_path)) {
			@unlink($gzipped_path);
		}
		// 2. Save reference to Database
		$file_id = $FileSystem->insertFileToDatabase($user_id, $details, $initial_path, $renamed_path, $remote_path, "uploads");

		// 3. Delete local file
		if (file_exists($initial_path)) {
			@unlink($initial_path);
		}

		if (file_exists($renamed_path)) {
			@unlink($renamed_path);
		}

		$file_details = $FileSystem->getFileDetails($file_id, false);
		if ($file_details !== false) {
			$message = array(
				"id" => $file_details["id"],
				"size" => $file_details["size"],
				"display_filename" => $file_details["display_filename"],
				"extension" => $file_details["extension"],
				"mime_type" => $file_details["mime_type"],
				"item_type" => $file_details["item_type"],
			);
		}

	}

	return $response->withJson(["success" => $success, "message" => $message]);

});

$app->post('/backend/system/filesystem/list', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$Config = $this->get('Noodlehaus\Config');
	$FileSystem = $this->get('SIMON\System\FileSystem');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	if (isset($post['selectedDirectory'])) {
		$selectedDirectory = urldecode(base64_decode($post['selectedDirectory']));
	} else {
		$selectedDirectory = urldecode(base64_decode($post['selectedDirectory']));
	}

	$details = $FileSystem->getAllFilesByUserID($user_id, "uploads", false);

	return $response->withJson(["success" => $success, "message" => $details]);

});

$app->get('/backend/system/filesystem/delete/{file_id:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$FileSystem = $this->get('SIMON\System\FileSystem');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$file_id = intval($args['file_id']);
	$file_details = $FileSystem->getFileDetails($file_id, false);

	if ($file_details !== false && $user_id == $file_details["uid"]) {
		$message = $FileSystem->deleteFileByID($file_id, $file_details["path_remote"]);
		if ($message === false) {
			$success = false;
		}
	} else {
		$success = false;
	}

	return $response->withJson(["success" => $success, "message" => $message]);

});

$app->get('/backend/system/filesystem/download/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$FileSystem = $this->get('SIMON\System\FileSystem');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = [];
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	$file_id = intval($submitData['fileID']);
	$file_details = $FileSystem->getFileDetails($file_id, false);

	$headerFormatted = array_values($file_details["details"]["header"]["formatted"]);

	$url = $FileSystem->getPreSignedURL($file_details['path_remote'], 'genular');

	return $response->withJson(["success" => $success, "message" => ["url" => $url, "header" => $headerFormatted]]);

});
