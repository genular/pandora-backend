<?php

use Slim\Http\Request;
use Slim\Http\Response;

/**
 * Handles creating or updating organization-related information.
 *
 * This endpoint is designed to process POST requests related to organization operations, such as creating a new organization
 * or updating an existing organization's details. It extracts user and directory information from the request, performing
 * operations based on the provided data. The function currently focuses on extracting a directory path from the request,
 * though the actual use-case seems to be broader or requires further implementation details.
 *
 * @param Request $request The request object, containing user details and possibly a selected directory.
 * @param Response $response The response object used to return the operation's success status and any relevant data, such as the user ID.
 * @param array $args Unused in this function but required by the route definition.
 * 
 * @return Response JSON response indicating the operation's success and including any pertinent data, like the user ID.
 */
$app->post('/backend/organization/', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = false;

	$fileSystem = $this->get('PANDORA\System\FileSystem');
	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	if (isset($post['selectedDirectory'])) {
		$selectedDirectory = urldecode(base64_decode($post['selectedDirectory']));
	} else {
		$selectedDirectory = urldecode(base64_decode($post['selectedDirectory']));
	}

	return $response->withJson(["success" => $success, "data" => $user_id]);

});
