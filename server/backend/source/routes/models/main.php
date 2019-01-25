<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:15
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 14:25:46
 */
use Slim\Http\Request;
use Slim\Http\Response;

$app->get('/backend/queue/list', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];

	$config = $this->get('Noodlehaus\Config');
	$redirectURL = $config->get('default.frontend.server.url');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$page = (int) $request->getQueryParam('page', 1);
	$limit = (int) $request->getQueryParam('limit', 20);
	$sort = $request->getQueryParam('sort', '+');

	$filters = [];
	$queueID = $request->getQueryParam('queueID', null);
	// Only numeric filters are supported
	preg_match_all('!\d+!', $queueID, $matches);
	if (count($matches[0]) > 0) {
		$filters = array(
			"dataset_queue.id" => $matches[0],
		);
	}

	$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');
	$paginatedData = $DatasetQueue->getDatasetQueueList($user_id, $page, $limit, $sort, $filters);

	$countData = 0;
	if (count($paginatedData) > 0) {
		$countData = $DatasetQueue->getDatasetQueueCount("uid", $user_id, $filters);
	}

	return $response->withJson(["success" => $success, "data" => $paginatedData, "totalItems" => $countData]);
});

$app->get('/backend/queue/exploration/list', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];
	$data = Array(
		'resamplesList' => null,
		'modelsList' => null,
		'queueDetails' => null,
		'performaceVariables' => null,
	);

	$config = $this->get('Noodlehaus\Config');
	$redirectURL = $config->get('default.frontend.server.url');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$queueID = $request->getQueryParam('queueID', 0);
	$measurements = $request->getQueryParam('measurements', []);

	if (is_numeric($queueID)) {
		$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');
		$queueDetails = $DatasetQueue->getDetailsByID($queueID, $user_id);

		if ($queueDetails !== false) {
			$ModelsPerformance = $this->get('SIMON\Models\ModelsPerformance');

			list($queuePerformace, $queuePerformaceVariables) = $ModelsPerformance->getPerformaceVariables([$queueID], "queueID", "MAX", $measurements);

			if (isset($queuePerformace[$queueID])) {
				$queueDetails["performance"] = $queuePerformace[$queueID]["performance"];
			}

			$selectedOptions = json_decode($queueDetails["selectedOptions"], true);
			$queueDetails["selectedOptions"] = $selectedOptions;

			$DatasetResamples = $this->get('SIMON\Dataset\DatasetResamples');
			$resamplesList = $DatasetResamples->getDatasetResamples($queueID, $user_id);
			$resamplesListIDs = array_column($resamplesList, 'resampleID');

			list($resamplesPerformace, $resamplesPerformaceVariables) = $ModelsPerformance->getPerformaceVariables($resamplesListIDs, "resampleID", "MAX", $measurements);

			$DatasetProportions = $this->get('SIMON\Dataset\DatasetProportions');
			$resamplesProportions = $DatasetProportions->getDatasetResamplesProportions($resamplesListIDs);

			$queueDetails["selectedOptions"]["classes"] = $DatasetProportions->getUniqueValuesCountForClasses($resamplesListIDs, $queueDetails["selectedOptions"]["classes"]);

			$resamplesProportions = $DatasetProportions->mapRenamedToOriginal("column_remapped", $resamplesProportions, $queueDetails["selectedOptions"]);
			$resamplesList = $DatasetProportions->mergeProportions($resamplesProportions, $resamplesList);

			foreach ($resamplesList as $resampleKey => $resamplesListValue) {
				$resampleID = $resamplesListValue["resampleID"];
				if (isset($resamplesPerformace[$resampleID])) {
					$resamplesList[$resampleKey]["performance"] = $resamplesPerformace[$resampleID]["performance"];
				}
			}

			// Remove list of feature to speed up the things
			if (isset($queueDetails["selectedOptions"]["features"])) {
				unset($queueDetails["selectedOptions"]["features"]);
			}
			if (isset($queueDetails["selectedOptions"]["excludeFeatures"])) {
				unset($queueDetails["selectedOptions"]["excludeFeatures"]);
			}

			$Models = $this->get('SIMON\Models\Models');
			$modelsList = $Models->getDatasetResamplesModels($resamplesListIDs, $user_id);

			$modelsListIDs = array_column($modelsList, 'modelID');
			list($modelsPerformace, $modelsPerformaceVariables) = $ModelsPerformance->getPerformaceVariables($modelsListIDs, "modelID", "MAX", $measurements);
			$modelsList = $Models->assignMesurmentsToModels($modelsList, $modelsPerformace, $modelsPerformaceVariables);

			$data = Array(
				'resamplesList' => $resamplesList,
				'modelsList' => $modelsList,
				'queueDetails' => $queueDetails,
				'performaceVariables' => $modelsPerformaceVariables,
			);
		} else {
			$success = false;
		}

	} else {
		$success = false;
	}

	return $response->withJson(["success" => $success, "data" => $data]);
});

