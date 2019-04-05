<?php

/**
 * @Author: LogIN-
 * @Date:   2018-06-08 15:11:00
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-04-05 15:07:18
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
			if ($file['error'] !== 0) {
				$message[] = 'file_error_' . $file['error'];
				$this->get('Monolog\Logger')->info("SIMON '/backend/system/filesystem/upload' file_error " . json_encode($file));
				continue;
			}
			if (!$file['tmp_name']) {
				$message[] = 'file_error_tmp';
				$this->get('Monolog\Logger')->info("SIMON '/backend/system/filesystem/upload' file_error_tmp " . json_encode($file));
				continue;
			}
			$uploaded_path = $file['tmp_name'];
			$filename = (isset($file['filename'])) ? $file['filename'] : $file['name'];
			// Check if chunk upload
			if (isset($post['dzuuid'])) {
				$chunks_res = $ResumableUpload->resumableUpload($uploaded_path, $filename, $post);
				if ($chunks_res['final'] === true) {
					// Last chunk uploaded and file constructed
					$success = true;
					$uploaded_path = $chunks_res['path'];
					$message[] = 'upload_success_chunks';
				}
			} else {
				// File is not chunk is complete file
				$uploaded_path = $ResumableUpload->moveUploadedFile($uploaded_path, $filename);
				if ($uploaded_path !== false) {
					$success = true;
					$message[] = 'upload_success_whole';
				}
			}
		}
	}

	// File upload is finished!
	if ($success === true) {
		// Validate File Header and rename it to standardize column names!
		$details = $Helpers->validateCSVFileHeader($uploaded_path);

		if (count($details["message"]) === 0) {

			$renamed_path = $Helpers->renamePathToHash($details);
			// Compress original file to GZ archive format
			$gzipped_path = $Helpers->compressPath($renamed_path);
			// Upload compressed file to the Storage
			$remote_path = $FileSystem->uploadFile($user_id, $gzipped_path, "uploads");
			// Save reference to Database
			$file_id = $FileSystem->insertFileToDatabase($user_id, $details, $remote_path);

			// Delete and cleanup local files
			if (file_exists($uploaded_path)) {
				@unlink($uploaded_path);
			}
			if (file_exists($renamed_path)) {
				@unlink($renamed_path);
			}
			if (file_exists($gzipped_path)) {
				@unlink($gzipped_path);
			}

			$file_details = $FileSystem->getFileDetails($file_id, ["id", "size", "display_filename", "extension", "mime_type", "item_type"], true);
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
		} else {
			$success = false;
			$message = $details["message"];
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

	$data = $FileSystem->getAllFilesByUserID($user_id, "uploads", false);

	return $response->withJson(["success" => $success, "message" => $data]);

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
			$file_details = $FileSystem->getFileDetails($fileID, ["uid", "file_path"], false);

			if ($file_details !== false && $user_id == $file_details["uid"]) {
				$message = $FileSystem->deleteFileByID($fileID, $file_details["file_path"]);
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
	$Helpers = $this->get('SIMON\Helpers\Helpers');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = false;
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	if ($submitData && isset($submitData['recordID'])) {
		// This is array for models or integer for queue and resample
		$recordID = $submitData['recordID'];
		$downloadType = $submitData['downloadType'];

		$recordDetails = false;
		if ($downloadType === "queue") {
			$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');
			$recordDetails = $DatasetQueue->getDetailsByID($recordID, $user_id);
		} else if ($downloadType === "resample") {
			$DatasetResamples = $this->get('SIMON\Dataset\DatasetResamples');
			$recordDetails = $DatasetResamples->getDetailsByID($recordID, $user_id);
		} else if ($downloadType === "models") {
			$Models = $this->get('SIMON\Models\Models');
			$recordDetails = $Models->getDetailsByID($recordID, $user_id);

		}
		// 1st fetch all necessarily file IDs from database
		$downloadIDs = [];
		if ($recordDetails) {
			// Loop all values and search for fileIDs
			foreach ($recordDetails as $recordDetailsKey => $recordDetailsValue) {
				if (!is_array($recordDetailsValue)) {
					// Process only keys that start with ufid: ex. ufid_train
					if ($Helpers->startsWith($recordDetailsKey, 'ufid')) {
						if (!isset($downloadIDs[$recordDetailsValue])) {
							$downloadIDs[$recordDetailsValue] = $recordDetailsValue;
						}
					}
				} else {
					foreach ($recordDetailsValue as $recordDetailsValueKey => $recordValue) {
						if ($Helpers->startsWith($recordDetailsValueKey, 'ufid')) {
							if (!isset($downloadIDs[$recordValue])) {
								$downloadIDs[$recordValue] = $recordValue;
							}
						}
					}
				}
			}
		}

		// 2nd Generate final download links
		$downloadLinks = [];
		foreach ($downloadIDs as $fileID) {
			$fileDetails = $FileSystem->getFileDetails($fileID, ["file_path", "display_filename", "extension"], false);

			if (isset($fileDetails['file_path'])) {
				$display_filename = $FileSystem->getDisplayFilename($fileDetails['display_filename'], $fileDetails['extension']);
				// get link with a new name
				$download_url = $FileSystem->getDownloadLink($fileDetails['file_path'], $display_filename);
				$downloadLinks[] = ["filename" => $display_filename, "download_url" => $download_url];
			}
		}
		// TODO 3rd if model download is requested also download variable_importance and model overview sheet
		// if ($downloadType === "models") {
		// }

		if (count($downloadLinks) > 0) {
			$message = $downloadLinks;
			$success = true;
		}
	}

	return $response->withJson(["success" => $success, "message" => $message]);

});
