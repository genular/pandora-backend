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

    // Get user details from the request attribute
    $user_details = $request->getAttribute('user');
    $user_id = $user_details['user_id'];

    // Fetch user details using the Users service
    $Users = $this->get('PANDORA\Users\Users');
    $user_details = $Users->getUsersByUserId($user_id);

    // Parse the submitted data
    $post = $request->getParsedBody();
    if (isset($post['submitData'])) {
        $submitData = json_decode(base64_decode(urldecode($post['submitData'])), true);
    } else {
        return $response->withJson(["success" => false, "message" => "No data provided."]);
    }

    // Ensure the required fields are present
    if (!isset($submitData['type'], $submitData['value'])) {
        return $response->withJson(["success" => false, "message" => "Missing required fields."]);
    }

    $promptType = $submitData['type'];
    $promptQuery = $submitData['value'];
    $promptImages = $submitData['images'];


    // Fetch the response from the LLM_AI service
    $LLM_AI = $this->get('PANDORA\Helpers\LLM_AI');
    $ai_response = $LLM_AI->get($promptQuery, $promptImages, null, $user_details['llm_api_key']);

    // Check if the response from LLM_AI is valid
    if ($ai_response === false) {
        $success = false;
        $message = "AI response generation failed.";
    } else {
        $message = $ai_response;
    }

    // Return the JSON response
    return $response->withJson(["success" => $success, "message" => $message]);
});


$app->get('/backend/system/check-updates', function (Request $request, Response $response, array $args) {
    // Define base paths relative to __DIR__
    $baseBackendPath = realpath(__DIR__ . '/../../../../../');
    $baseFrontendPath = realpath(__DIR__ . '/../../../../../../pandora');

    // Ensure paths are valid
    if (!$baseBackendPath || !$baseFrontendPath) {
        return $response->withJson(["success" => false, "message" => "Invalid directory structure"]);
    }

    // Set repository paths
    $repos = [
        'Frontend' => $baseFrontendPath,
        'Backend' => $baseBackendPath
    ];

    // Check if running in a Docker container
    $isDocker = $this->get('settings')["is_docker"];
    $userToExecuteAs = $isDocker ? 'genular' : 'login';
    $sudoPrefix = "sudo -u $userToExecuteAs ";

    $updates = [];
    foreach ($repos as $name => $repoPath) {
        if (!is_dir($repoPath . '/.git')) {
            $updates[$name] = ["status" => "error", "message" => "Not a valid Git repository"];
            continue;
        }

        // Change directory to the repository path
        chdir($repoPath);

        // Get the current remote URL for origin
        $remoteUrl = trim(shell_exec($sudoPrefix . 'git remote get-url origin'));
        
        // Convert SSH URL to HTTPS if necessary
        if (strpos($remoteUrl, 'git@github.com:') === 0) {
            $httpsUrl = preg_replace('/^git@github\.com:/', 'https://github.com/', $remoteUrl);
        } else {
            $httpsUrl = $remoteUrl; // Use as-is if already HTTPS
        }

        // Use the HTTPS URL directly in the git fetch command
        $cmd = $sudoPrefix . 'git fetch ' . escapeshellarg($httpsUrl) . ' origin master 2>&1';
        
        // Fetch the latest changes from the remote using HTTPS URL
        exec($cmd, $fetchOutput, $fetchResult);

        $fetchOutputText = implode("\n", $fetchOutput);  // Combine output into a single string

        if ($fetchResult !== 0) {
            $userInfo = posix_getpwuid(posix_geteuid());
            $updates[$name] = [
                "status" => "error",
                "message" => "User: " . $userInfo['name'] . " CMD: ".$cmd." ERROR: $fetchOutputText"
            ];
            continue;
        }

        // Check if local master is behind remote master
        $cmd = $sudoPrefix . 'git rev-list HEAD..origin/master --count';
        $behindCount = intval(trim(shell_exec($cmd)));

        $this->get('Monolog\Logger')->info("PANDORA '/system/check-updates' $name behind count: $behindCount");

        if ($behindCount > 0) {
            $updates[$name] = [
                "status" => "behind",
                "behindBy" => $behindCount,
                "message" => "$name repository is behind by $behindCount commits"
            ];
        } else {
            $updates[$name] = [
                "status" => "up-to-date",
                "message" => "$name repository is up to date"
            ];
        }
    }

    return $response->withJson(["success" => true, "updates" => $updates]);
});


