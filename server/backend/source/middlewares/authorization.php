<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:28:25
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-05 15:17:24
 */
use Slim\Http\Request;
use Slim\Http\Response;
use Slim\Middleware\TokenAuthentication;
use \PANDORA\Exceptions\UnauthorizedException as UnauthorizedException;

$app->add(new TokenAuthentication([
	'path' => '/backend',
	'passthrough' => [
		'/backend/user/login',
		'/backend/user/register',
		'/backend/user/reset',
		'/backend/system/status/*',
		'/backend/system/cron/*',
		'/backend/system/servers/*',
		'/backend/user/verify/*',
		'/backend/user/avatar/*',
		'/backend/models/predict/*',
		'/backend/system/validation/database/*',
		'/backend/system/plans/list/*'],
	'authenticator' => function (Request $request, TokenAuthentication $tokenAuth) use ($container) {

		/**
		 * Try find authorization token via header, parameters, cookie or attribute
		 * If token not found, return response with status 401 (unauthorized)
		 */
		$session_id = $tokenAuth->findToken($request);

		$start = microtime(true);
		/**
		 * Call authentication logic class
		 */
		$UsersSessions = $container->get('PANDORA\Users\UsersSessions');

		/**
		 * Verify if token is valid on database
		 * If token isn't valid, must throw an UnauthorizedExceptionInterface
		 */
		$user_id = $UsersSessions->getUserIdBySessionId($session_id);
		$initial_db_connect = microtime(true) - $start;
		if ($user_id) {
			// $this->logger->addInfo("====================> PANDORA REQUEST STARTS: " . $user_id["uid"]);
			return $request->withAttribute('user', ["user_id" => intval($user_id["uid"]), "session_id" => $session_id, "initial_db_connect" => $initial_db_connect]);
		} else {
			throw new UnauthorizedException('Invalid Authentication');
		}
	},
	'error' => function (Request $request, $response, TokenAuthentication $tokenAuth) {
		$status = 401;
		$output = [];

		$output['error'] = [
			'message' => $tokenAuth->getResponseMessage(),
			//'token' => $tokenAuth->getResponseToken(),
			'status' => $status,
			'error' => true,
		];
		return $response->withJson($output, $status);
	},
	'secure' => false,
	'relaxed' => ['127.0.0.1', 'localhost', 'localhost:3010'],
	'header' => 'X-TOKEN',
	'regex' => "/^([a-f0-9]{64})$/",
	'parameter' => 'HTTP_X_TOKEN',
	'cookie' => 'HTTP_X_TOKEN',
	'argument' => 'HTTP_X_TOKEN',

]));
