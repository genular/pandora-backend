<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:18:09
 */
namespace PANDORA\Organization;

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
		$this->logger->addInfo("==> INFO: PANDORA\Organization constructed");
	}

	/**
	 * [getOrganizationByUserId description]
	 * @param  [int] $user_id
	 * @return [array]
	 */
	public function getOrganizationByUserId($user_id) {
		$columns = "*";
		$conditions = [
			'uid' => $user_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);

		return ($details);
	}
}
