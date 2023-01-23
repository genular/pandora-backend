<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2021-02-04 10:35:21
 */
namespace PANDORA\Models;

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
		$this->logger->addInfo("==> INFO: PANDORA\Models\ModelsPackages constructed");
	}

	/**
	 * Get all available analysis packages
	 * @param  integer $installed  [description]
	 * @param  [type]  $packageIDs [description]
	 * @return [type]              [description]
	 */
	public function getPackages($installed = 1, $packageIDs = null, $packageNameIDs = null) {
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

		if ($packageNameIDs !== null) {
			$conditions["internal_id"] = array_values($packageNameIDs);
		}

		$details = $this->database->select($this->table_name, $columns, $conditions);

		return ($details);
	}
}
