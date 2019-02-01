<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:28:25
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-31 11:53:33
 */
use Slim\Http\Request;
use Slim\Http\Response;
use Slim\Middleware\TokenAuthentication;
use \SIMON\Exceptions\UnauthorizedException as UnauthorizedException;

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
		$UsersSessions = $container->get('SIMON\Users\UsersSessions');

		/**
		 * Verify if token is valid on database
		 * If token isn't valid, must throw an UnauthorizedExceptionInterface
		 */
		$user_id = $UsersSessions->getUserIdBySessionId($session_id);

		$initial_db_connect = microtime(true) - $start;
		if ($user_id) {
			return $request->withAttribute('user', ["user_id" => intval($user_id["uid"]), "session_id" => $session_id, "initial_db_connect" => $initial_db_connect]);
		} else {
			throw new UnauthorizedException('Invalid Authentication');
		}
	},
	'error' => function (Request $request, $response, TokenAuthentication $tokenAuth) {
		$output = [];
		$output['error'] = [
			'msg' => $tokenAuth->getResponseMessage(),
			'token' => $tokenAuth->getResponseToken(),
			'status' => 401,
			'error' => true,
		];
		return $response->withJson($output, 401);
	},
	'secure' => false,
	'relaxed' => ['127.0.0.1', 'localhost'],
	'header' => 'HTTP_X_TOKEN',
	'regex' => "/^([a-f0-9]{64})$/",
	'parameter' => 'HTTP_X_TOKEN',
	'cookie' => 'HTTP_X_TOKEN',
	'argument' => 'HTTP_X_TOKEN',

]));
