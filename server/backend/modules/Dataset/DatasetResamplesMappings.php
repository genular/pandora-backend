<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:24:46
 */
namespace PANDORA\Dataset;

use \Medoo\Medoo;
use \Monolog\Logger;
use \PANDORA\Helpers\Helpers as Helpers;
use \PANDORA\System\FileSystem as FileSystem;

class DatasetResamplesMappings {
	protected $table_name = "dataset_resamples_mappings";
	protected $database;
	protected $logger;
	protected $FileSystem;
	protected $Helpers;

	public function __construct(
		Medoo $database,
		Logger $logger,
		FileSystem $FileSystem,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->FileSystem = $FileSystem;
		$this->Helpers = $Helpers;
		// Log anything.
		$this->logger->addInfo("==> INFO: PANDORA\Dataset\DatasetResamplesMappings constructed");
	}

	/**
	 * [deleteByQueueIDs description]
	 * @param  [type] $queueIDs [description]
	 * @return [type]           [description]
	 */
	public function deleteByQueueIDs($queueIDs) {
		$data = $this->database->delete($this->table_name, [
			"AND" => [
				"dqid" => $queueIDs,
			],
		]);
		return ($data->rowCount());
	}

	public function getMappingsForResample($resampleID){

		$columns = [
			"id [Int]",
			"dqid [Int]",
			"class_column",
			"class_type [Int]",
			"class_original",
			"class_remapped"
		];
		$conditions = [
			"drid" => $resampleID,
			"ORDER" => ["id" => "DESC"],
		];
		$details = $this->database->select($this->table_name, $columns, $conditions);

		return ($details);

	}
}
