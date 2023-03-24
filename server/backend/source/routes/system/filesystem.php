<?php

/**
 * @Author: LogIN-
 * @Date:   2018-06-08 15:11:00
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2021-02-04 14:58:28
 */

use Slim\Http\Request;
use Slim\Http\Response;



/**
 * Retrieves list of files for the user, uploaded in specific user directory
 *
 * @param  {object} submitData Object containing one string variable: selectedDirectory that corresponds to upload_directory column in users_files table
 * @return {json} JSON encoded API response object
 */ 
$app->get('/backend/system/filesystem/create/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = false;

	$Config = $this->get('Noodlehaus\Config');
	$UsersFiles = $this->get('PANDORA\Users\UsersFiles');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = false;
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	$directoryPath = null;
	if ($submitData && isset($submitData['directoryPath'])) {
		$directoryPath = $submitData['directoryPath'];
	}

	if($directoryPath){
		// get all sub-directories separated by "/"
		$directoryPath = explode("/", $directoryPath);

		$fullPath = "";

		foreach ($directoryPath as $subdirectory) {
			$fullPath .= $fullPath . "/" . $subdirectory;
			// Check if directory exists and if not create one
			if(!$UsersFiles->isDirectory($user_id, $fullPath)){
				$UsersFiles->createDirectory($user_id, $fullPath);
			}

		}
	}

	return $response->withJson(["success" => $success, "message" => $data]);

});


/**
 * Multi part ajax file upload
 *
 * @param  {array} $_FILES
 * @return {json} JSON encoded API response object
 */
