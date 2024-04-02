<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:10
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-24 09:53:27
 */

use Slim\Http\Request;
use Slim\Http\Response;

/**
 * Validates the availability of a specific value in a database table's field.
 *
 * This endpoint performs a validation check to determine if a specified value is available (i.e., does not
 * exist) in a given field of a specified database table. It's designed to validate user input against existing
 * database records, such as checking for unique usernames or email addresses before allowing a new user registration.
 * The validation process involves decoding provided parameters and verifying them against a whitelist of allowed tables
 * and fields to prevent unauthorized database queries. The result indicates whether the queried value is available for
 * use (not found in the database).
 *
 * @param Request $request The request object, containing encoded parameters for table, field, and value to validate.
 * @param Response $response The response object used to return the validation outcome.
 * @param array $args Contains 'validationTable', 'validationField', and 'validationValue', all base64-encoded and URL-decoded strings specifying the database query parameters.
 * 
 * @return Response JSON response indicating the success of the validation check and whether the value is available.
 */
$app->get('/backend/system/validation/database/{validationTable:.*}/{validationField:.*}/{validationValue:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$recordAvaliable = false;

	$system = $this->get('PANDORA\System\System');

	$validationTable = urldecode(base64_decode($args['validationTable']));
	$validationField = urldecode(base64_decode($args['validationField']));
	$validationValue = urldecode(base64_decode($args['validationValue']));

	$allowedTables = array('users', 'users_details', 'users_organization', 'organization_details', 'coupon_code');
	$allowedFields = array('username', 'email', 'invite_code', 'name', 'private', 'coupon_code', 'org_invite_code');

	if (!in_array($validationTable, $allowedTables)) {
		$success = false;
	}

	if (!in_array($validationField, $allowedFields)) {
		$success = false;
	}

	if ($success !== false) {

		if($validationField === 'org_invite_code'){

			if($validationValue === "aTomicLab"){
				$recordAvaliable = true;
			}else{
				$url = 'https://genular.atomic-lab.org/api/validate_key';
				$api_key = $validationValue;
				$url_with_api_key = $url . '?api_key=' . urlencode($api_key);

				$options = array(
				    'ssl' => array(
				        'verify_peer'       => true, // Enable verification of the peer's SSL certificate
				        'verify_peer_name'  => true, // Enable verification of the peer name in the SSL certificate
				        'allow_self_signed' => false, // Do not allow self-signed certificates
				    ),
				    'http' => array(
				        'method'  => 'GET',
				        'timeout' => 15, // Set timeout
				    ),
				);

				$context = stream_context_create($options);
				$check_response = @file_get_contents($url_with_api_key, false, $context);

				if ($check_response !== FALSE) {
					$check_response_data = json_decode($check_response, true);			
				    if (isset($check_response_data['valid']) && $check_response_data['valid'] === true) {
				        $recordAvaliable = true;
				    }
				}
			}
		}else{
			// Try to retrieve that row from database
			$dbResults = $system->databaseAvailability($validationTable, $validationField, $validationValue);
			if (!$dbResults) {
				$recordAvaliable = true;
			}
		}
	}

	return $response->withJson(["success" => $success, "message" => $recordAvaliable]);

});
