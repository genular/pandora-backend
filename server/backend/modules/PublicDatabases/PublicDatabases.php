<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-08 16:27:54
 */
namespace SIMON\PublicDatabases;

use Noodlehaus\Config as Config;
use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Cache as Cache;
use \SIMON\Helpers\Helpers as Helpers;
use \SIMON\System\FileSystem as FileSystem;

class PublicDatabases {
	protected $table_name = "public_databases";
	protected $database;
	protected $logger;
	protected $Helpers;

	protected $FileSystem;

	protected $Config;
	protected $Cache;
	protected $temp_download_dir = "/tmp/downloads";

	public function __construct(
		Medoo $database,
		Logger $logger,

		Config $Config,
		Cache $Cache,
		Helpers $Helpers,
		FileSystem $FileSystem
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Config = $Config;
		$this->Cache = $Cache;
		$this->Helpers = $Helpers;
		$this->FileSystem = $FileSystem;

		$this->logger->addInfo("==> INFO: SIMON\PublicDatabases\PublicDatabases constructed");
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
	 * [getDatasetQueueCount description]
	 * @param  [type] $column  [description]
	 * @param  [type] $value   [description]
	 * @param  array  $filters [description]
	 * @return [type]          [description]
	 */
	public function getDatasetQueueCount($column, $value, $filters = []) {
		$columns = "*";
		$conditions = [
			$column => $value,
		];
		$count = $this->database->count($this->table_name, $columns, $conditions);

		return ($count);
	}

	/**
	 * [getDatasetByID description]
	 * @param  [type]  $datasetID [description]
	 * @param  boolean $cache   [description]
	 * @return [type]           [description]
	 */
	public function getDatasetByID($datasetID, $cache = true) {

		$cache_key = $this->table_name . "_getFileByID_" . md5($datasetID);
		$details = $this->Cache->getArray($cache_key);

		if ($cache === false || $details === false) {
			$columns = "*";
			$conditions = [
				'id' => $datasetID,
			];
			$details = $this->database->get($this->table_name, $columns, $conditions);
			$this->Cache->setArray($cache_key, $details);
		}

		return ($details);
	}
	/**
	 * Downloads file from remote server to temporary place in our local file-system
	 * @param  [type] $datasetID [description]
	 * @return [type]          [description]
	 */
	public function downloadInternalDataset($datasetID) {

		$datasetDetails = $this->getDatasetByID($datasetID, false);

		$datasetPathRemote = "/datasets/" . $datasetDetails["hash"] . ".csv.tar.gz";
		$datasetPathLocal = $this->FileSystem->downloadFile($datasetPathRemote, $this->Helpers->sanitizeFileName($datasetDetails["title"]) . ".csv");

		return $datasetPathLocal;
	}

	/**
	 * Retrive all datasets for specific criteria
	 * @param  [type] $user_id [description]
	 * @param  [type] $page    [description]
	 * @param  [type] $limit   [description]
	 * @param  string $sort    [description]
	 * @param  string $sort_by    [description]
	 * @param  array  $custom [description]
	 * @return [type]          [description]
	 */
	public function getList($user_id, $page, $limit, $sort_by, $sort, $custom, $sql_calc_found_rows = false) {
		$sort_by_options = ['id', 'title', 'rows', 'columns', 'sparsity', 'updated'];
		if (!in_array($sort_by, $sort_by_options)) {
			$sort_by = "id";
		}
		if ($limit < 1 || $limit > 50) {
			$limit = 50;
		}
		$start_limit = (($page - 1) * $limit);
		$end_limit = $limit;

		if ($sort === "+") {
			$sort = "ASC";
		} else {
			$sort = "DESC";
		}

		$filters = [
			":user_id" => $user_id,
		];

		$sql = "SELECT ";
		if ($sql_calc_found_rows === false) {
			$sql = $sql . $this->table_name . ".id    AS datasetID,
				    " . $this->table_name . ".title,
				    " . $this->table_name . ".description,
				    " . $this->table_name . ".format,
				    " . $this->table_name . ".source,
				    " . $this->table_name . ".references,
				    " . $this->table_name . ".example,
				    " . $this->table_name . ".rows,
				    " . $this->table_name . ".columns,
				    " . $this->table_name . ".hash,
				    CONCAT('https://genular.ams3.cdn.digitaloceanspaces.com/datasets/', " . $this->table_name . ".hash, '.csv.tar.gz') AS downloadLink,
				    " . $this->table_name . ".sparsity,
				    " . $this->table_name . ".updated";
		} else {
			$sql = $sql . "COUNT(id) AS total";
		}

		$sql = $sql . " FROM " . $this->table_name . "

	            WHERE " . $this->table_name . ".uid = :user_id
	            OR " . $this->table_name . ".uid IS NULL
	            AND " . $this->table_name . ".rows > 5
	            AND " . $this->table_name . ".columns > 5
	            AND " . $this->table_name . ".format IS NOT NULL";

		if (trim($custom) !== "") {
			$sql = $sql . " AND MATCH(public_databases.title, public_databases.description, public_databases.format, public_databases.source, public_databases.references) AGAINST('" . $custom . "' IN BOOLEAN MODE)";

		}

		if ($sql_calc_found_rows === false) {
			$filters[":start_limit"] = $start_limit;
			$filters[":end_limit"] = $end_limit;
			$sql = $sql . " ORDER BY " . $this->table_name . "." . $sort_by . " " . $sort . " LIMIT :start_limit, :end_limit;";
		} else {
			$sql = $sql . " ORDER BY " . $this->table_name . "." . $sort_by . " " . $sort . ";";
		}

		if ($sql_calc_found_rows === false) {
			$details = $this->database->query($sql, $filters)->fetchAll(\PDO::FETCH_ASSOC);
			$totalResults = $this->getList($user_id, $page, $limit, $sort_by, $sort, $custom, true);
			return array($details, $totalResults);
		} else {
			$details = $this->database->query($sql, $filters)->fetch();
			return (int) $details["total"];
		}
	}
}
