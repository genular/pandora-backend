<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:15
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-04-15 15:04:45
 */
use Slim\Http\Request;
use Slim\Http\Response;

$app->get('/backend/queue/exploration/variableImportance', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];

	$config = $this->get('Noodlehaus\Config');
	$redirectURL = $config->get('default.frontend.server.url');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$pqid = $request->getQueryParam('pqid');

	$resampleID = $request->getQueryParam('resampleID', 0);
	$modelsID = $request->getQueryParam('modelsID', [0]);

	$selectedOutcomeOptionsIDs = $request->getQueryParam('selectedOutcomeOptionsIDs', [0]);

	$page = $request->getQueryParam('page', 1);
	$page_size = $request->getQueryParam('page_size', 20);
	$sort = $request->getQueryParam('sort', false);
	// Cast string to boolean
	$sort = $sort === 'true' ? true : false;

	$sort_by = $request->getQueryParam('sort_by', 'feature_name');

	$ModelsVariables = $this->get('PANDORA\Models\ModelsVariables');
	$variableImportanceData = $ModelsVariables->getVariableImportance($modelsID, intval($page), intval($page_size), $sort, $sort_by, $selectedOutcomeOptionsIDs);

	$DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');
	$queueDetails = $DatasetQueue->getDetailsByID($pqid, $user_id);

	$selectedOptions = json_decode($queueDetails["selectedOptions"], true);
	$queueDetails["selectedOptions"] = $selectedOptions;

	$DatasetProportions = $this->get('PANDORA\Dataset\DatasetProportions');
	$variableImportanceData = $DatasetProportions->mapRenamedToOriginal("feature_name", $variableImportanceData, $queueDetails["selectedOptions"]);

	// $DatasetResamplesMappings = $this->get('PANDORA\Dataset\DatasetResamplesMappings');
	// $outcomeMappings =  $DatasetResamplesMappings->getMappingsForResample($resampleID);


	$totalItems = $ModelsVariables->countTotalVariables($modelsID);

	return $response->withJson(["success" => $success, "data" => $variableImportanceData, "total" => $totalItems]);
});
