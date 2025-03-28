<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-04-18 13:08:04
 */
namespace PANDORA\Users;

use Noodlehaus\Config as Config;
use \Medoo\Medoo;
use \Monolog\Logger;
use \PANDORA\Helpers\Cache as Cache;
use \PANDORA\Helpers\Helpers as Helpers;
use \PANDORA\System\FileSystem as FileSystem;
use \PDO as PDO;



class UsersFiles {

	protected $database;
	protected $logger;

	protected $table_name = "users_files";

	protected $Config;
	protected $Cache;
	protected $Helpers;

	public function __construct(
		Medoo $database,
		Logger $logger,

		Config $Config,
		Cache $Cache,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Config = $Config;
		$this->Cache = $Cache;
		$this->Helpers = $Helpers;

		$this->logger->addInfo("==> INFO: PANDORA\Users\UsersFiles constructed");
	}
	/**
	 * Checks if file is owned by specific user
	 * @return boolean [description]
	 */
	public function isOwner($user_id, $file_id) {
		$file = $this->getFileDetails($file_id, ["uid"]);

		return (intval($user_id) === intval($file["uid"]));
	}

	/**
	 * [updateTable description]
	 * @param  [type] $column      [description]
	 * @param  [type] $value       [description]
	 * @param  [type] $whereColumn [description]
	 * @param  [type] $whereValue  [description]
	 * @return [type]              [description]
	 */
	public function updateTable($column, $value, $whereColumn, $whereValue) {

		$data = $this->database->update($this->table_name, [
			$column => $value,
		], [
			$whereColumn => $whereValue,
		]);

		// Returns the number of rows affected by the last SQL statement
		return ($data->rowCount());
	}

	/**
	 * [getDisplayFilename description]
	 * @param  [type] $filename [description]
	 * @return [type]           [description]
	 */
	public function getDisplayFilename($filename, $extension) {

		$display_filename = "";

		if ($this->Helpers->startsWith($filename, 'genSysFile_queue')) {
			$display_filename = "resample_data";
		} else if ($this->Helpers->endsWith($filename, 'training_partition')) {
			$display_filename = "training_partition";
		} else if ($this->Helpers->endsWith($filename, 'testing_partition')) {
			$display_filename = "testing_partition";
		} else if ($this->Helpers->startsWith($filename, 'modelID')) {
			// TODO: This is temporary
			if ($extension == ".csv") {
				$extension = ".RData";
			}
			$display_filename = str_replace("modelID", "model", $filename);
		} else {
			$display_filename = $filename;
		}
		if ($extension) {
			$display_filename = $display_filename . $extension;
		}
		return ($display_filename . ".tar.gz");
	}


