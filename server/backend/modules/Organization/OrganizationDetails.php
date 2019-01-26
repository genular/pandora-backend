<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:18:16
 */
namespace SIMON\OrganizationDetails;

use \Medoo\Medoo;
use \Monolog\Logger;

class OrganizationDetails {
	protected $table_name = "organization_details";
	protected $database;
	protected $logger;

	public function __construct(
		Medoo $database,
		Logger $logger
	) {
		$this->database = $database;
		$this->logger = $logger;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\OrganizationDetails constructed");
	}

	/**
	 * [getOrganizationDetailsByUserId description]
	 * @param  [int] $user_id
	 * @return [array]
	 */
	public function getOrganizationDetailsByUserId($user_id) {
		$columns = "*";
		$conditions = [
			'uid' => $user_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);

		return ($details);
	}
}
