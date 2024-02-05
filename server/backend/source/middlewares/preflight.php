<?php

use Slim\Http\Request;
use Slim\Http\Response;

/**
 * CORS middleware for handling cross-origin request settings.
 *
 * This middleware dynamically sets Access-Control-* headers for all HTTP responses
 * based on configurations defined in the application settings. It specifically handles
 * pre-flight OPTIONS requests by stopping further middleware execution and returning
 * the response immediately with the appropriate CORS headers.
 *
 * @param Request $request The HTTP request object.
 * @param Response $response The HTTP response object.
 * @param callable $next The next middleware or route callable.
 * @return Response The response object with added CORS headers.
 */
$app->add(function (Request $request, Response $response, $next) use ($container) {
    // Retrieve application configuration settings.
    $config = $container->get('Noodlehaus\Config');

    // Define CORS headers based on application settings and requirements.
    $headers = [
        'Access-Control-Allow-Origin' => $config->get('default.frontend.server.url'), // Allows requests from the configured frontend URL.
        'Access-Control-Allow-Credentials' => 'true', // Allows credentials to be included in the requests.
        'Access-Control-Max-Age' => '60', // Indicates how long the results of a preflight request can be cached.
        'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, PATCH, OPTIONS, HEAD', // Specifies the methods allowed when accessing the resource.
        'Access-Control-Allow-Headers' => 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,Origin,Accept,X-Token,U-Path', // Specifies the headers allowed in actual requests.
    ];

    // Check if the current request is a pre-flight OPTIONS request.
    if (!$request->isOptions()) {
        // For non-OPTIONS requests, continue with the next middleware or route callable.
        $results = $next($request, $response);

        // Add the CORS headers to the response.
        foreach ($headers as $key => $value) {
            $results = $results->withHeader($key, $value);
        }
        return $results;
    } else {
        // For OPTIONS requests, stop further processing and return the response with CORS headers.
        $results = $response;
        foreach ($headers as $key => $value) {
            $results = $results->withHeader($key, $value);
        }
        return $results;
    }
});