$app->get('/backend/system/update', function (Request $request, Response $response, array $args) {
    // Load configuration
    $config = $this->get('Noodlehaus\Config');

    // Extract URLs from the config
    $frontendUrl = $config->get('default.frontend.server.url');
    $backendUrl = $config->get('default.backend.server.url');

    // Check if running in a Docker container
    $isDocker = $this->get('settings')["is_docker"];
    $userToExecuteAs = $isDocker ? 'genular' : 'login';

    // Define the sudo prefix
    $sudoPrefix = "sudo -u $userToExecuteAs";

    $baseBackendPath = realpath(__DIR__ . '/../../../../../');
    $baseFrontendPath = realpath(__DIR__ . '/../../../../../../pandora');

    $this->get('Monolog\Logger')->info("PANDORA '/system/update' Started");


    // Ensure paths are valid
    if (!$baseBackendPath || !$baseFrontendPath) {
        return $response->withJson([
            "success" => false,
            "message" => "Invalid directory structure"
        ]);
    }

    $updates = [
        'Frontend' => [
            'path' => $baseFrontendPath,
            'success' => "Frontend repository updated successfully.",
            'error' => "Failed to update the frontend repository.",
        ],
        'Backend' => [
            'path' => $baseBackendPath,
            'success' => "Backend repository updated successfully.",
            'error' => "Failed to update the backend repository.",
        ]
    ];

    $successMessages = [];
    $updateStartTime = microtime(true);
    foreach ($updates as $name => &$repo) {

        // Check if the path exists
        if (!is_dir($repo['path'])) {
            return $response->withJson([
                "success" => false,
                "message" => "Path does not exist for $name: {$repo['path']}"
            ]);
        }

        // Change to the repository directory
        if (!chdir($repo['path'])) {
            return $response->withJson([
                "success" => false,
                "message" => "Failed to change directory to {$repo['path']} for $name"
            ]);
        }

        // Reset output and result before getting current branch
        $output = [];
        $result = null;

        // Get the current branch
        $command = "$sudoPrefix git rev-parse --abbrev-ref HEAD 2>&1";
        $this->get('Monolog\Logger')->info("PANDORA '/system/update' Getting current branch for $name: $command");

        // Start timing
        $startTime = microtime(true);
        exec($command, $output, $result);
        $endTime = microtime(true);
        $duration = round($endTime - $startTime, 2); // Duration in seconds

        if ($result !== 0 || empty($output)) {
            $this->get('Monolog\Logger')->error("PANDORA '/system/update' Failed to get current branch for $name. Duration: {$duration}s. Output: " . implode("\n", $output));
            return $response->withJson([
                "success" => false,
                "message" => "Failed to get current branch for $name: " . implode("\n", $output)
            ]);
        }
        $currentBranch = trim($output[0]);
        $this->get('Monolog\Logger')->info("PANDORA '/system/update' Current branch for $name: $currentBranch. Duration: {$duration}s");

        // Build the commands for this repo
        $commands = [
            "$sudoPrefix git checkout .",
            "$sudoPrefix git fetch origin $currentBranch",
            "$sudoPrefix git checkout $currentBranch",
            "$sudoPrefix git pull origin $currentBranch"
        ];

        // Additional commands specific to Frontend or Backend
        if ($name === 'Frontend') {
            $commands = array_merge($commands, [
                "$sudoPrefix yarn install --check-files",
                "$sudoPrefix yarn run webpack:web:prod --isDemoServer=false --server_frontend=$frontendUrl --server_backend=$backendUrl --server_homepage=$frontendUrl"
            ]);
        } elseif ($name === 'Backend' && $isDocker) {
            $phpPath = $isDocker ? '/usr/bin/php8.2' : '/usr/bin/php';

            // Change to the 'server/backend' directory
            $backendSubDir = "{$repo['path']}/server/backend";
            if (!is_dir($backendSubDir)) {
                $this->get('Monolog\Logger')->info("PANDORA '/system/update' Backend subdirectory does not exist: $backendSubDir");
                return $response->withJson([
                    "success" => false,
                    "message" => "Backend subdirectory does not exist: $backendSubDir"
                ]);
            }

            $commands = array_merge($commands, [
                "cd $backendSubDir && $sudoPrefix $phpPath /usr/local/bin/composer install --ignore-platform-reqs",
                "cd $backendSubDir && $sudoPrefix $phpPath /usr/local/bin/composer post-install /tmp/configuration.json"
            ]);
        }

        $this->get('Monolog\Logger')->info("PANDORA '/system/update' Executing commands for: $name");

        // Execute commands
        foreach ($commands as $command) {
            // Reset output and result
            $output = [];
            $result = null;

            $this->get('Monolog\Logger')->info("PANDORA '/system/update' Starting command: $command");

            // Start timing
            $cmdStartTime = microtime(true);
            exec($command, $output, $result);
            $cmdEndTime = microtime(true);
            $cmdDuration = round($cmdEndTime - $cmdStartTime, 2); // Duration in seconds

            if ($result !== 0) {
                $this->get('Monolog\Logger')->error("PANDORA '/system/update' Command failed: $command. Duration (sec): {$cmdDuration}s. Output: " . implode("\n", $output));
                return $response->withJson([
                    "success" => false,
                    "message" => "Error updating $name: Command '$command' failed with output: " . implode("\n", $output)
                ]);
            }

            $this->get('Monolog\Logger')->info("PANDORA '/system/update' Command succeeded: $command. Duration (sec): {$cmdDuration}s");
        }

        // Collect success message
        $successMessages[] = $repo['success'];
    }

    if ($isDocker) {
        $this->get('Monolog\Logger')->info("PANDORA '/system/update' Restarting PM2 processes");

        // Restart PM2 processes with environment updates
        $pm2Command = "sudo -u root pm2 restart all --update-env";
        exec($pm2Command, $pm2Output, $pm2Result);

        // Check for both success indicators: zero exit code OR expected output message
        $pm2OutputString = implode("\n", $pm2Output);
        $pm2Success = ($pm2Result === 0 || strpos($pm2OutputString, "Applying action restartProcessId on app") !== false);

        if (!$pm2Success) {
            $this->get('Monolog\Logger')->error("PANDORA '/system/update' Failed to restart PM2 processes: " . $pm2OutputString);
            return $response->withJson([
                "success" => false,
                "message" => "Failed to restart PM2 processes: " . $pm2OutputString
            ]);
        }

        $this->get('Monolog\Logger')->info("PANDORA '/system/update' PM2 processes restarted successfully.");
    }

    $updateEndTime = microtime(true);
    $updateDuration = round($updateEndTime - $updateStartTime, 2); // Duration in seconds

    // Return success message
    return $response->withJson([
        "success" => true,
        "message" => 'Update process completed successfully in ' . $updateDuration . ' seconds.',
        "details" => $successMessages
    ]);
});



