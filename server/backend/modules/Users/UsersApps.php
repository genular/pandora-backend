<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-06-08 15:58:56
 */
namespace SIMON\Users;

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

		$this->logger->addInfo("==> INFO: SIMON\Users\UsersApps constructed");
	}

	public function getUsersAppsByUserId($user_id) {
		$columns = "*";
		$conditions = [
			'uid' => $user_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);

		return ($details);
	}
}
