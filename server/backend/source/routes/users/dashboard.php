<?php

use Slim\Http\Request;
use Slim\Http\Response;

/**
 * Fetches statistics for the user dashboard.
 *
 * This endpoint retrieves various statistics for the current user, which can include the number of models created,
 * datasets processed, or any other relevant metrics to be displayed on the user's dashboard. The process involves querying
 * the database for statistics related to the user's activities and aggregating this data into a format suitable for dashboard
 * presentation. The success of the operation and the resulting statistics (if any) are returned in the response.
 *
 * @param Request $request The request object, containing user details such as the user ID.
 * @param Response $response The response object used to return the collected statistics.
 * @param array $args Unused in this function but required by the route definition.
 * 
 * @return Response JSON response containing the operation's status and the fetched statistics.
 */
$app->get('/backend/dashboard/stats', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = array();

	$config = $this->get('Noodlehaus\Config');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$Models = $this->get('PANDORA\Models\Models');
	$statistics = $Models->getStatistics($user_id);
	if ($statistics) {
		$message = $statistics;
		$success = true;
	}

	$data = array(
		'status' => $success,
		'message' => $message,
	);

	return $response->withJson($data);
});