	/**
	 * Insert remote file reference into local database
	 *
	 * @param string $user_id Database ID of the current user
	 * @param array $details file-info array
	 * @param string $remote_path
	 */
	public function insertFileToDatabase($user_id, $details, $remote_path) {
	    $this->logger->addInfo("==> INFO: START insertFileToDatabase for user_id: " . $user_id);

	    // Adjust filename for system files if necessary
	    if ($details['item_type'] === 2 && strpos($details['filename'], "genSysFile_queue_") === 0) {
	        $details['filename'] = str_replace("genSysFile_queue_", "", $details['filename']);
	        $this->logger->addInfo("==> INFO: System file detected, adjusted display filename to: " . $details['filename']);
	    }

	    // Prepare JSON for 'details' and handle any encoding errors
	    $details_json = json_encode($this->Helpers->utf8ize($details['details']));
	    if ($details_json === false) {
	        $this->logger->addError("==> ERROR: JSON encoding failed for 'details' with error: " . json_last_error_msg());
	        return false;
	    }

	    // Prepare the data to be inserted and log the information
	    $insert_data = [
	        "uid" => $user_id,
	        "ufsid" => 1,
	        "item_type" => $details['item_type'],
	        "file_path" => $remote_path,
	        "filename" => md5($details['basename']),
	        "display_filename" => $details['filename'],
	        "size" => $details['filesize'],
	        "extension" => $details['extension'],
	        "mime_type" => $details['mime_type'],
	        "details" => $details_json,
	        "file_hash" => $details['file_hash'],
	        "created" => Medoo::raw("NOW()"),
	        "updated" => Medoo::raw("NOW()"),
	    ];
	    $this->logger->addInfo("==> INFO: insert_data prepared: " . json_encode($insert_data));

	    // Define SQL for insertion with parameter placeholders
	    $sql = "
	        INSERT INTO `{$this->table_name}`
	        (`uid`, `ufsid`, `item_type`, `file_path`, `filename`, `display_filename`, `size`, `extension`, `mime_type`, `details`, `file_hash`, `created`, `updated`) 
	        VALUES (:uid, :ufsid, :item_type, :file_path, :filename, :display_filename, :size, :extension, :mime_type, :details, :file_hash, NOW(), NOW())
	    ";

	    // Mutex lock for sequential execution
	    $file = fopen('/tmp/db_insert.lock', 'c');
	    if ($file && flock($file, LOCK_EX)) {
	        $this->database->pdo->beginTransaction(); // Start transaction
	        $stmt = $this->database->pdo->prepare($sql);

	        // Bind parameters
	        $stmt->bindParam(':uid', $user_id, PDO::PARAM_INT);
	        $stmt->bindParam(':ufsid', $insert_data['ufsid'], PDO::PARAM_INT);
	        $stmt->bindParam(':item_type', $insert_data['item_type'], PDO::PARAM_INT);
	        $stmt->bindParam(':file_path', $insert_data['file_path'], PDO::PARAM_STR);
	        $stmt->bindParam(':filename', $insert_data['filename'], PDO::PARAM_STR);
	        $stmt->bindParam(':display_filename', $insert_data['display_filename'], PDO::PARAM_STR);
	        $stmt->bindParam(':size', $insert_data['size'], PDO::PARAM_INT);
	        $stmt->bindParam(':extension', $insert_data['extension'], PDO::PARAM_STR);
	        $stmt->bindParam(':mime_type', $insert_data['mime_type'], PDO::PARAM_STR);
	        $stmt->bindParam(':details', $insert_data['details'], PDO::PARAM_STR);
	        $stmt->bindParam(':file_hash', $insert_data['file_hash'], PDO::PARAM_STR);

	        // Initialize variable to hold the insert ID
	        $insert_id = false;

	        try {
	            // Attempt to execute and commit the transaction
	            $stmt->execute();
	            $insert_id = $this->database->pdo->lastInsertId();

	            if ($insert_id) {
	                $this->database->pdo->commit(); // Commit transaction
	                $this->logger->addInfo("==> INFO: Database insertion successful. Insert ID: " . $insert_id);
	            } else {
	                $last_error = $this->database->error();
	                $this->logger->addError("==> ERROR: No insert ID returned. Last SQL error: " . json_encode($last_error));
	                $this->database->pdo->rollBack(); // Rollback transaction
	            }
	        } catch (PDOException $pdoException) {
	            // Check for duplicate key error and log it specifically
	            if ($pdoException->getCode() === '23000') { // SQLSTATE code for integrity constraint violation
	                $this->logger->addError("==> ERROR: Duplicate entry detected. " . $pdoException->getMessage());
	            } else {
	                $this->logger->addError("==> PDOException encountered during insertion: " . $pdoException->getMessage());
	            }
	            $this->database->pdo->rollBack(); // Rollback transaction
	        } catch (Exception $e) {
	            $this->logger->addError("==> General Exception encountered during insertion: " . $e->getMessage());
	            $this->database->pdo->rollBack(); // Rollback transaction
	        } catch (Throwable $t) {
	            $this->logger->addError("==> Throwable caught during insertion: " . $t->getMessage());
	            $this->database->pdo->rollBack(); // Rollback transaction
	        } finally {
	            $this->logger->addInfo("==> INFO: Finally block reached; releasing lock.");
	            
	            // Release file lock and close handle
	            if (isset($file) && is_resource($file)) {
	                flock($file, LOCK_UN);
	                fclose($file);
	            }
	        }
	    } else {
	        $this->logger->addError("==> ERROR: Failed to acquire file lock for sequential execution.");
	    }

	    // Log any additional database errors if present
	    $log = $this->database->error();
	    $this->logger->addInfo("==> INFO: Final Database Log: " . json_encode($log));

	    return $insert_id;
	}