$app->get('/backend/queue/details', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];

	$config = $this->get('Noodlehaus\Config');
	$redirectURL = $config->get('default.frontend.server.url');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$pqid = $request->getQueryParam('pqid', 0);
	if (is_numeric($pqid)) {
		$DatasetResamples = $this->get('SIMON\Dataset\DatasetResamples');
		$data = $DatasetResamples->getDatasetResamples($pqid, $user_id);
	} else {
		$data = "";
		$success = false;
	}

	return $response->withJson(["success" => $success, "data" => $data]);
});

$app->get('/backend/queue/resamples/details', function (Request $request, Response $response, array $args) {
	$success = true;

	$data = Array(
		'modelsList' => null,
		'performaceVariables' => null,
	);

	$config = $this->get('Noodlehaus\Config');
	$redirectURL = $config->get('default.frontend.server.url');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$resamplesListIDs = $request->getQueryParam('drid', 0);
	$measurements = $request->getQueryParam('measurements', []);

	if (is_numeric($resamplesListIDs)) {

		$Models = $this->get('SIMON\Models\Models');
		$modelsList = $Models->getDatasetResamplesModels(array($resamplesListIDs), $user_id);

		$modelsListIDs = array_column($modelsList, 'modelID');
		$ModelsPerformance = $this->get('SIMON\Models\ModelsPerformance');

		list($modelsPerformace, $modelsPerformaceVariables) = $ModelsPerformance->getPerformaceVariables($modelsListIDs, "modelID", "MAX", $measurements);
		$modelsList = $Models->assignMesurmentsToModels($modelsList, $modelsPerformace, $modelsPerformaceVariables);

		$data = Array(
			'modelsList' => $modelsList,
			'performaceVariables' => $modelsPerformaceVariables,
		);

	} else {
		$success = false;
	}

	return $response->withJson(["success" => $success, "data" => $data]);
});

/**
 * Suggest features of requested re-sample ID
 *
 * @param  {object} Containing 3 variables
 * resampleID: database ID of the resample, userInput: user inputed string, inputType: features, outcome, classes
 *
 * @return {json} JSON encoded API response object
 */
$app->get('/backend/queue/resamples/features/suggest/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];
	$data = "";

	$config = $this->get('Noodlehaus\Config');
	$redirectURL = $config->get('default.frontend.server.url');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$resampleID = false;
	$userInput = "";
	$inputType = "outcome_classes";

	$submitData = false;
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
		if ($submitData) {
			$resampleID = (int) $submitData['resampleID'];
			$userInput = (string) $submitData['userInput'];
			$inputType = (string) $submitData['inputType'];
		}
	}

	if ($resampleID) {
		$DatasetResamples = $this->get('SIMON\Dataset\DatasetResamples');
		$options = $DatasetResamples->getResampleOptions($resampleID, $user_id);

		$DatasetProportions = $this->get('SIMON\Dataset\DatasetProportions');

		if ($inputType === "features") {
			$data = $DatasetProportions->mapRenamedToOriginal("remapped", $options["resampleOptions"]["features"], $options["queueOptions"]);
		} else if ($inputType === "outcome") {
			$data = $options["queueOptions"]["outcome"];
		} else if ($inputType === "classes") {
			$data = $options["queueOptions"]["classes"];
		} else {
			$data = array_merge($options["queueOptions"]["outcome"], $options["queueOptions"]["classes"]);
		}

		if (trim($userInput) !== "") {
			usort($data, function ($a, $b) use ($userInput) {
				similar_text($userInput, $a["original"], $percentA);
				similar_text($userInput, $b["original"], $percentB);

				return $percentA === $percentB ? 0 : ($percentA > $percentB ? -1 : 1);
			});
		}

		$data = array_slice($data, 0, 50);
		$data = array_values($data);

	} else {
		$success = false;
	}

	return $response->withJson(["success" => $success, "data" => $data]);
});
