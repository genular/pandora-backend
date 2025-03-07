<?php
use Slim\Http\Request;
use Slim\Http\Response;


$app->post('/backend/user/password-reset', function (Request $request, Response $response, array $args) {
    /** @var \PANDORA\Users\Users $Users */
    $Users = $this->get('PANDORA\Users\Users');

    // Initialize response flags
    $success = false;
    $message = "Invalid input data.";

    // Parse the POST body
    $post = $request->getParsedBody();
    if (isset($post['email'], $post['password'], $post['registration_key'])) {
        $email             = $post['email'];
        $newPassword       = $post['password'];
        $registration_key  = $post['registration_key'];

        // Call resetPassword
        $result = $Users->resetPassword($email, $newPassword, $registration_key);
        if ($result) {
            $success = true;
            $message = "Password updated successfully.";
        } else {
            $message = "Could not reset password. Invalid email or registration key.";
        }
    }

    // Return JSON
    return $response->withJson([
        "success" => $success,
        "message" => $message
    ]);
});

/**
 * Updates parts of the user profile.
 * 
 * This route allows users to update their first name, last name, phone number, and OpenAI API key.
 * The request is authenticated, and user details are updated based on their ID.
 *
 * @param Request  $request  Slim's HTTP request object.
 * @param Response $response Slim's HTTP response object.
 * @param array    $args     Route parameters as an associative array (unused in this function).
 *
 * @return Response Returns a JSON response indicating the success status of the update operation.
 */
$app->post('/backend/user/update-profile', function (Request $request, Response $response, array $args) {
    $user_details = $request->getAttribute('user');
    $user_id = $user_details['user_id'];

    $Users = $this->get('PANDORA\Users\Users');
    $post = $request->getParsedBody();

    // Call the new updateUserProfile method
    $result = $Users->updateUserProfile($user_id, $post);

    $success = $result->rowCount() > 0;
    $message = $success ? "Profile updated successfully." : "No changes made or update failed.";

    return $response->withJson(["success" => $success, "message" => $message]);
});


/**
 * Handles user login requests.
 * 
 * This route is responsible for processing login requests by checking the provided 
 * username and password against the database. If authentication is successful, it 
 * returns a JSON response including a success flag and an authentication token.
 *
 * @param Request  $request  Slim's HTTP request object.
 * @param Response $response Slim's HTTP response object.
 * @param array    $args     Route parameters as an associative array.
 *
 * @return Response Returns a JSON response containing the authentication status and token.
 */
$app->post('/backend/user/login', function (Request $request, Response $response, array $args) {
    // Flag to indicate success status
    $success = false;
    // Variable to hold the authentication token, false if authentication fails
    $authToken = false;

    // Access the Users class from the dependency container
    $Users = $this->get('PANDORA\Users\Users');
    // Retrieve the parsed body of the request as an associative array
    $post = $request->getParsedBody();

    // Check if both username and password are provided
    if (isset($post['username']) && isset($post['password'])) {
        $username = $post['username'];
        $password = $post['password'];

        // Attempt to login with the provided credentials
        $authToken = $Users->login($username, $password);
    }

    // Update success flag if an auth token was received
    if ($authToken !== false) {
        $success = true;
    }

    // Return a JSON response with the authentication status and token
    return $response->withJson(["success" => $success, "auth_token" => $authToken]);
});

/**
 * Handles user logout requests.
 * 
 * This route is responsible for processing logout requests by using details
 * from the user's session. It invokes the logout method of the Users class,
 * which is expected to handle session termination and any necessary cleanup.
 *
 * @param Request  $request  Slim's HTTP request object, used to access user details.
 * @param Response $response Slim's HTTP response object, used to send back a JSON response.
 * @param array    $args     Additional route parameters (unused in this function).
 *
 * @return Response Returns a JSON response indicating the success status of the logout operation.
 */
$app->post('/backend/user/logout', function (Request $request, Response $response, array $args) {
    // Initialize success flag to false.
    $success = false;

    // Access the Users class from the dependency container.
    $Users = $this->get('PANDORA\Users\Users');

    // Retrieve user details added to the request, usually by a middleware.
    $user_details = $request->getAttribute('user');

    // Ensure user details are provided and in the expected array format.
    if (is_array($user_details)) {
        // Attempt to log the user out using their ID and session ID.
        // The third parameter 'true' might indicate a specific logout behavior, such as clearing session data.
        // It's assumed $Users->logout() updates $success internally or returns a boolean to indicate success.
        $user_logout = $Users->logout($user_details['user_id'], $user_details['session_id'], true);

        // If logout is successful, update the success flag.
        // Assuming $Users->logout() returns a boolean indicating the success of the operation.
        if ($user_logout) {
            $success = true;
        }
    }

    // Return a JSON response with the success status.
    // Initially, success is always false regardless of the logout operation's outcome.
    // To reflect the actual outcome, $success should be set based on the logout method's return value.
    return $response->withJson(["success" => $success]);
});


/**
 * Generates and returns a user avatar based on their initials.
 * 
 * This route generates a simple avatar image with a colored background and the user's initials.
 * The size of the avatar can be specified via the 'size' query parameter. The background and
 * text colors are selected randomly from a predefined set.
 *
 * @param Request  $request  Slim's HTTP request object, used to access query parameters.
 * @param Response $response Slim's HTTP response object, used to send back the generated image.
 * @param array    $args     Additional route parameters (unused in this function).
 *
 * @return Response Returns the generated image as a PNG with the appropriate Content-Type header.
 */
