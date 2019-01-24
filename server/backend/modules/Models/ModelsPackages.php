<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-09 10:51:56
 */
namespace SIMON\Models;

use \Medoo\Medoo;
use \Monolog\Logger;

class ModelsPackages {
	protected $table_name = "models_packages";
	protected $database;
	protected $logger;

	public function __construct(
		Medoo $database,
		Logger $logger
	) {
		$this->database = $database;
		$this->logger = $logger;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\Models\ModelsPackages constructed");
	}
	/**
	 * Get all available analysis packages
	 */
	public function getPackages($installed = 1, $packageIDs = null) {
		$columns = [
			"id [Int]",
			"internal_id",
			"label",
			"classification [Bool]",
			"regression [Bool]",
			"tags [JSON]",
			"tuning_parameters [JSON]",
			"citations [JSON]",
			"time_per_million [Int]",
		];

		$conditions = [
			'installed' => $installed,
		];

		if ($packageIDs !== null) {
			$conditions["id"] = array_values($packageIDs);
		}

		$details = $this->database->select($this->table_name, $columns, $conditions);

		return ($details);
	}
}