$app->get('/backend/system/live-logs', function (Request $request, Response $response, array $args) {
    $offsets = $request->getQueryParam('offset', []);
    $maxLinesPerLog = 500;  // Limit lines per log to prevent oversized responses

    // Define log sources with file paths or PM2 commands
    $logFiles = [
        "SIMON" => "/var/log/pandora-cron.log",
        "Analysis" => realpath(dirname(__DIR__) . "/../logs/pandora-analysis.log"),
        "Plots" => realpath(dirname(__DIR__) . "/../logs/pandora-plots.log"),
        "API Backend" => realpath(dirname(__DIR__) . "/../logs/pandora.log"),
    ];

    $logs = [];
    foreach ($logFiles as $key => $filePathOrCommand) {
        $logContent = [];

        // Check if the entry is a pm2 command or a log file path
        if (strpos($filePathOrCommand, 'pm2 logs') === 0) {
            $commandOutput = shell_exec("/home/login/.yarn/bin/" . $filePathOrCommand . " 2>&1"); // Specify pm2 path

            if ($commandOutput) {
                $lines = explode(PHP_EOL, trim($commandOutput));
                $logContent = array_slice($lines, 0, $maxLinesPerLog); // Limit lines
            } else {
                error_log("Warning: Failed to retrieve PM2 logs for $key using command: $filePathOrCommand");
            }
        }
        // Otherwise, handle as a regular log file if path is valid
        elseif (file_exists($filePathOrCommand) && is_readable($filePathOrCommand) && is_file($filePathOrCommand)) {
            $offset = isset($offsets[$key]) ? (int)$offsets[$key] : 0;
            $fileContent = file($filePathOrCommand, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            $logContent = array_slice($fileContent, $offset, $maxLinesPerLog);  // Limit lines per log
        } else {
            error_log("Warning: Log file or command $filePathOrCommand for $key does not exist or is not readable.");
        }

        // Process log content into response structure
        $logs[$key] = array_map(function($line) {
            $content = mb_convert_encoding(trim($line), 'UTF-8', 'UTF-8');
            return [
                'content' => $content,
                'hash' => md5($content)
            ];
        }, $logContent);
    }

    $responseData = ["success" => true, "logs" => $logs, "newOffset" => array_map('count', $logs)];
    $jsonResponse = json_encode($responseData, JSON_PARTIAL_OUTPUT_ON_ERROR | JSON_UNESCAPED_UNICODE);

    if (json_last_error() !== JSON_ERROR_NONE) {
        $errorMessage = json_last_error_msg();
        return $response->withJson(["success" => false, "message" => "JSON encoding error: $errorMessage"], 500);
    }

    return $response->write(trim($jsonResponse))->withHeader('Content-Type', 'application/json');
});
