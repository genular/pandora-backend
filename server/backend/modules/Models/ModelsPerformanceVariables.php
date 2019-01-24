<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-06-08 16:12:49
 */
namespace SIMON\Models;

use \Medoo\Medoo;
use \Monolog\Logger;

class ModelsPerformanceVariables {
	protected $table_name = "models_performance_variables";
	protected $database;
	protected $logger;

	public function __construct(
		Medoo $database,
		Logger $logger
	) {
		$this->database = $database;
		$this->logger = $logger;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\Models\ModelsPerformanceVariables constructed");
	}

}
