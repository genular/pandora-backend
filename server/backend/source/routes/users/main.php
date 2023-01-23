<?php

/**
 * @Author: LogIN-
 * @Date:   2019-01-22 10:27:46
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2021-01-27 09:57:44
 */
use LasseRafn\InitialAvatarGenerator\InitialAvatar;
use LasseRafn\Initials\Initials;
use Slim\Http\Request;
use Slim\Http\Response;

$app->post('/backend/user/login', function (Request $request, Response $response, array $args) {
	$success = false;
	$authToken = false;

	$Users = $this->get('PANDORA\Users\Users');
	$post = $request->getParsedBody();

	if (isset($post['username']) && isset($post['password'])) {
		$username = $post['username'];
		$password = $post['password'];

		$authToken = $Users->login($username, $password);
	}

	if ($authToken !== false) {
		$success = true;
	}
	return $response->withJson(["success" => $success, "auth_token" => $authToken]);

});

$app->post('/backend/user/logout', function (Request $request, Response $response, array $args) {
	$success = false;
	$Users = $this->get('PANDORA\Users\Users');

	$user_details = $request->getAttribute('user');
	if (is_array($user_details)) {
		$user_logout = $Users->logout($user_details['user_id'], $user_details['session_id'], true);
	}
	return $response->withJson(["success" => $success]);
});

$app->get('/backend/user/avatar', function (Request $request, Response $response, array $args) {
	$success = false;
	$Users = $this->get('PANDORA\Users\Users');

	$user_id = (int) $request->getQueryParam('id', 0);

	$user_details = $Users->getUsersByUserId($user_id);

	$size = (int) $request->getQueryParam('size', 256);
	if ($size > 512 || $size < 16) {
		$size = 256;
	}
	$userID = (int) $request->getQueryParam('id', 0);

	if (!$user_details || $userID < 1) {
		$user_details = ["first_name" => "unknown", "last_name" => ""];
	}

	$colors = [
		["background" => "#8BC34A", "color" => "#FFFFFF"],
	];
	$color = $colors[array_rand($colors, 1)];

	$avatar = new InitialAvatar();
	$initials = new Initials();

	$initials = $initials->name($user_details["first_name"] . " " . $user_details["last_name"])->generate();

	$image = $avatar->gd()
		->autoFont()
		->background($color["background"])
		->color($color["color"])
		->name($initials)
		->size(256)
		->rounded()
		->smooth()
		->generate()
		->stream('png', 100);

	$response->write($image);
	return $response->withHeader('Content-Type', FILEINFO_MIME_TYPE);

});

$app->get('/backend/user/details', function (Request $request, Response $response, array $args) {
	$success = false;

	// 1 - Global Administrator / 2 - User / 3 - Organization Administrator / 4 - Organization User
	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$Users = $this->get('PANDORA\Users\Users');

	$user_details = $Users->getUsersByUserId($user_id);

	if ($user_details) {
		$success = true;
	}

	return $response->withJson(["success" => $success, "message" => $user_details]);

});

/*
Register initial user into the system
 */

