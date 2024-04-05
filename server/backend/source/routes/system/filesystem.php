<?php

use Slim\Http\Request;
use Slim\Http\Response;

/**
 * Creates a nested directory structure within the user's space.
 * 
 * This route processes a request to create a hierarchical directory structure based on a given path.
 * The path is specified relative to the user's root directory. Each segment of the path is validated 
 * and created if it does not exist. The operation is performed recursively based on the supplied path segments.
 *
 * @param Request $request The request object, which includes user details and the submitted data.
 * @param Response $response The response object used to return the operation's outcome.
 * @param array $args Arguments passed in the route, including 'submitData' which contains the directory path.
 * @return Response Returns a JSON response indicating the success or failure of the directory creation process.
 */
$app->get('/backend/system/filesystem/create/{submitData:.*}', function (Request $request, Response $response, array $args) {
    // Initialize response variables
    $success = true; // Assume success until a failure occurs
    $data = []; // Prepare an empty data array to potentially hold any response data

    // Access configured services
    $Config = $this->get('Noodlehaus\Config');
    $UsersFiles = $this->get('PANDORA\Users\UsersFiles');

    // Extract user details from the request
    $user_details = $request->getAttribute('user');
    $user_id = $user_details['user_id'];

    // Decode the submitted data to get the directory path
    $submitData = false;
    if (isset($args['submitData'])) {
        $submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
    }

    $directoryPath = null;
    if ($submitData && isset($submitData['directoryPath'])) {
        $directoryPath = $submitData['directoryPath'];
    }

    if ($directoryPath) {
        // Split the path into segments to process each directory in the hierarchy
        $directorySegments = explode("/", $directoryPath);
        $fullPath = "";

        foreach ($directorySegments as $subdirectory) {
            // Construct the full path incrementally to ensure each segment exists
            $fullPath = trim($fullPath . "/" . $subdirectory, "/");

            // Check if the current segment directory exists, create if not
            if (!$UsersFiles->isDirectory($user_id, $fullPath)) {
                if (!$UsersFiles->createDirectory($user_id, $fullPath)) {
                    // If creation failed, update success flag and break out of the loop
                    $success = false;
                    $data['error'] = "Failed to create directory at path: $fullPath";
                    break;
                }
            }
        }
    } else {
        // No directory path was provided in the request
        $success = false;
        $data['error'] = "No directory path provided.";
    }

    // Return the success status and any message or data
    return $response->withJson(["success" => $success, "message" => $data]);
});


/**
 * Processes file uploads, handling both single and chunked uploads.
 *
 * This endpoint supports uploading files directly or in chunks for large files. It processes uploaded files,
 * validates CSV headers, renames files for standardization, compresses them, and uploads to a specified storage path.
 * Successful uploads are recorded in the database with details accessible to the user. The function handles file
 * validation, chunk assembly for resumable uploads, and cleanup of temporary files.
 *
 * @param Request $request The request object, including uploaded files and additional data like chunk identifiers.
 * @param Response $response The response object for sending back the upload result.
 * @param array $args Unused in this function but required by the route definition.
 * 
 * @return Response JSON response indicating the success of the upload and details of the uploaded file.
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
 * Creates a new directory within the specified current directory for a user.
 * 
 * This route decodes the submitted data to determine the current directory and 
 * the name of the subdirectory to be created. It then constructs the directory 
 * details, including generating a unique basename via hashing, and attempts to 
 * insert a reference to this new directory into the database.
 *
 * @param Request $request The request object, containing the decoded JWT user details.
 * @param Response $response The response object used to return a JSON response.
 * @param array $args Arguments passed in the route, including encoded 'submitData'.
 *
 * @return Response Returns a JSON response indicating the success or failure of the directory creation.
 */
