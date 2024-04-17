<?php

use Slim\Http\Request;
use Slim\Http\Response;

/**
 * Index page
 */
$app->get('/', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("PANDORA '/' route");
	// Render index view
	return $this->get('Slim\Views\PhpRenderer')->render($response, 'index.phtml', $args);
});

/**
 * Retrieves server configuration details based on the application's current settings.
 *
 * This endpoint is designed to provide an overview of the server configurations as defined in the application's settings.
 * It extracts and returns details about various server components configured in the system. Access to this information
 * requires a secret for security purposes, ensuring that only authorized requests receive configuration data.
 *
 * Note: Logging is performed upon route access to monitor usage and ensure authorized access.
 *
 * @param Request  $request  Slim's request object, encapsulating all the request-specific information.
 * @param Response $response Slim's response object, used to construct and return the response.
 * @param array    $args     Route parameters, including the 'secret' provided in the URL path.
 *
 * @return Response JSON response containing a 'success' boolean indicating whether the request was authorized,
 * along with a 'servers' array detailing the server configurations. The 'servers' array includes each server's type
 * and URL based on the application's configuration settings.
 */
$app->get('/backend/system/status/{secret:.*}', function (Request $request, Response $response, array $args) {
    $this->get('Monolog\Logger')->info("PANDORA '/system/status/{secret:.*}' route");

    $status = 301;
    $success = false;

    $system = $this->get('PANDORA\System\System');
    $config = $this->get('Noodlehaus\Config');

    $configData = $config->all();
    $server_details = [];

    foreach ($configData["default"] as $configItemKey => $configItemValue) {
        if (is_array($configItemValue) && isset($configItemValue["server"])) {
            if (isset($configItemValue["server"]["url"])) {
                $server_details[] = [
                    "type" => $configItemKey,
                    "url" => $configItemValue["server"]["url"],
                ];
            }
        }
    }

    if (count($server_details) >= 4) {
        $success = true;
        $status = 200; // Ensure to set the correct status for a successful response
    }

    return $response->withJson(["success" => $success, "servers" => $server_details])->withStatus($status);
});


/**
 * Initializes the system with predefined configurations if the correct secret is provided.
 *
 * This endpoint serves as a trigger for system initialization processes, which may include setting up default configurations, 
 * database migrations, or other bootstrap operations necessary for the application to function correctly. Due to its sensitive nature,
 * this operation requires a secret passed in the URL, which is compared against a system-stored secret to ensure authorization.
 *
 * Security Note: This endpoint should be protected and only accessible by authorized personnel or systems, as it can significantly 
 * affect the application's state and operation.
 *
 * @param Request  $request  Slim's request object, providing access to request parameters, headers, and body.
 * @param Response $response Slim's response object, used to build and return the response to the client.
 * @param array    $args     Route parameters, including the 'secret' provided in the URL path.
 *
 * @return Response The response is a JSON object containing a 'success' boolean field indicating whether the initialization was successful.
 */
$app->get('/init/{secret:.*}', function (Request $request, Response $response, array $args) {
	$status = 301;
	$success = false;

	$config = $this->get('Noodlehaus\Config');
	$systemSecret = $config->get('default.secret');

	$requestSecret = $args['secret'];
	if (strcmp($systemSecret, $requestSecret) == 0) {
		$system = $this->get('PANDORA\System\System');
		$system->init();
		// $system->scrapeHelpDocumentation();
		$status = 200;
		$success = true;
	}

	$response->getBody()->write(json_encode(["success" => $success]));
	return $response->withStatus($status);
});

/**
 * Retrieves the current server load information.
 *
 * This endpoint is designed to provide administrative insight into the server's current load,
 * facilitating monitoring and management operations. It utilizes the 'PANDORA\System\System' service
 * to fetch the server load details, which typically include CPU usage, memory usage, and possibly other
 * metrics depending on the system's implementation.
 *
 * @param Request  $request  Slim's request object, encapsulating all the request-specific information.
 * @param Response $response Slim's response object, used to construct and return the response.
 * @param array    $args     Any arguments passed to the route; not used in this route but required by the signature.
 *
 * @return Response The response is a JSON object containing a 'success' key indicating the operation's success
 * (always true in this implementation) and a 'message' key with the server load information.
 */
