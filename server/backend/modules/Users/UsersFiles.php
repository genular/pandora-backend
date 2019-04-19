<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-04-18 13:08:04
 */
namespace SIMON\Users;

use Noodlehaus\Config as Config;
use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Cache as Cache;
use \SIMON\Helpers\Helpers as Helpers;

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

		$this->logger->addInfo("==> INFO: SIMON\Users\UsersFiles constructed");
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
		// Display user friendly name for system files
		if ($details['item_type'] === 2) {
			if (substr($details['filename'], 0, 17) !== "genSysFile_queue_") {
				$details['filename'] = str_replace("genSysFile_queue_", "", $details['filename']);
			}
		}

		$this->database->insert($this->table_name, [
			"uid" => $user_id,
			"ufsid" => 1,
			"item_type" => $details['item_type'],
			"file_path" => $remote_path,
			"filename" => md5($details['basename']),
			"display_filename" => $details['filename'],
			"size" => $details['filesize'],
			"extension" => $details['extension'],
			"mime_type" => $details['mime_type'],
			"details" => json_encode($details['details']),
			"file_hash" => $details['file_hash'],
			"created" => Medoo::raw("NOW()"),
			"updated" => Medoo::raw("NOW()"),
		]);

		return $this->database->id();
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
	public function getAllFilesByUserID($user_id, $upload_directory, $cache = true, $sort = "DESC", $sort_by = "id") {

		$cache_key = $this->table_name . "_getAllFilesByUserID_" . md5($user_id . $upload_directory . $sort . $sort_by);

		$details = $this->Cache->getArray($cache_key);

		if ($cache === false || $details === false) {
			$columns = [
				"id",
				"item_type",
				"size",
				"display_filename",
				"extension",
				"mime_type",
			];
			$conditions = [
				'uid' => $user_id,
				'item_type' => 1,
				'file_path[~]' => $upload_directory,
				'ORDER' => [$sort_by => $sort],
			];

			$details = $this->database->select($this->table_name, $columns, $conditions);
			$this->Cache->setArray($cache_key, $details, 5000);
		}

		return ($details);
	}
}
