<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-31 15:27:56
 */
namespace SIMON\Dataset;

use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;
use \SIMON\Models\ModelsPackages as ModelsPackages;

class DatasetDatabase {
	protected $table_name = "dataset_database";
	protected $database;
	protected $logger;
	protected $Helpers;

	protected $ModelsPackages;

	public function __construct(
		Medoo $database,
		Logger $logger,
		ModelsPackages $ModelsPackages,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;

		$this->ModelsPackages = $ModelsPackages;
		$this->Helpers = $Helpers;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\Dataset\DatasetDatabase constructed");
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
	 * Retrive all datasets for specific criteria
	 * @param  [type] $user_id [description]
	 * @param  [type] $page    [description]
	 * @param  [type] $limit   [description]
	 * @param  [type] $sort    [description]
	 * @param  array  $custom [description]
	 * @return [type]          [description]
	 */
	public function getList($user_id, $page, $limit, $sort, $custom, $sql_calc_found_rows = false) {

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
			$sql = $sql . "dataset_database.id    AS datasetID,
				    dataset_database.title   AS title,
				    dataset_database.description_html   AS description,
				    dataset_database.rows    AS rows,
				    dataset_database.columns AS columns,
				    dataset_database.hash AS hash,
				    CONCAT('https://ams3.digitaloceanspaces.com/genular/datasets/', dataset_database.hash, '.csv.tar.gz') AS downloadLink,
				    dataset_database.sparsity AS sparsity,
				    dataset_database.updated AS updated";
		} else {
			$sql = $sql . "COUNT(id) AS total";
		}

		$sql = $sql . " FROM dataset_database

	            WHERE dataset_database.uid = :user_id
	            OR dataset_database.uid IS NULL";

		if (trim($custom) !== "") {
			$sql = $sql . " AND MATCH(description_latex) AGAINST('+" . $custom . "' IN BOOLEAN MODE)";

		}

		if ($sql_calc_found_rows === false) {
			$filters[":start_limit"] = $start_limit;
			$filters[":end_limit"] = $end_limit;
			$sql = $sql . " ORDER BY dataset_database.id " . $sort . " LIMIT :start_limit, :end_limit;";
		} else {
			$sql = $sql . " ORDER BY dataset_database.id " . $sort . ";";
		}

		if ($sql_calc_found_rows === false) {
			$details = $this->database->query($sql, $filters)->fetchAll(\PDO::FETCH_ASSOC);
			$totalResults = $this->getList($user_id, $page, $limit, $sort, $custom, true);

			return array($details, $totalResults);
		} else {
			$details = $this->database->query($sql, $filters)->fetch();
			return (int) $details["total"];
		}
	}
}
