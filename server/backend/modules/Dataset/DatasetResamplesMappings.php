<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-24 09:02:41
 */
namespace SIMON\Dataset;

use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;
use \SIMON\System\FileSystem as FileSystem;

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
		$this->logger->addInfo("==> INFO: SIMON\Dataset\DatasetResamplesMappings constructed");
	}

	public function deleteByQueueIDs($queueIDs) {
		$data = $this->database->delete($this->table_name, [
			"AND" => [
				"dqid" => $queueIDs,
			],
		]);
		return ($data->rowCount());
	}
}