	/**
	 * [getFileDetails description]
	 * @param  [type]  $file_id [description]
	 * @param  array   $columns [description]
	 * @param  boolean $cache   [description]
	 * @return [type]           [description]
	 */
	public function getFileDetails($file_id, $columns = ["*"], $cache = true) {
		// Make unique cache key for query
		$cache_key = $this->table_name . "_getFileDetails_" . md5($file_id) . "_" . md5(json_encode($columns));

		$details = $this->Cache->getArray($cache_key);
		if ($cache === false || $details === false) {
			$conditions = [
				'id' => $file_id,
			];
			$details = $this->database->get($this->table_name, $columns, $conditions);
			$this->Cache->setArray($cache_key, $details);
		}
		if (isset($details["details"])) {
			$details["details"] = json_decode($details["details"], true);
		}

		return ($details);
	}

	/**
	 * [getAllFilesByUserID description]
	 * @param  [type]  $user_id          [description]
	 * @param  [type]  $upload_directory [description]
	 * @param  boolean $cache            [description]
	 * @return [type]                    [description]
	 */
	public function getAllFilesByUserID($user_id, $upload_directory, $cache = true, $sort = "DESC", $sort_by = "id", $include_directories = false){

		$cache_key = $this->table_name . "_getAllFilesByUserID_" . md5($user_id . $upload_directory . $sort . $sort_by);

		$details = $this->Cache->getArray($cache_key);



		if ($cache === false || $details === false) {
			$columns = [
				"id",
				"item_type",
				"file_path",
				"size",
				"display_filename",
				"extension",
				"mime_type",
			];

			$item_type = 1;
			if($include_directories) {
				$item_type =  [1, 3];
			}

			$conditions = [
				'uid' => $user_id,
				'item_type' => $item_type,
				'file_path[~]' => "%".$upload_directory."%",
				'ORDER' => [$sort_by => $sort],
			];
			$details = $this->database->select($this->table_name, $columns, $conditions);


			$this->Cache->setArray($cache_key, $details, 5000);
		}

		return ($details);
	}



	/**
	 * [remapColumsToOriginal description]
	 * @param  [type] $fileInput    [directory-name]
	 * @param  [type] $recordID     [archive-name.tar.gz]
	 * @param  [type] $downloadType [archive-name.tar.gz]
	 * @return [type]             [description]
	 */

	public function remapColumsToOriginal($fileInput, $selectedOptions, $columnMappings){

		if(!is_array($selectedOptions)){
			$selectedOptions = json_decode($selectedOptions, true);
		}
		

		if(isset($selectedOptions["features"]) || isset($selectedOptions["outcome"]) || isset($selectedOptions["classes"])){
			$allMappings = array_merge($selectedOptions["features"], $selectedOptions["outcome"], $selectedOptions["classes"]);
		} else if(isset($selectedOptions["header"])){
			$allMappings = $selectedOptions["header"]["formatted"];
		}

		$file_contents = file_get_contents($fileInput);

		// Load CSV file to associative array
		$lines = explode( "\n", $file_contents );
		$headers = str_getcsv( array_shift( $lines ) );
		$data = array();
		foreach ( $lines as $line ) {
			if(trim($line) === ""){
				continue;
			}
			$row = array();
			foreach ( str_getcsv( $line ) as $key => $field ){
				$row[ $headers[ $key ] ] = $field;
			}
			$data[] = $row;
		}

		// Remap array data
		$remappedData = [];
		foreach ($data as $csvRow) {
			$remappedRow = [];

			foreach ($csvRow as $csvRowKey => $csvRowValue) {
				// Remap column values
				if($columnMappings !== false){
					foreach ($columnMappings as $columnMapping) {
						if($csvRowKey === $columnMapping["class_column"]){
							if($columnMapping["class_remapped"] === $csvRowValue){
								$csvRowValue = $columnMapping["class_original"];
							}
						}
					}
				}
				// remap column keys
				foreach ($allMappings as $mapping) {
					if($mapping["remapped"] === $csvRowKey){
						$csvRowKey = $mapping["original"];
					}
				}
				$remappedRow[$csvRowKey] = $csvRowValue;
			}
			if(count($remappedRow) > 0){
				$remappedData[] = $remappedRow;
			}
		}
		
		// Empty existing file
		$f = @fopen($fileInput, "r+");
		if ($f !== false) {
		    ftruncate($f, 0);
		    fclose($f);
		}

		// Save new data to the existing file
		$has_header = false;
		foreach ($remappedData as $c) {
			$fp = fopen($fileInput, 'a');
			if (!$has_header) {
				fputcsv($fp, array_keys($c));
				$has_header = true;
			}
			fputcsv($fp, $c);
			fclose($fp);
		}
		return ($fileInput);
	}
}