$app->get('/backend/system/filesystem/directory-create/{submitData:.*}', function (Request $request, Response $response, array $args) {
    // Initial success and message variables
    $success = true;
    $message = false;

    // Retrieve configuration and UsersFiles service
    $Config = $this->get('Noodlehaus\Config');
    $UsersFiles = $this->get('PANDORA\Users\UsersFiles');

    // Extract user details from the request attribute
    $user_details = $request->getAttribute('user');
    $user_id = $user_details['user_id'];

    // Decode the submitted data
    $submitData = false;
    if (isset($args['submitData'])) {
        $submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
    }

    // Extract current and subdirectory names from the submitted data
    $currentDirectory = $submitData['currentDirectory'] ?? false;
    $subDirectory = $submitData['subDirectory'] ?? false;

    // Prepare the directory details for database insertion
    $details = [
        'item_type' => 3, // Indicator of a directory type
        'basename' => md5($subDirectory), // Unique identifier
        'filename' => $subDirectory, // Directory name
        'filesize' => null, // Not applicable for directories
        'extension' => "directory", // Custom extension indicating a directory
        'mime_type' => "text/plain", // Generic MIME type
        'file_hash' => null, // Not applicable for directories
        'details' => [] // Additional details, if any
    ];

    // Construct the remote path for the new directory
    $remote_path = "users/" . $user_id . "/" . $currentDirectory . "/" . $subDirectory;

    // Attempt to insert the directory reference into the database
    $message = $UsersFiles->insertFileToDatabase($user_id, $details, $remote_path);

    // Return the operation result
    return $response->withJson(["success" => $success, "message" => $message]);
});


/**
 * Route to preview the first N lines of a CSV file.
 * 
 * This route fetches file details based on a provided file ID, downloads the file,
 * and returns a preview of its contents. It supports pagination and remaps column
 * headers from their stored representation to the original column names as defined
 * in the file's metadata.
 *
 * @param Request $request The request object.
 * @param Response $response The response object.
 * @param array $args Arguments passed in the route, including encoded 'submitData'.
 *
 * @return Response Returns a JSON response containing the preview data or an error message.
 */
$app->get('/backend/system/filesystem/preview-file/{submitData:.*}', function (Request $request, Response $response, $args) use ($app) {
    // Inject required services
    $FileSystem = $this->get('PANDORA\System\FileSystem');
    $UsersFiles = $this->get('PANDORA\Users\UsersFiles');
    $Helpers = $this->get('PANDORA\Helpers\Helpers');

    // Attempt to decode the submitted data
    $submitData = false;
    if (isset($args['submitData'])) {
        $submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
    }

    // Validate the presence of the file ID in the request
    $fileId = $submitData['selectedFile']['fileId'] ?? false;
    if (!$fileId) {
        // Respond with an error if file ID is missing
        return $response->withJson(['success' => false, 'message' => 'File ID is missing.'], 400);
    }

    // Retrieve file details using the provided file ID
    $details = $UsersFiles->getFileDetails($fileId, ["file_path", "details"], true);
    if (!$details || !isset($details["file_path"])) {
        // Respond with an error if file details could not be retrieved
        return $response->withJson(['success' => false, 'message' => 'File details not found.'], 404);
    }

    // Download the file for processing
    $filePath = $FileSystem->downloadFile($details["file_path"]);
    if (!$filePath) {
        // Respond with an error if the file could not be downloaded
        return $response->withJson(['success' => false, 'message' => 'Failed to download file.'], 500);
    }

    // Set up pagination variables
    $currentPage = $submitData['page'] ?? 1;
    $linesPerPage = $submitData['rows'] ?? 100;
    $offset = ($currentPage - 1) * $linesPerPage;

    // Obtain header mapping for original column names
    $headerMapping = $Helpers->remapHeadersToOriginal($details["details"]["header"]["formatted"]);

    // Initialize data collection
    $data = [];
    $rowCount = 0;

    // Open and process the CSV file
    if (($handle = fopen($filePath, "r")) !== FALSE) {
        // Read and remap headers to their original names
        $headers = fgetcsv($handle);
        if (!$headers) {
            // Respond with an error if headers could not be read
            return $response->withJson(['success' => false, 'message' => 'Failed to read headers from file.'], 500);
        }
        
        // Apply header remapping
        $headers = array_map(function($header) use ($headerMapping) {
            return $headerMapping[$header] ?? $header;
        }, array_slice($headers, 0, 50));

        // Skip rows to reach the desired offset for pagination
        while ($offset-- > 0 && fgetcsv($handle) !== FALSE) {}

        // Collect the required number of lines of data
        while (($row = fgetcsv($handle)) !== FALSE && $rowCount < $linesPerPage) {
            $rowData = array_slice($row, 0, 50);
            if (count($headers) == count($rowData)) {
                $data[] = array_combine($headers, $rowData);
            }
            $rowCount++;
        }
        fclose($handle);

        // Prepare the successful response body
        $responseBody = ['success' => true, 'message' => $data];
    } else {
        // Respond with an error if the file could not be opened
        $responseBody = ['success' => false, 'message' => 'Unable to open file for reading.'];
    }

    // Return the processed data or an error message in JSON format
    return $response->withJson($responseBody, 200);
});

