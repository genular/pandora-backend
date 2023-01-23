<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:08:25
 */
namespace PANDORA\Users;

use \Medoo\Medoo;
use \Monolog\Logger;
use \PANDORA\Organization\Organization as Organization;

class UsersOrganization {

	protected $table_name = "users_organization";
	protected $database;
	protected $logger;
	protected $Organization;

	public function __construct(
		Medoo $database,
		Logger $logger,
		Organization $Organization
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Organization = $Organization;

		$this->logger->addInfo("==> INFO: PANDORA\Users\UsersOrganization constructed");
	}

	/**
	 * [getUsersOrganizationByUserId description]
	 * @param  [type] $user_id [description]
	 * @return [type]          [description]
	 */
	public function getUsersOrganizationByUserId($user_id) {
		$columns = "*";
		$conditions = [
			'uid' => $user_id,
		];
		$users_organization = $this->database->get($this->table_name, $columns, $conditions);

		return ($users_organization);
	}
}
