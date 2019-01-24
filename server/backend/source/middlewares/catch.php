<?php
/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:28:04
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-06 09:35:31
 */

// $app->add(function ($request, $response, $next) {
// 	$Helpers = $this->get('SIMON\Helpers\Helpers');
//
// 	$Config = $this->get('Noodlehaus\Config');
// 	$frontend_url = $Config->get('default.frontend.server.url');
//
// 	$response = $next($request, $response);
// 	// Get current response body
// 	$body = $response->getBody()->__toString();
//
// 	// Base64 encode the body and encrypt it
// 	$dataEnc = base64_encode($body);
// 	$dataEnc = $Helpers->cryptoJsAesEncrypt("1337", $dataEnc);
// 	$dataEnc = json_encode($dataEnc);
//
// 	// Response with new encrypted body
// 	$body = new \Slim\Http\Body(fopen('php://temp', 'r+'));
// 	$body->write($dataEnc);
//
// 	return $response->withBody($body);
//
// });

// Catch all http errors here.
// $app->add(function ($request, $response, $next) use ($container) {
//
// 	// Default status code.
// 	$status = 200;
//
// 	// Catch errors.
// 	try {
// 		$response = $next($request, $response);
// 		$status = $response->getStatusCode();
//
// 		// If it is 404, throw error here.
// 		if ($status === 404) {
// 			throw new \Exception('Page not found', 404);
//
// 			// A 404 should be invoked.
// 			// Note since it is to be taken care by the exception below
// 			// so comment this custom 404.
// 			// $handler = $container->get('notFoundHandler');
// 			// return $handler($request, $response);
// 		}
// 	} catch (\Exception $error) {
// 		$status = $error->getCode();
// 		$data = [
// 			"status" => $error->getCode(),
// 			"messsage" => $error->getMessage(),
// 		];
// 		$response->getBody()->write(json_encode($data));
// 	};
//
// 	return $response
// 		->withStatus($status)
// 		->withHeader('Content-type', 'application/json');
// });