/**
 * Handles the upload of a local file to a temporary server location and then processes it.
 *
 * This endpoint receives a local file path and a new file name, copies the file to a temporary directory,
 * and processes it for upload. The process includes validation of the CSV file header, renaming the file
 * for standardization, compressing it, and finally uploading the compressed file to a storage solution.
 * Successful operations update the database with the new file's details. The response triggers a browser
 * action to close the window, signaling the end of the upload process.
 *
 * @param Request $request The request object, containing `local_file_path` and `new_file_name`, both base64 encoded.
 * @param Response $response The response object for signaling the upload's completion to the client.
 * @param array $args Contains `local_file_path` and `new_file_name`, detailing the file to upload and its new name.
 * 
 * @return Response Triggers a browser action to close the window, indicating the end of the process.
 */
$app->get('/backend/system/filesystem/local-upload/{local_file_path:.*}/{new_file_name:.*}', function (Request $request, Response $response, array $args) {
	$success = false;
	$uploaded_path = false;
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

	// Use PHP's temporary directory as the destination
	$destination_directory = sys_get_temp_dir();
	// Full path to the new file in the temporary directory
	$new_full_path = $destination_directory . DIRECTORY_SEPARATOR . basename($local_file_path);

	if(file_exists($local_file_path)){
		if (copy($local_file_path, $new_full_path)) {
			$success = true;
			// make a new copy of the file
			$uploaded_path = $ResumableUpload->moveUploadedFile($new_full_path, $new_file_name);
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
	
    // check if HTTP_X_TOKEN is present specifically in request URL
    $token = $request->getQueryParam('HTTP_X_TOKEN');
    if ($token) {
        return $response->withHeader('Content-Type', 'text/html')->write('<script>window.close();</script>');
    }else{
        $message["details"] = $details["details"];
        return $response->withJson(["success" => $success, "message" => $message]);
    }
});

/**
 * Lists files and directories for a user with optional sorting.
 *
 * Retrieves a list of files and directories for the authenticated user from a specified directory.
 * The directory and sorting parameters are provided in the `submitData` argument. This argument is
 * a base64 encoded JSON string that may specify the selected directory and sorting preferences.
 * Directories in the response include a calculated size based on the total size of all contained items.
 *
 * @param Request $request The request object, containing user details and optional `submitData`.
 * @param Response $response The response object for sending back the list of files/directories.
 * @param array $args Contains the `submitData` parameter with details like `selectedDirectory` and sorting settings.
 * 
 * @return Response JSON response with `success` status and list of files/directories in `message`.
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

	$directories = [];

	foreach ($data as $item_id => $item){

		$item_directory_prefix = pathinfo($item['file_path'], PATHINFO_DIRNAME);
		if($selected_directory_prefix !== $item_directory_prefix){
			unset($data[$item_id]);
		}
		if($item['item_type'] === "3"){
			$directories[$item['id']] = $item;
		}
	}
	// Loop directories and calculate size of all files inside
	foreach ($directories as $directory_id => $directory){
	 	$directory_data = $UsersFiles->getAllFilesByUserID($user_id, $directory["file_path"], false, $sort, $sort_by, $include_directories);

	 	foreach($directory_data as $item){
	 		$directories[$directory_id]["size"] += $item["size"];
	 	}
	}

	foreach ($data as $item_id => $item){
		if($item['item_type'] === "3"){
			$data[$item_id]["size"] = $directories[$item['id']]["size"];
		}
	}

	$message = [];
	foreach ($data as $item) {
		$message[] = $item;
	}

	return $response->withJson(["success" => $success, "message" =>  $message]);

});

/**
 * Deletes files or directories specified by the client.
 * 
 * This endpoint allows clients to delete files or directories. The client must provide a list of items
 * to be deleted, specified by their IDs and types (file or directory), as part of the `submitData` parameter.
 * The actual deletion process is determined by the item type: individual files are deleted directly, while
 * directories entail a deletion of all contained files. The operation is allowed only if the user initiating
 * the request owns the items.
 *
 * @param Request $request The request object, containing the `submitData` parameter and user details.
 * @param Response $response The response object used to return the operation's outcome.
 * @param array $args Contains the `submitData` parameter, a base64 encoded JSON string representing an array
 *                    with details about the selected files or directories to delete. The `submitData` array
 *                    includes `selectedFiles`, each having a `fileId` and an `item_type` indicating whether
 *                    it's a file (1) or a directory (3).
 * 
 * @return Response Returns a JSON response indicating the success or failure of the deletion operation.
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
 * Downloads files related to dataset processing in the PANDORA ML software.
 * 
 * This endpoint allows authenticated users to download files based on the provided submitData.
 * The submitData must include a recordID and downloadType, which determines the source of the files
 * (e.g., queue, resample, models). It fetches file details from the database, generates download links,
 * remaps columns to their original names if necessary, and compresses the files for download.
 * 
 * @param Request $request The SLIM request object containing details of the HTTP request.
 * @param Response $response The SLIM response object for sending back the HTTP response.
 * @param array $args Associative array of route parameters; expects 'submitData' with encoded JSON data.
 * 
 * @return Response Returns a JSON response with success status and messages or download links.
 * 
 * @throws Exception If there's an error in processing, exceptions may be thrown internally but are caught
 *                   and handled by generating an appropriate HTTP response.
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
        $downloadIDs = [];

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

		} else if ($downloadType === "userFile") {
            if(isset($submitData['recordID'])){
                if(is_array($submitData['recordID'])){
                    $downloadIDs = (int) $submitData['recordID'];
                }else{
                    $downloadIDs = [$submitData['recordID']];    
                }
            }
        }


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
			$fileDetails = $UsersFiles->getFileDetails($fileID, ["file_path", "display_filename", "extension", "details"], false);

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

				}else if ($downloadType === "userFile") {
       
                    if(isset($fileDetails["details"])){
                        $queueDetails = $fileDetails["details"];        
                    }

                }

				// Download and de-compress
				$fileInput = $FileSystem->downloadFile($fileDetails['file_path'], $download_filename, false);

				if ($downloadType === "queue" || $downloadType  === "models") {
					$fileInput = $UsersFiles->remapColumsToOriginal($fileInput, $queueDetails["selectedOptions"], $columnMappings); 
                }else if($downloadType === "userFile"){
                    $fileInput = $UsersFiles->remapColumsToOriginal($fileInput, $queueDetails, false); 
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


		if (count($downloadLinks) > 0) {
			$message = $downloadLinks;
			$success = true;
		}else{
			$success = false;
			$message = "No files found for download!";
		}
	}
	return $response->withJson(["success" => $success, "message" => $message]);
});

/**
 * Retrieves file details for selected files in the PANDORA ML software filesystem.
 * 
 * This endpoint accepts a base64 encoded JSON string representing the IDs of selected files
 * via the URL path. It decodes and processes this string to fetch details for each file,
 * sorts the details based on a specified criteria, and returns them in the response.
 * 
 * @param Request $request The request object, providing access to the HTTP request method, headers, and body.
 * @param Response $response The response object, used to build and return the HTTP response.
 * @param array $args Arguments passed from the route, including 'selectedFiles' which is a base64 encoded JSON string.
 * 
 * @return Response Returns a JSON response containing a success status and message with file details.
 * 
 * @throws Exception Throws an exception if decoding the selectedFiles fails or if fetching file details encounters errors.
 */
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
