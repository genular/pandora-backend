<?php

/**
 * Main entry point for the application's route definitions.
 * 
 * This file includes the necessary PHP files for all route definitions across the application,
 * organizing them by their respective modules such as users, system, organization, models, and datasets.
 * It sets up a catch-all OPTIONS route to handle pre-flight CORS requests for the API.
 *
 */

// User-related route definitions
require 'source/routes/users/main.php';
require 'source/routes/users/dashboard.php';

// System-related route definitions including system status, validation, filesystem operations, and Pandora system specifics
require 'source/routes/system/main.php';
require 'source/routes/system/validation.php';
require 'source/routes/system/filesystem.php';
require 'source/routes/system/pandora.php';

// Organization-related route definitions
require 'source/routes/organization/main.php';

// Model-related route definitions, including model predictions and variable importance
require 'source/routes/models/main.php';
require 'source/routes/models/variableImportance.php';
require 'source/routes/models/predict.php';

// Dataset-related route definitions
require 'source/routes/dataset/main.php';

/**
 * Catch-all route for handling OPTIONS requests.
 * This is primarily used for CORS pre-flight requests in a RESTful API context, allowing
 * the client to determine the options and requirements associated with a resource, or the capabilities of a server.
 *
 * @param Request $request Slim's HTTP request object.
 * @param Response $response Slim's HTTP response object.
 * @param array $args Additional route parameters.
 * @return Response Returns an empty response for OPTIONS requests.
 */
$app->options('/{routes:.+}', function ($request, $response, $args) {
    return $response;
});
