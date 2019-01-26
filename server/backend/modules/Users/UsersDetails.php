<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:08:18
 */
namespace SIMON\Users;
use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;

class UsersDetails {

	protected $table_name = "users_details";
	protected $database;
	protected $logger;
	protected $Helpers;

	public function __construct(
		Medoo $database,
		Logger $logger,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Helpers = $Helpers;

		$this->logger->addInfo("==> INFO: SIMON\Users\UsersDetails constructed");
	}

	/**
	 * [getUsersDetailsByUserId description]
	 * @param  [int] $user_id [description]
	 * @return [type]          [description]
	 */
	public function getUsersDetailsByUserId($user_id) {
		$columns = "*";
		$conditions = [
			'uid' => $user_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);
		if ($details !== false) {
			$details["account_roles"] = $this->generateUserRoles($details);
		}

		return ($details);
	}

	/**
	 * // 1 - Global Administrator / 2 - User / 3 - Organization Administrator / 4 - Organization User
	 * @param  [type] $account_details [description]
	 * @return [type]                  [description]
	 */
	public function generateUserRoles($account_details) {
		$account_roles = [];

		$account_type = (int) $account_details["account_type"];

		if ($account_type === 3) {
			array_push($account_roles, 3);
			array_push($account_roles, 4);
		} else {
			array_push($account_roles, $account_type);
		}
		/*
			if ($this->Helpers->endsWith($account_details["email"], "genular.com") === true) {
				array_push($account_roles, 1);
			}
		*/
		return $account_roles;
	}
}