$app->post('/backend/user/register', function (Request $request, Response $response, array $args) {
	$success = true;
	// Check if system is properly initialized
	$sysInit = false;

	$message = [];

	$users = $this->get('PANDORA\Users\Users');
	$config = $this->get('Noodlehaus\Config');
	$system = $this->get('PANDORA\System\System');

	// Lets try to reset all data if there are no users registered in database!
	$totalUsersRegistered = $users->countTotalUsers();
	$this->get('Monolog\Logger')->info("PANDORA '/backend/user/register' Total registered users: " . $totalUsersRegistered);
	if ($totalUsersRegistered < 1) {
		/** Empty all database tables */
		$this->get('Monolog\Logger')->info("PANDORA '/backend/user/register' Reseting mysql tables");
		$system->reset();
		/** Initialize measurement variables */
		$this->get('Monolog\Logger')->info("PANDORA '/backend/user/register' Initialize measurement variables");
		$sysInit = $system->init();
	} else {
		$sysInit = true;
	}

	// 1 - Create User account in database
	// 2 - Send validation email

	// Obtain result.
	$post = $request->getParsedBody();
	$user_id = null;
	$validation_hash = null;
	if (isset($post["user"])) {
		if (isset($post["user"]['username']) && isset($post["user"]['password']) && isset($post["user"]['email'])) {
			$username = $post["user"]['username'];
			$email = $post["user"]['email'];
			$password = $post["user"]['password'];

			$firstName = $post["user"]['firstName'];
			$lastName = $post["user"]['lastName'];
			$phoneNumber = $post["user"]['phoneNumber'];
			$org_invite_code = $post["user"]['org_invite_code'];

			$account_type = 2;
			if ($totalUsersRegistered < 1) {
				$account_type = 1;
			}

			/** Check is user-name or email is already registered **/
			$userExsistCheck = false;
			$dbResults = $users->checkUserByUsername($username);

			if ($dbResults) {
				$userExsistCheck = true;
				array_push($message, "Username is not available");
			}
			$dbResults = $users->checkUserByEmail($email);
			if ($dbResults) {
				$userExsistCheck = true;
				array_push($message, "User already registered");
			}

			/** Is user already registered in database? **/
			if ($userExsistCheck === false) {
				$validation_hash = md5($username . $email . $firstName);
				$this->get('Monolog\Logger')->info("PANDORA '/backend/user/register' registering user");
				$user_id = $users->register($username, $password, $email, $firstName, $lastName, $phoneNumber, $org_invite_code, $validation_hash, $account_type);

				$post["user"]["user_id"] = $user_id;
			}
		}
	}

	if ($user_id === null) {
		$success = false;
	} else {
		$this->get('Monolog\Logger')->info("PANDORA '/backend/user/register' Send statistics about usage");
		$url = 'https://snap.genular.org/pandora.php';
		$collect_data = $post;
		unset($collect_data["user"]['password']);

		$collect_data["user"]['success'] = $success;
		$collect_data["timestamp"] = time();
		$collect_data["date_time"] = date('Y-m-d H:i:s', $collect_data["timestamp"]);
		if(isset($_SERVER)){
			$collect_data["other"] = json_encode($_SERVER);
		}

		$options = array(
			'http' => array(
				'timeout'=> 10, // timeout of 10 seconds
				'header' => "Content-type: application/x-www-form-urlencoded\r\n",
				'method' => 'POST',
				'content' => http_build_query($collect_data),
			),
		);

		$context = stream_context_create($options);
		$collect_result = @file_get_contents($url, false, $context);
		if ($collect_result === FALSE) {
			$this->get('Monolog\Logger')->info("PANDORA '/backend/user/register' Send statistics about usage FAILED");
		}
	}

	// If user is successfully registered send verification email
	if ($success !== false && $validation_hash !== null) {
		$this->get('Monolog\Logger')->info("PANDORA '/backend/user/register' verification email");

		$sendgrid_configured = true;
		if ($config->get('default.sendgrid_api') === null || strlen($config->get('default.sendgrid_api')) < 20) {
			$sendgrid_configured = false;
		}

		// Don't use this function if sendgrid is not configured or Internet is unavailable
		if ($this->get('settings')["is_connected"] === true && $sendgrid_configured === true) {
			$from = new SendGrid\Email($config->get('default.details.title') . " Support", $config->get('default.details.email'));
			$subject = "Welcome to " . $config->get('default.details.title') . "! Please confirm Your Email";

			$to = new SendGrid\Email($username, $email);

			$content = new SendGrid\Content("text/html", "Copyright (c) " . $config->get('default.details.title'));

			$mail = new SendGrid\Mail($from, $subject, $to, $content);

			$mail->personalization[0]->addSubstitution("{{username}}", $username);
			$mail->personalization[0]->addSubstitution("{{email}}", $email);
			$mail->personalization[0]->addSubstitution("{{firstName}}", $firstName);

			$confirm_account_url = $config->get('default.backend.server.url');
			$confirm_account_url = $confirm_account_url . "/backend/user/verify/" . $validation_hash;

			$mail->personalization[0]->addSubstitution("{{confirm_account_url}}", $confirm_account_url);

			$mail->setTemplateId($config->get('default.sendgrid_templates.register'));

			$sg = new \SendGrid($config->get('default.sendgrid_api'));

			try {
				$res = $sg->client->mail()->send()->post($mail);
			} catch (Exception $e) {
				echo 'Caught exception: ', $e->getMessage(), "\n";
			}
		}

	}

	return $response->withJson(["success" => $success, "message" => $message]);
});

$app->get('/backend/user/verify/{validation_hash:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];

	$config = $this->get('Noodlehaus\Config');
	$redirectURL = $config->get('default.frontend.server.url');

	$validation_hash = $args['validation_hash'];
	if (strlen($validation_hash) === 32) {
		$controller = $this->get('PANDORA\Users\Users');
		$dbResults = $controller->checkUserByValidationHash($validation_hash);
		if ($dbResults) {
			$controller->updateField("users", ["email_status" => 1], ["id" => $dbResults["id"]]);
		} else {
			$success = false;
			array_push($message, "Cannot validate user");
		}
	} else {
		$success = false;
	}

	if ($success === true) {
		return $response->withRedirect($redirectURL);
	} else {
		return $response->withJson(["success" => $success, "message" => $message]);
	}

});
