<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-10-08 11:09:45
 */
namespace SIMON\Users;
use \Medoo\Medoo;
use \Monolog\Logger;

class UsersSessions {
	protected $table_name = "users_sessions";
	protected $database;
	protected $logger;
	public function __construct(
		Medoo $database,
		Logger $logger
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->logger->addInfo("==> INFO: SIMON\Users\UsersSessions constructed");
	}

	public function getUsersSessionsByUserId($user_id) {
		$columns = "*";
		$conditions = [
			'uid' => $user_id,
		];
		$details = $this->database->get($this->table_name, $columns, $conditions);

		return ($details);
	}

	public function getSessionId($userId) {
		$columns = [
			'session',
		];
		$conditions = [
			'uid' => $userId,
		];
		$users_sessions = $this->database->get('users_sessions', $columns, $conditions);
		return ($users_sessions);
	}
	/**
	 * Retrieve user ID from Database by Session ID
	 *
	 */
	public function getUserIdBySessionId($sessionId) {
		$columns = [
			'uid [Int]',
		];
		$conditions = [
			'session' => $sessionId,
		];

		$user_id = $this->database->get('users_sessions', $columns, $conditions);

		return ($user_id);
	}

	public function setSessionId($userId) {
		$random_number = intval("0" . rand(1, 9) . rand(0, 9) . rand(0, 9) . rand(0, 9) . rand(0, 9)); // random(ish) 5 digit int
		$timestamp = microtime(true);

		$sessionHash = hash('sha256', $random_number . $timestamp);

		$this->database->insert("users_sessions", [
			"uid" => $userId,
			"session" => $sessionHash,
			"remote_ip" => "127.0.0.1",
			"created" => Medoo::raw("NOW()"),
		]);

		return ($sessionHash);
	}
}
