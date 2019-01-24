<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-06-11 10:41:11
 */
namespace SIMON\Organization;

use \Medoo\Medoo;
use \Monolog\Logger;

class Organization {
	protected $table_name = "organization";
	protected $database;
	protected $logger;

	public function __construct(
		Medoo $database,
		Logger $logger
	) {
		$this->database = $database;
		$this->logger = $logger;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\Organization constructed");
	}

	public function getOrganizationByUserId($user_id) {
		$columns = "*";
		$conditions = [
			'uid' => $user_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);

		return ($details);
	}
}
