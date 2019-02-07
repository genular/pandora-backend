<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-02-06 11:02:11
 */
namespace SIMON\Users;

use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;
use \SIMON\System\FileSystem as FileSystem;
use \SIMON\Users\UsersApps as UsersApps;
use \SIMON\Users\UsersDetails as UsersDetails;
use \SIMON\Users\UsersOrganization as UsersOrganization;
use \SIMON\Users\UsersSessions as UsersSessions;

class Users {

	protected $table_name = "users";
	protected $database;
	protected $logger;

	protected $Helpers;
	protected $UsersApps;
	protected $UsersDetails;
	protected $UsersOrganization;
	protected $UsersSessions;
	protected $FileSystem;

	public function __construct(
		Medoo $database,
		Logger $logger,
		Helpers $Helpers,
		UsersApps $UsersApps,
		UsersDetails $UsersDetails,
		UsersOrganization $UsersOrganization,
		UsersSessions $UsersSessions,
		FileSystem $FileSystem
	) {
		$this->database = $database;

		$this->logger = $logger;

		$this->Helpers = $Helpers;
		$this->UsersApps = $UsersApps;
		$this->UsersDetails = $UsersDetails;
		$this->UsersOrganization = $UsersOrganization;
		$this->UsersSessions = $UsersSessions;
		$this->FileSystem = $FileSystem;

		$this->logger->addInfo("==> INFO: SIMON\Users constructed");
	}
	/**
	 * Get number of total users in database
	 * @return [int]
	 */
	public function countTotalUsers() {
		$count = $this->database->count("users");
		return $count;
	}

	/**
	 * Logs in user and sets session hash in database
	 * @param  [string] $username [description]
	 * @param  [string] $password [description]
	 * @return [string]
	 */
	public function login($username, $password) {
		$sessionHash = false;
		$saltDetails = $this->getSalt($username);

		if (is_array($saltDetails) > 0) {
			$hashedPassword = hash('sha256', $saltDetails['salt'] . $password);
			$columns = [
				'id',
				'username',
			];
			$conditions = [
				'username' => $username,
				'password' => $hashedPassword,
			];
			$user = $this->database->get('users', $columns, $conditions);

			if ($user) {
				$sessionHash = $this->UsersSessions->getSessionId($user['id']);

				if (!$sessionHash) {
					$sessionHash = $this->UsersSessions->setSessionId($user['id']);
				} else {
					$sessionHash = $sessionHash["session"];
				}
			}
		}
		return $sessionHash;
	}

	/**
	 * Destroy user one or all sessions from database
	 * @param  [int]  $user_id    [description]
	 * @param  [string]  $session_id [description]
	 * @param  boolean $specific   Should we delete only one specific session or all ones
	 * @return [int] Number of affected rows
	 */
	public function logout($user_id, $session_id, $specific = true) {

		$conditions = [
			"uid" => $user_id,
		];

		if ($specific === true) {
			$conditions["session"] = $session_id;
		}

		$data = $this->database->delete("users_sessions", [
			"AND" => $conditions,
		]);

		return $data->rowCount();
	}

