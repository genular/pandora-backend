<?php

/**
 * @Author: LogIN-
 * @Date:   2018-06-08 15:11:00
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-08 14:45:36
 */

use Slim\Http\Request;
use Slim\Http\Response;

/**
 * Multi part ajax file upload
 *
 * @param  {array} $_FILES
 *
 * @return {json} JSON encoded API response object
 */
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

/**
 * Retrieves list of files for the user, uploaded in specific user directory
 *
 * @param  {object} submitData Object containing one string variable: selectedDirectory that corresponds to upload_directory column in users_files table
 *
 * @return {json} JSON encoded API response object
 */
$app->get('/backend/system/filesystem/list/{fileID:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$Config = $this->get('Noodlehaus\Config');
	$FileSystem = $this->get('SIMON\System\FileSystem');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = false;
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	$selectedDirectory = "uploads";
	if ($submitData && isset($submitData['selectedDirectory'])) {
		$selectedDirectory = $submitData['selectedDirectory'];
	}

	$message = $FileSystem->getAllFilesByUserID($user_id, "uploads", false);

	return $response->withJson(["success" => $success, "message" => $message]);

});

/**
 * Deletes file from database and from file system
 *
 * @param  {int} fileID ID of the desired file to be deleted from users_files database table
 *
 * @return {json} JSON encoded API response object
 */
$app->get('/backend/system/filesystem/delete/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$FileSystem = $this->get('SIMON\System\FileSystem');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = false;
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	if (isset($submitData['selectedFiles'])) {
		foreach ($submitData['selectedFiles'] as $selectedFilesKey => $selectedFilesValue) {
			$fileID = (int) $selectedFilesValue;
			$file_details = $FileSystem->getFileDetails($fileID, false);

			if ($file_details["details"] && $user_id == $file_details["uid"]) {
				$message = $FileSystem->deleteFileByID($fileID, $file_details["path_remote"]);
				if ($message === false) {
					$success = false;
				}
			} else {
				$success = false;
			}
		}
	}

	return $response->withJson(["success" => $success, "message" => $message]);

});

/**
 * Generates download ZIP files and return full URL to download file
 *
 * @param  {string} submitData Is base 64 and json encoded javascript object containing two variables
 * downloadType: (resample, queue)
 * recordID: main ID of the queue or resample
 *
 * @return {json} JSON encoded API response object
 */
$app->get('/backend/system/filesystem/download/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = false;

	$FileSystem = $this->get('SIMON\System\FileSystem');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = false;
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	if ($submitData && isset($submitData['recordID'])) {
		$recordID = (int) $submitData['recordID'];
		$downloadType = $submitData['downloadType'];

		$recordDetails = false;
		if ($downloadType === "queue") {
			$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');
			$recordDetails = $DatasetQueue->getDetailsByID($recordID, $user_id);
		} else {
			$DatasetResamples = $this->get('SIMON\Dataset\DatasetResamples');
			$recordDetails = $DatasetResamples->getDetailsByID($recordID, $user_id);
		}

		$downloadIDs = [];
		if ($recordDetails) {
			// Loop all values and search for fileIDs
			foreach ($recordDetails as $recordDetailsKey => $recordDetailsValue) {
				if (strpos($recordDetailsKey, 'fileID') === 0) {
					if (!isset($downloadIDs[$recordDetailsValue])) {
						$downloadIDs[$recordDetailsValue] = $recordDetailsValue;
					}
				}
			}
		}

		$downloadLinks = [];
		foreach ($downloadIDs as $fileID) {
			$fileDetails = $FileSystem->getFileDetails($fileID, false);
			if (isset($fileDetails['path_remote'])) {
				$url = $FileSystem->getDownloadLink($fileDetails['path_remote']);
				$downloadLinks[] = $url;
			}
		}

		if (count($downloadLinks) > 0) {
			$message = $downloadLinks;
			$success = true;
		}
	}

	return $response->withJson(["success" => $success, "message" => $message]);

});