$app->get('/backend/system/serverload', function (Request $request, Response $response, array $args) {
	$success = true;

	$system = $this->get('PANDORA\System\System');
	$server_load = $system->getServerLoadInfo();

	return $response->withJson(["success" => $success, "message" => $server_load]);
});

/**
 * Handles a request to reset system settings to default values.
 *
 * This endpoint requires a secret to be passed as part of the URL. The secret is compared
 * with a system-defined secret. If they match, the system settings are reset to their
 * default values. This operation is intended for administrative use and should be protected
 * or limited to certain users.
 *
 * @param Request  $request  Slim's request object, providing access to request parameters, headers, and body.
 * @param Response $response Slim's response object, used to build and return the response to the client.
 * @param array    $args     Route parameters, including the 'secret' provided in the URL path.
 *
 * @return Response Returns a JSON response indicating the success status of the reset operation.
 * The response contains a boolean 'success' field. It also sets the HTTP status code to 200 on success,
 * or 301 if the provided secret does not match the system's secret.
 *
 * @throws Exception If there's an issue accessing the system settings or performing the reset,
 * an exception may be thrown. [This line is optional and should be included only if your method actually
 * can throw exceptions that are not internally caught.]
 */
$app->get('/reset/{secret:.*}', function (Request $request, Response $response, array $args) {
	$status = 301;
	$success = false;
	$config = $this->get('Noodlehaus\Config');
	$systemSecret = $config->get('default.secret');

	$userSecret = $args['secret'];
	if (strcmp($systemSecret, $userSecret) == 0) {
		$system = $this->get('PANDORA\System\System');
		$system->reset();
		$status = 200;
		$success = true;
	}

	$response->getBody()->write(json_encode(["success" => $success]));
	return $response->withStatus($status);
});

/**
 * Fetches and filters log content by CRON task segments and optional queueID or resampleID.
 * 
 * This route reads the log file to identify segments corresponding to individual CRON tasks,
 * then optionally filters these segments based on the presence of a specified queueID or resampleID.
 * It enables efficient log analysis by organizing log entries into discrete tasks and allowing
 * detailed filtering, making it easier for users to find relevant log information.
 *
 * @param \Psr\Http\Message\ServerRequestInterface $request  PSR-7 request object, containing query params.
 * @param \Psr\Http\Message\ResponseInterface      $response PSR-7 response object for returning JSON data.
 * @param array                                   $args     Route parameters as an associative array.
 *
 * @return \Psr\Http\Message\ResponseInterface Returns a JSON response containing the filtered log segments.
 */
$app->get('/backend/system/get-log', function ($request, $response, $args) {
    $logFilePath = '/var/log/pandora-cron.log';
    $queryParams = $request->getQueryParams(); // Extract query parameters

    $queueID = $queryParams['queueID'] ?? null;
    $resampleID = $queryParams['resampleID'] ?? null;

    if (file_exists($logFilePath) && is_readable($logFilePath)) {
        $file = new SplFileObject($logFilePath, 'r');
        $file->seek(PHP_INT_MAX);
        $lastLine = $file->key();
        $cronTasks = [];
        $currentTaskLogs = [];

        while ($lastLine >= 0) {
            $file->seek($lastLine);
            $line = $file->current();
            $lastLine--;

            if (strpos($line, "======> INFO: Initializing CRON. Working directory") !== false) {
                // Prepend the current task logs to the cronTasks array and reset currentTaskLogs
                if (!empty($currentTaskLogs)) {
                    array_unshift($cronTasks, array_reverse($currentTaskLogs));
                    $currentTaskLogs = [];
                }
            }

            $currentTaskLogs[] = $line;
        }

        // Add the last task logs if any
        if (!empty($currentTaskLogs)) {
            array_unshift($cronTasks, array_reverse($currentTaskLogs));
        }

        // If queueID or resampleID is set, filter the cronTasks array
        if ($queueID !== null || $resampleID !== null) {
            $cronTasks = array_filter($cronTasks, function($taskLogs) use ($queueID, $resampleID) {
                foreach ($taskLogs as $logLine) {
                    if (($queueID !== null && strpos($logLine, "queueID: $queueID") !== false) ||
                        ($resampleID !== null && strpos($logLine, "resampleID: $resampleID") !== false)) {
                        return true;
                    }
                }
                return false;
            });
        }

        // Flatten the filtered cronTasks array to a string
        $filteredLogs = array_reduce($cronTasks, function($carry, $taskLogs) {
            return $carry .= implode("\n", $taskLogs) . "\n";
        }, '');

        return $response->withJson([
            'success' => true,
            'log' => $filteredLogs
        ]);
    } else {
        return $response->withJson([
            'success' => false,
            'message' => 'Log file not found or not readable.'
        ], 404);
    }
});