$app->post('/backend/system/filesystem/upload', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = array();

	$FileSystem = $this->get('PANDORA\System\FileSystem');
	$UsersFiles = $this->get('PANDORA\Users\UsersFiles');
	$ResumableUpload = $this->get('PANDORA\System\ResumableUpload');

	$Helpers = $this->get('PANDORA\Helpers\Helpers');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	$uploadedFiles = $request->getUploadedFiles();

	$uploadPath = "uploads";

	if ($request->getHeader('U-Path')) {
		$uploadPath = $request->getHeader('U-Path');
		// get first element from array
		$uploadPath = $uploadPath[0];
	}

	$this->get('Monolog\Logger')->info("PANDORA '/backend/system/filesystem/upload' uploadPath " . $uploadPath);

	if (!empty($_FILES)) {
		foreach ($_FILES as $file) {
			if ($file['error'] !== 0) {
				$message[] = 'file_error_' . $file['error'];
				$this->get('Monolog\Logger')->info("PANDORA '/backend/system/filesystem/upload' file_error " . json_encode($file));
				continue;
			}
			if (!$file['tmp_name']) {
				$message[] = 'file_error_tmp';
				$this->get('Monolog\Logger')->info("PANDORA '/backend/system/filesystem/upload' file_error_tmp " . json_encode($file));
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

			$this->get('Monolog\Logger')->info("PANDORA '/backend/system/filesystem/upload' renamePathToHash " . json_encode($details));
			$renamed_path = $Helpers->renamePathToHash($details);

			if($details['extension'] === ".csv"){
				// Compress original file to GZ archive format
				$this->get('Monolog\Logger')->info("PANDORA '/backend/system/filesystem/upload' renamed_path " . $renamed_path);
				$gzipped_path = $Helpers->compressPath($renamed_path);
			}else{
				$gzipped_path = $renamed_path;
			}

			// Upload compressed file to the Storage
			$this->get('Monolog\Logger')->info("PANDORA '/backend/system/filesystem/upload' uploadFile " . $gzipped_path);
			$remote_path = $FileSystem->uploadFile($user_id, $gzipped_path, $uploadPath);

			// Save reference to Database
			$this->get('Monolog\Logger')->info("PANDORA '/backend/system/filesystem/upload' insertFileToDatabase " . $remote_path);

			$file_id = $UsersFiles->insertFileToDatabase($user_id, $details, $remote_path);

			sleep(3);

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

			$file_details = $UsersFiles->getFileDetails($file_id, ["id", "size", "display_filename", "extension", "mime_type", "item_type"], true);

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
 * Create Directory
 */ 
$app->get('/backend/system/filesystem/directory-create/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$Config = $this->get('Noodlehaus\Config');
	$UsersFiles = $this->get('PANDORA\Users\UsersFiles');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = false;
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	$currentDirectory = false;
	if ($submitData && isset($submitData['currentDirectory'])) {
		$currentDirectory = $submitData['currentDirectory'];
	}

	$subDirectory = false;
	if ($submitData && isset($submitData['subDirectory'])) {
		$subDirectory = $submitData['subDirectory'];
	}
	
	$details = [];
	$details['item_type'] = 3;
	$details['basename'] = md5($subDirectory);
	$details['filename'] = $subDirectory;
	$details['filesize'] = null;
	$details['extension'] = "directory";
	$details['mime_type'] = "text/plain";
	$details['file_hash'] = null;
	$details['details'] = [];

	$remote_path = "users/".$user_id."/".$currentDirectory."/".$subDirectory;

	// Save reference to Database
	$message = $UsersFiles->insertFileToDatabase($user_id, $details, $remote_path);

	return $response->withJson(["success" => $success, "message" =>  $message]);

});

/**
 * Local file upload - upload file that is already on the system
 * @param  {local_file_path} Path to the file in local PHP Back-end file-system
 * @return {json} JSON encoded API response object
 */
$app->get('/backend/system/filesystem/local-upload/{local_file_path:.*}/{new_file_name:.*}', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = array();

	$FileSystem = $this->get('PANDORA\System\FileSystem');
	$UsersFiles = $this->get('PANDORA\Users\UsersFiles');
	$ResumableUpload = $this->get('PANDORA\System\ResumableUpload');

	$Helpers = $this->get('PANDORA\Helpers\Helpers');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$local_file_path = $request->getAttribute('local_file_path');

	$local_file_path = base64_decode($local_file_path);

	$new_file_name = $request->getAttribute('new_file_name');
	$new_file_name = base64_decode($new_file_name);

	
	if(file_exists($local_file_path)){
		$success = true;
		$uploaded_path = $local_file_path;
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
			$file_id = $UsersFiles->insertFileToDatabase($user_id, $details, $remote_path);


			if (file_exists($renamed_path)) {
				@unlink($renamed_path);
			}
			if (file_exists($gzipped_path)) {
				@unlink($gzipped_path);
			}

			$file_details = $UsersFiles->getFileDetails($file_id, ["id", "size", "display_filename", "extension", "mime_type", "item_type"], true);
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
	
    return $response->withHeader('Content-Type', 'text/html')->write('<script>window.close();</script>');

});

/**
 * Retrieves list of files for the user, uploaded in specific user directory
 * @param  {object} submitData Object containing one string variable: selectedDirectory that corresponds to upload_directory column in users_files table
 * @return {json} JSON encoded API response object
 */ 
$app->get('/backend/system/filesystem/list/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$Config = $this->get('Noodlehaus\Config');
	$UsersFiles = $this->get('PANDORA\Users\UsersFiles');

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

	$sort = "DESC";
	$sort_by = "display_filename";
	if (isset($submitData['settings'])) {

		$sort = $submitData['settings']['sort'] === true ? "ASC" : "DESC";
		$sort_by = $submitData['settings']['sort_by'];
	}

	$include_directories = true;
	$data = $UsersFiles->getAllFilesByUserID($user_id, $selectedDirectory, false, $sort, $sort_by, $include_directories);

	// Remove item if current path is not the root item path
	$selected_directory_prefix = "users/".$user_id."/".$selectedDirectory;
	foreach ($data as $item_id => $item){
		$item_directory_prefix = pathinfo($item['file_path'], PATHINFO_DIRNAME);
		if($selected_directory_prefix !== $item_directory_prefix){
			unset($data[$item_id]);
		}
	}

	$message = [];
	foreach ($data as $item) {
		$message[] = $item;
	}

	return $response->withJson(["success" => $success, "message" =>  $message]);

});

/**
 * Deletes file from database and from file system
 * @param  {int} fileID ID of the desired file to be deleted from users_files database table
 * @return {json} JSON encoded API response object
 */
$app->get('/backend/system/filesystem/delete/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$FileSystem = $this->get('PANDORA\System\FileSystem');
	$UsersFiles = $this->get('PANDORA\Users\UsersFiles');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$submitData = false;
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	if (isset($submitData['selectedFiles'])) {
		foreach ($submitData['selectedFiles'] as $selectedFilesKey => $selectedFilesValue) {

			$fileID = (int) $selectedFilesValue['fileId'];
			$fileType = (int) $selectedFilesValue['item_type']; // 1 - file, 3 - directory

			$file_details = $UsersFiles->getFileDetails($fileID, ["uid", "file_path"], false);

			if ($file_details !== false && $user_id == $file_details["uid"]) {

				if($fileType === 1){
					$message = $FileSystem->deleteFileByID($fileID, $file_details["file_path"]);	
				}else if($fileType === 3){
					
					$selectedDirectory = $file_details["file_path"];
					$data = $UsersFiles->getAllFilesByUserID($user_id, $selectedDirectory, false, "DESC", "id", true);

					// Remove item if current path is not the root item path
					foreach ($data as $item_id => $item){
						if((int)$item['item_type'] === 1){
							$item_directory_prefix = pathinfo($item['file_path'], PATHINFO_DIRNAME);	
						}else if((int)$item['item_type'] === 3){
							$item_directory_prefix = $item['file_path'];
						}

						if($selectedDirectory !== $item_directory_prefix){
							unset($data[$item_id]);
						}
					}

					foreach ($data as $item) {
						$message = $FileSystem->deleteFileByID($item["id"], $item["file_path"]);	
					}
					$message = true;
				}
				

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

	$config = $this->get('Noodlehaus\Config');
	$backend_server_url = $config->get('default.backend.server.url');

	$FileSystem = $this->get('PANDORA\System\FileSystem');
	$UsersFiles = $this->get('PANDORA\Users\UsersFiles');
	$Helpers = $this->get('PANDORA\Helpers\Helpers');

	$DatasetResamples = $this->get('PANDORA\Dataset\DatasetResamples');
	$DatasetResamplesMappings = $this->get('PANDORA\Dataset\DatasetResamplesMappings');
	$DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$queueID = false;

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
			$recordDetails = $DatasetQueue->getDetailsByID($recordID, $user_id);
			$queueID = $recordDetails["id"];

		} else if ($downloadType === "resample") {
			$recordDetails = $DatasetResamples->getDetailsByID($recordID, $user_id);
			$queueID = $recordDetails["queueID"];

		} else if ($downloadType === "models") {
			$Models = $this->get('PANDORA\Models\Models');
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
			$fileDetails = $UsersFiles->getFileDetails($fileID, ["file_path", "display_filename", "extension"], false);

			if (isset($fileDetails['file_path'])) {
				$display_filename = $UsersFiles->getDisplayFilename($fileDetails['display_filename'], $fileDetails['extension']);



				// get remote link with a new name
				// $download_url = $FileSystem->getDownloadLink($fileDetails['file_path'], $display_filename);
				$download_filename = str_replace(".tar.gz","", $display_filename);

				if ($downloadType === "resample") {
					$download_filename =  $recordDetails["resampleID"]."_".$download_filename;
					$queueDetails = $DatasetQueue->getDetailsByID($queueID, $user_id);
					$columnMappings = $DatasetResamplesMappings->getMappingsForResample($recordDetails["resampleID"]);
				}else if ($downloadType === "queue") {
					$download_filename =  $queueID."_".$download_filename;
					$queueDetails = $recordDetails;
					$columnMappings = false;
				}

				// Download and de-compress
				$fileInput = $FileSystem->downloadFile($fileDetails['file_path'], $download_filename, false);


				if ($downloadType !== "models") {
					$fileInput = $UsersFiles->remapColumsToOriginal($fileInput, $queueDetails["selectedOptions"], $columnMappings); 
				}

				$this->get('Monolog\Logger')->info("PANDORA '/backend/system/filesystem/download' compressing file for download: " . $fileInput);
				$download_url = $FileSystem->compressFileOrDirectory($fileInput, $display_filename);

				if ($download_url !== false) {
					$downloadLinks[] = ["filename" => $display_filename, 
					"download_url" => $download_url, 
					"local_download_url" => $backend_server_url."/backend/system/filesystem/local-upload/".urlencode(base64_encode($fileInput))."/".urlencode(base64_encode($download_filename))."?HTTP_X_TOKEN=".urlencode($user_details['session_id'])
					];
				}
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


$app->get('/backend/system/filesystem/file-details/{selectedFiles:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = array();

	$config = $this->get('Noodlehaus\Config');
	$UsersFiles = $this->get('PANDORA\Users\UsersFiles');
	$Helpers = $this->get('PANDORA\Helpers\Helpers');

	$selectedFiles = [];
	if (isset($args['selectedFiles'])) {
		$selectedFiles = json_decode(base64_decode(urldecode($args['selectedFiles'])), true);
	}

	foreach ($selectedFiles["selectedFilesIDs"] as $selectedFileID) {
		$this->get('Monolog\Logger')->info("PANDORA '/backend/system/filesystem/file-details' getting details " . $selectedFileID);

		$details = $UsersFiles->getFileDetails($selectedFileID, ["details"], true);

		usort($details["details"]["header"]["formatted"], function($a, $b) {
			return $a['remapped'] <=> $b['remapped'];
		});

		$message = $details;

	}

	return $response->withJson(["success" => $success, "message" => $message]);
});
