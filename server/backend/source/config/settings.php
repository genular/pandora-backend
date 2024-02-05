<?php

/**
 * Configuration settings for the PANDORA project.
 *
 * This file defines an array of settings used throughout the PANDORA application. It includes
 * environment-specific settings (like Docker usage and internet connectivity), error handling,
 * template rendering paths, logging configurations, and timezone settings. These settings are
 * consumed by the Slim application and its dependencies to configure behavior across different
 * environments (development, production, etc.).
 *
 * Usage of environment variables and helper functions ensures that configurations can be
 * dynamically adjusted based on the deployment environment.
 */

use \PANDORA\Helpers\Helpers as Helpers;

return [
    'settings' => [
        // Check if the application is running in a Docker container by looking for a specific environment variable.
        'is_docker' => getenv('IS_DOCKER') ? true : false,

        // Check internet connectivity using a helper function from the PANDORA Helpers class.
        'is_connected' => Helpers::is_connected(),

        // Control whether detailed error messages should be displayed. Recommended to be false in production environments for security.
        'displayErrorDetails' => true,

        // Determines if the Slim application adds a Content-Length header to the response. Disabling can be useful for streaming responses.
        'addContentLengthHeader' => false,

        // Renderer settings for the application's views or templates.
        'renderer' => [
            'template_path' => __DIR__ . '/../../templates/',
        ],

        // Monolog logger settings, including the log file location and the logging level.
        'logger' => [
            'name' => 'pandora-backend',
            'path' => __DIR__ . '/../logs/pandora.log',
            'level' => \Monolog\Logger::DEBUG,
        ],

        // Set the application's timezone, defaulting to the system's timezone if not specified via an environment variable.
        'timezone' => getenv('TZ') ? getenv('TZ') : date_default_timezone_get(),
    ],
];
