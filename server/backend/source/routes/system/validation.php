<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:10
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-24 09:53:27
 */

use Slim\Http\Request;
use Slim\Http\Response;

$app->get('/backend/system/validation/database/{validationTable:.*}/{validationField:.*}/{validationValue:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$recordAvaliable = false;

	$system = $this->get('SIMON\System\System');

	$validationTable = urldecode(base64_decode($args['validationTable']));
	$validationField = urldecode(base64_decode($args['validationField']));
	$validationValue = urldecode(base64_decode($args['validationValue']));

	$allowedTables = array('users', 'users_details', 'users_organization', 'organization_details', 'coupon_code');
	$allowedFields = array('username', 'email', 'invite_code', 'name', 'private', 'coupon_code');

	if (!in_array($validationTable, $allowedTables)) {
		$success = false;
	}

	if (!in_array($validationField, $allowedFields)) {
		$success = false;
	}

	if ($success !== false) {
		// Try to retrieve that row from database
		$dbResults = $system->databaseAvailability($validationTable, $validationField, $validationValue);

		if (!$dbResults) {
			$recordAvaliable = true;
		}
	}

	return $response->withJson(["success" => $success, "message" => $recordAvaliable]);

});