	/**
	 * Register user in database
	 * @param  [type] $username        [description]
	 * @param  [type] $password        [description]
	 * @param  [type] $email_adress    [description]
	 * @param  [type] $firstName       [description]
	 * @param  [type] $lastName        [description]
	 * @param  [type] $phoneNumber     [description]
	 * @param  [type] $org_invite_code [description]
	 * @param  [type] $validation_hash [description]
	 * @param  [type] $account_type [description]
	 * @return [int]                   User ID
	 */
	public function register($username, $password, $email_adress, $firstName, $lastName, $phoneNumber, $org_invite_code, $validation_hash, $account_type) {
		$salt = $this->Helpers->generateRandomString(16);
		$hash_password = hash('sha256', $salt . $password);

		$user_id = null;
		$organization_id = null;

		$this->database->insert("users", [
			"username" => $username,
			"password" => $hash_password,
			"salt" => $salt,
			"validation_hash" => $validation_hash,
			"email_status" => 0,
			"created" => Medoo::raw("NOW()"),
			"updated" => Medoo::raw("NOW()"),
		]);
		$user_id = $this->database->id();

		if ($user_id === false || intval($user_id) === 0) {
			$user_id = null;
		}
		$organization_id = false;
		if ($user_id !== null) {
			if (trim($org_invite_code) !== "") {
				$organization_id = $this->database->get("organization", ['id'], ["invite_code" => $org_invite_code]);
				$this->logger->addInfo("User organization code: " . $organization_id);
			}

			if ($organization_id) {
				// 4 - Organization User
				$account_type = 4;
				$this->database->insert("users_organization", [
					"uid" => $user_id,
					"oid" => $organization_id,
					"invite_code" => $org_invite_code,
					"account_type" => $account_type,
					"created" => Medoo::raw("NOW()"),
					"updated" => Medoo::raw("NOW()"),
				]);
				$this->logger->addInfo("User users_organization created: " . $user_id);
			}

			$workspace_directory = $this->FileSystem->initilizeUserWorkspace($user_id);

			$this->database->insert("users_details", [
				"uid" => $user_id,
				"first_name" => $firstName,
				"last_name" => $lastName,
				"email" => $email_adress,
				"phone" => $phoneNumber,
				"profile_picture" => null,
				"workspace_directory" => $workspace_directory,
				"account_type" => $account_type,
				"created" => Medoo::raw("NOW()"),
				"updated" => Medoo::raw("NOW()"),
			]);

			$this->logger->addInfo("User users_details created: " . $user_id);
		} else {
			$this->logger->addInfo("Cannot create user user ID is false");
		}

		return $user_id;
	}

	/**
	 * Get salt for specific user
	 * @param  [type] $username [description]
	 * @return [type]           [description]
	 */
	private function getSalt($username) {
		$columns = [
			'id',
			'salt',
		];
		$conditions = [
			'username' => $username,
		];
		$user = $this->database->get('users', $columns, $conditions);

		return ($user);
	}

	public function getUsersByUserId($user_id) {
		$columns = [
			"users.id [Int]",
			"users.username",
			"users.email_status [Int]",
			"users.created",
			"users_details.first_name",
			"users_details.last_name",
			"users_details.email",
			"users_details.phone",
			"users_details.profile_picture",
			"users_details.account_type [Int]",
			"users_organization.oid [Int]",
		];
		$join = [
			"[>]users_details" => ["users.id" => "uid"],
			"[>]users_organization" => ["users.id" => "uid"],
		];
		$conditions = [
			'users.id' => $user_id,
		];
		$details = $this->database->get($this->table_name, $join, $columns, $conditions);

		return ($details);
	}

	/**
	 * Check if User Email is in database or not
	 * @param  [type] $email_adress [description]
	 * @return [type]               [description]
	 */
	public function checkUserByEmail($email_adress) {
		$columns = [
			'uid',
		];
		$conditions = [
			'email' => $email_adress,
		];

		$uid = $this->database->get('users_details', $columns, $conditions);

		return $uid;
	}

	/**
	 * Check if User Username is in database or not
	 * @param  [type] $username [description]
	 * @return [type]           [description]
	 */
	public function checkUserByUsername($username) {
		$columns = [
			'id',
		];
		$conditions = [
			'username' => $username,
		];
		$id = $this->database->get('users', $columns, $conditions);
		return $id;
	}

	/**
	 * Check if User validation_hash is in database or not
	 * @param  [type] $validation_hash [description]
	 * @return [type]                  [description]
	 */
	public function checkUserByValidationHash($validation_hash) {
		$columns = [
			'id',
		];
		$conditions = [
			'validation_hash' => $validation_hash,
		];

		$id = $this->database->get('users', $columns, $conditions);

		return $id;
	}

	/**
	 * Update User status
	 * @param  string $table [description]
	 * @param  array  $data  [description]
	 * @param  array  $where [description]
	 * @return [type]        [description]
	 */
	public function updateField($table = "users", $data = ["email_status" => null], $where = ["id" => null]) {
		$check = $this->database->update($table, $data, $where);
		return $check;
	}
}