$app->get('/backend/user/avatar', function (Request $request, Response $response, array $args) {
    // Path to the default avatar icon
    $avatarPath = __DIR__ . '/../../../public/assets/avatar_icon.png';

    // Check if the avatar file exists
    if (!file_exists($avatarPath)) {
        return $response->withStatus(404)->write('Avatar icon not found.');
    }

    // Retrieve and validate the avatar size from the query parameters.
    $size = (int) $request->getQueryParam('size', 256);
    if ($size > 512 || $size < 16) {
        $size = 256; // Reset to default size if the specified size is out of bounds.
    }

    // Load the avatar image
    $image = imagecreatefrompng($avatarPath);

    // Get the original image dimensions
    $originalWidth = imagesx($image);
    $originalHeight = imagesy($image);

    // Create a new blank image with the specified size
    $resizedImage = imagecreatetruecolor($size, $size);
    imagesavealpha($resizedImage, true);
    $transparent = imagecolorallocatealpha($resizedImage, 0, 0, 0, 127);
    imagefill($resizedImage, 0, 0, $transparent);

    // Resize the avatar icon to the specified dimensions
    imagecopyresampled($resizedImage, $image, 0, 0, 0, 0, $size, $size, $originalWidth, $originalHeight);

    // Capture the resized image data
    ob_start();
    imagepng($resizedImage);
    $data = ob_get_contents();
    ob_end_clean();

    // Cleanup: destroy the image resources to free memory
    imagedestroy($image);
    imagedestroy($resizedImage);

    // Write the image data to the response body and set the content type
    $response->getBody()->write($data);
    return $response->withHeader('Content-Type', 'image/png');
});


/**
 * Fetches and returns details for a specific user.
 * 
 * This route retrieves detailed information about a user based on the user ID extracted
 * from the request's attributes. This user ID is typically set by a prior authentication
 * middleware. It supports different user roles, including Global Administrator, User,
 * Organization Administrator, and Organization User.
 *
 * @param Request  $request  Slim's HTTP request object, containing user attributes.
 * @param Response $response Slim's HTTP response object for sending back the user details.
 * @param array    $args     Route parameters (unused in this function).
 *
 * @return Response A JSON response containing a success flag and the user's details or a message.
 */
$app->get('/backend/user/details', function (Request $request, Response $response, array $args) {
    // Initialize success flag to false.
    $success = false;

    // Extract user details from request attributes, typically set by authentication middleware.
    $user_details = $request->getAttribute('user');
    $user_id = $user_details['user_id'];

    // Access the Users class from the dependency container.
    $Users = $this->get('PANDORA\Users\Users');

    // Fetch user details from the database or user management service.
    $user_details = $Users->getUsersByUserId($user_id);

    // Check if user details were successfully retrieved.
    if ($user_details) {
        $success = true;
    }

    // Return the user details along with the success flag in a JSON response.
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
			$registration_key = $post["user"]['registration_key'];

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
				$user_id = $users->register($username, $password, $email, $firstName, $lastName, $phoneNumber, $registration_key, $validation_hash, $account_type);

				$post["user"]["user_id"] = $user_id;
			}
		}
	}

	if ($user_id === null) {
		$success = false;
	}

	return $response->withJson(["success" => $success, "message" => $message]);
});

/**
 * Verifies a user's email or account based on a validation hash.
 * 
 * This route is responsible for verifying a user's email or account by matching a provided
 * validation hash against records in the database. If the hash is valid and corresponds to a
 * user, the user's email status is updated to indicate verification. Success or failure is
 * communicated via a redirect for success or a JSON response for failure.
 *
 * @param Request  $request  Slim's HTTP request object, contains the validation hash as part of the route.
 * @param Response $response Slim's HTTP response object, used for redirecting or returning JSON data.
 * @param array    $args     Route parameters, including the 'validation_hash' obtained from the URL.
 *
 * @return Response Depending on the outcome, either redirects the user to a predefined URL or returns a JSON response with success status and message.
 */
$app->get('/backend/user/verify/{validation_hash:.*}', function (Request $request, Response $response, array $args) {
    // Default to a successful operation
    $success = true;
    // Initialize an empty message array to store potential error messages
    $message = [];

    // Retrieve configuration settings (e.g., for redirect URL)
    $config = $this->get('Noodlehaus\Config');
    // Get the redirect URL from the configuration
    $redirectURL = $config->get('default.frontend.server.url');

    // Extract the validation hash from the route parameters
    $validation_hash = $args['validation_hash'];

    // Validate the format of the validation hash (e.g., length check for MD5)
    if (strlen($validation_hash) === 32) {
        // Access the Users controller from the dependency container
        $controller = $this->get('PANDORA\Users\Users');
        // Check if the validation hash corresponds to a user
        $dbResults = $controller->checkUserByValidationHash($validation_hash);
        
        if ($dbResults) {
            // If a matching user is found, update their email status to verified
            $controller->updateField("users", ["email_status" => 1], ["id" => $dbResults["id"]]);
        } else {
            // Set success to false and add an error message if the hash is invalid
            $success = false;
            array_push($message, "Cannot validate user");
        }
    } else {
        // Set success to false if the hash does not meet the expected criteria
        $success = false;
    }

    // Redirect to a predefined URL on successful verification
    if ($success === true) {
        return $response->withRedirect($redirectURL);
    } else {
        // Return a JSON response with success status and error message(s) on failure
        return $response->withJson(["success" => $success, "message" => $message]);
    }
});
