<?php

/**
 * @Author: LogIN-
 * @Date:   2019-01-22 10:27:46
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-31 13:09:09
 */
use Slim\Http\Request;
use Slim\Http\Response;

$app->post('/backend/user/login', function (Request $request, Response $response, array $args) {
	$success = false;
	$authToken = false;

	$controller = $this->get('SIMON\Users\Users');
	$post = $request->getParsedBody();

	if (isset($post['username']) && isset($post['password'])) {
		$username = $post['username'];
		$password = $post['password'];
		$authToken = $controller->login($username, $password);
	}

	if ($authToken !== false) {
		$success = true;
	}
	return $response->withJson(["success" => $success, "auth_token" => $authToken]);

});

$app->post('/backend/user/logout', function (Request $request, Response $response, array $args) {
	$success = false;
	$controller = $this->get('SIMON\Users\Users');

	$user_details = $request->getAttribute('user');
	if (is_array($user_details)) {
		$user_logout = $controller->logout($user_details['user_id'], $user_details['session_id'], true);
	}

	return $response->withJson(["success" => $success]);

});

$app->get('/backend/user/details', function (Request $request, Response $response, array $args) {
	$success = true;

	// 1 - Global Administrator / 2 - User / 3 - Organization Administrator / 4 - Organization User
	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	// TODO
	$account_roles = $user_id;

	return $response->withJson(["success" => $success, "account_roles" => [2]]);

});

$app->post('/backend/user/register', function (Request $request, Response $response, array $args) {
	$success = true;
	// Check if system is properly initialized
	$sysInit = false;

	$message = [];

	$users = $this->get('SIMON\Users\Users');
	$config = $this->get('Noodlehaus\Config');
	$system = $this->get('SIMON\System\System');

	// Lets try to reset all data if there are no users registered in database!
	$totalUsersRegistered = $users->countTotalUsers();
	if ($totalUsersRegistered < 1) {
		/** Empty all database tables */
		$system->reset();
		/** Initialize measurement variables */
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
				$user_id = $users->register($username, $password, $email, $firstName, $lastName, $phoneNumber, $org_invite_code, $validation_hash, $account_type);

				$post["user"]["user_id"] = $user_id;
			}
		}
	}

	if ($user_id === null) {
		$success = false;
	} else {
		// array_push($message, "User successfully registered");
	}

	// If user is successfully registered send verification email
	if ($success !== false && $validation_hash !== null) {
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

	return $response->withJson(["success" => $success, "message" => $message]);
});

$app->get('/backend/user/verify/{validation_hash:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];

	$config = $this->get('Noodlehaus\Config');
	$redirectURL = $config->get('default.frontend.server.url');

	$validation_hash = $args['validation_hash'];
	if (strlen($validation_hash) === 32) {
		$controller = $this->get('SIMON\Users\Users');
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
