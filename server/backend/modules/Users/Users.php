<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-24 10:32:23
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

	public function countTotalUsers() {
		$count = $this->database->count("users");
		return $count;
	}

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
	 */
	public function logout($user_id, $session_id, $specific = true) {
		if ($specific === true) {
			$data = $this->database->delete("users_sessions", [
				"AND" => [
					"uid" => $user_id,
					"session" => $session_id,
				],
			]);
		} else {
			$data = $this->database->delete("users_sessions", [
				"AND" => [
					"uid" => $user_id,
				],
			]);
		}
		return $data->rowCount();
	}

	/** Register user in database **/
	public function register($username, $password, $email_adress, $firstName, $lastName, $phoneNumber, $org_invite_code, $validation_hash) {
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
		// 2 - User
		$account_type = 2;

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
		$columns = "*";
		$conditions = [
			'id' => $user_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);

		return ($details);
	}
	/**
	 *
	 */
	public function getUsersByCBSubscriptionId($cb_subscription_id) {
		$columns = "*";
		$conditions = [
			'cb_subscription_id' => $cb_subscription_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);

		return ($details);
	}
	/**
	 *
	 */
	public function getUsersByCBUserId($cb_user_id) {
		$columns = "*";
		$conditions = [
			'cb_user_id' => $cb_user_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);

		return ($details);
	}
	/**
	 * Check if User Email is in database or not
	 *
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
	 *
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
	 *
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
	 *
	 */
	public function updateField($table = "users", $data = ["email_status" => null], $where = ["id" => null]) {
		$check = $this->database->update($table, $data, $where);
		return $check;
	}
}
