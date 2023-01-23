<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:07:04
 */
namespace PANDORA\Users;

use \Medoo\Medoo;
use \Monolog\Logger;

class UsersApps {
	protected $table_name = "users_apps";
	protected $database;
	protected $logger;

	public function __construct(
		Medoo $database,
		Logger $logger
	) {
		$this->database = $database;
		$this->logger = $logger;

		$this->logger->addInfo("==> INFO: PANDORA\Users\UsersApps constructed");
	}

	/**
	 * [getUsersAppsByUserId description]
	 * @param  [type] $user_id [description]
	 * @return [type]          [description]
	 */
	public function getUsersAppsByUserId($user_id) {
		$columns = "*";
		$conditions = [
			'uid' => $user_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);

		return ($details);
	}
}