/**
 * Processes AI descriptions based on submitted data.
 *
 * This endpoint receives data for AI processing, decodes and interprets it, then utilizes an AI helper
 * to generate a response based on the submitted data. It primarily serves to interface with an AI model,
 * sending it processed user input and returning the AI's response.
 *
 * @param Request  $request  Slim's request object, encapsulating all request information.
 * @param Response $response Slim's response object, used for building and returning the response.
 * @param array    $args     Route parameters as an associative array.
 *
 * @return Response JSON response indicating the success of the operation along with the AI's generated description
 * or an error message. The response format is: {"success": bool, "message": mixed}, where `message` contains the AI
 * response on success or an error message on failure.
 *
 * @throws Exception If there are issues in decoding the submitted data or in AI processing, an exception may be thrown
 * and should be caught by Slim's error handling mechanisms.
 */
$app->post('/backend/system/describe_ai', function (Request $request, Response $response, array $args) {
    $success = true;

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$Users = $this->get('PANDORA\Users\Users');
	$user_details = $Users->getUsersByUserId($user_id);


	$post = $request->getParsedBody();
	
    if (isset($post['submitData'])) {
        $submitData = json_decode(base64_decode(urldecode($post['submitData'])), true);
    }

	// $prompt = EOF
	// 	I have conducted a series of machine learning experiments to address a supervised classification task. I employed various different ML models.
	// 	Please provide a summary all this results combined, in JSON format with a one and only text key "summary" highlighting any significant observations regarding performance or applicability. In short write me an short overview if we made any good model or not!
	// EOF;

    $LLM_AI = $this->get('PANDORA\Helpers\LLM_AI');
    $response = $LLM_AI->get($submitData, $user_details['openai_api']);

    if($response === false){
		$success = false;
	}

    return $response->withJson(["success" => $success, "message" => $response]);
});

/**
 * Handles the system update process.
 *
 * This endpoint initiates a series of actions to update the system's backend and frontend components.
 * It performs a 'git pull' operation on both frontend and backend repositories to synchronize them with their
 * respective remote versions. Additionally, it runs 'composer install' and its post-install script in the backend,
 * and executes 'yarn build' for the frontend to compile and prepare it for production.
 * 
 *
 * @param Request  $request  The request object provided by Slim framework, containing request details.
 * @param Response $response The response object used to return data back to the client.
 * @param array    $args     Additional arguments passed to the route.
 *
 * @return Response Returns a JSON response indicating the success or failure of the update operations, 
 * including detailed messages about each step of the process.
 */
$app->get('/backend/system/update', function (Request $request, Response $response, array $args) {
    // Load configuration
    $config = $this->get('Noodlehaus\Config');
    
    // Extract URLs from the config
    $frontendUrl = $config->get('default.frontend.server.url');
    $backendUrl = $config->get('default.backend.server.url');


    // Check if running in a Docker container
    $isDocker = $this->get('settings')["is_docker"];
    $userToExecuteAs = $isDocker ? 'genular' : 'login';

    $assetsPath = __DIR__ . '/../../../public/assets'; // Adjust path as needed to point to your public/assets directory
    $filePath = $assetsPath . '/update.txt';

    // Ensure the directory exists and is writable
    if (!file_exists($assetsPath)) {
        if (!mkdir($assetsPath, 0777, true)) {
            $message = 'Failed to create assets directory.';
            return $response->withJson(["success" => false, "message" => $message]);
        }
    }

    // Write/update URLs in the file
    $fileContent = "FRONTEND_URL=$frontendUrl\nBACKEND_URL=$backendUrl\n";

    if (file_put_contents($filePath, $fileContent) === false) {
        return $response->withJson(["success" => false, "message" => 'Failed to write to the file.']);
    }

    return $response->withJson(["success" => true, "message" => 'Update process initiated.']);
});
