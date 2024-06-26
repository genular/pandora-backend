<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-05 14:36:15
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2021-02-04 10:31:53
 */
use Slim\Http\Request;
use Slim\Http\Response;

$app->get('/backend/queue/list', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = array();

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

	$DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');
	$paginatedData = $DatasetQueue->getDatasetQueueList($user_id, $page, $limit, $sort, $filters);

	if ($paginatedData) {
		foreach ($paginatedData as $paginatedDataKey => $paginatedDataValue) {
			$paginatedData[$paginatedDataKey]['edit']['queueName'] = false;
		}

		$countData = 0;
		if (count($paginatedData) > 0) {
			$countData = $DatasetQueue->getDatasetQueueCount("uid", $user_id, $filters);

			$message["queueList"] = $paginatedData;
			$message["queueTotalItems"] = $countData;
			$success = true;
		}
	}

	return $response->withJson(["success" => $success, "message" => $message]);
});

/**
 * Used to update Queue name in Dashboard => field click
 */
$app->post('/backend/queue/update', function (Request $request, Response $response, array $args) {
	$success = false;
	$message = "";

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	$submitData = false;
	if (isset($post['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($post['submitData'])), true);
	}

	if ($submitData) {
		$updateID = intval($submitData['updateID']);
		$updateAction = trim($submitData['updateAction']);
		$updateValue = trim($submitData['updateValue']);
		// Different actions
		if ($updateAction === "queueName") {
			$DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');
			$privilage = $DatasetQueue->isOwner($user_id, $updateID);

			if ($privilage) {
				$updateCheck = $DatasetQueue->updateTable("name", $updateValue, "id", $updateID);
				if ($updateCheck) {
					$success = true;
				}
			}
		}
	}

	return $response->withJson(["success" => $success]);

});

$app->get('/backend/queue/exploration/list', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];
	$message = Array(
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
	
	// Outcome class to get measurements for?!
	$selectedOutcomeOptionsIDs = $request->getQueryParam('selectedOutcomeOptionsIDs', [0]);

	if (is_numeric($queueID)) {
		$DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');
		$queueDetails = $DatasetQueue->getDetailsByID($queueID, $user_id);

		if ($queueDetails !== false) {
			$DatasetResamplesMappings = $this->get('PANDORA\Dataset\DatasetResamplesMappings');
			$queueDetails["outcomeMappings"] =  $DatasetResamplesMappings->getMappingsForQueue($queueID);


			$ModelsPerformance = $this->get('PANDORA\Models\ModelsPerformance');

			// Get Average performance for the queue
			list($queuePerformace, $queuePerformaceVariables) = $ModelsPerformance->getPerformaceVariables([$queueID], "queueID", "MAX", $measurements, $selectedOutcomeOptionsIDs);

			if (isset($queuePerformace[$queueID])) {
				$queueDetails["performance"] = $queuePerformace[$queueID]["performance"];
			}

			$selectedOptions = json_decode($queueDetails["selectedOptions"], true);
			$queueDetails["selectedOptions"] = $selectedOptions;

			$DatasetResamples = $this->get('PANDORA\Dataset\DatasetResamples');
			$resamplesList = $DatasetResamples->getDatasetResamples($queueID, $user_id);
			$resamplesListIDs = array_column($resamplesList, 'resampleID');

			list($resamplesPerformace, $resamplesPerformaceVariables) = $ModelsPerformance->getPerformaceVariables($resamplesListIDs, "resampleID", "MAX", $measurements, $selectedOutcomeOptionsIDs);

			$DatasetProportions = $this->get('PANDORA\Dataset\DatasetProportions');
			$resamplesProportions = $DatasetProportions->getDatasetResamplesProportions($resamplesListIDs);
			// Count number of unique values inside the class
			$queueDetails["selectedOptions"]["classes"] = $DatasetProportions->getUniqueValuesCountForClasses($resamplesListIDs, $queueDetails["selectedOptions"]["classes"]);
			// For each proportion column add additional array key "original" and put original column name in it column7 => Outcome
			$resamplesProportions = $DatasetProportions->mapRenamedToOriginal("column_remapped", $resamplesProportions, $queueDetails["selectedOptions"]);

			// Format proportions and merge them with resamples
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

			$Models = $this->get('PANDORA\Models\Models');
			$modelsList = $Models->getDatasetResamplesModels($resamplesListIDs, $user_id);

			$modelsListIDs = array_column($modelsList, 'modelID');
			list($modelsPerformace, $modelsPerformaceVariables) = $ModelsPerformance->getPerformaceVariables($modelsListIDs, "modelID", "MAX", $measurements, $selectedOutcomeOptionsIDs);

			$modelsList = $Models->assignMesurmentsToModels($modelsList, $modelsPerformace, $modelsPerformaceVariables);

			$modelsListNameIDs = array_column($modelsList, 'modelName');

			$ModelsPackages = $this->get('PANDORA\Models\ModelsPackages');
			$modelPackagesDetails = $ModelsPackages->getPackages(1, null, $modelsListNameIDs);

			$modelsList = $Models->assignPackageDetailsToModels($modelsList, $modelPackagesDetails);
			// Custom sorting function using usort
			usort($modelsList, function ($a, $b) {
			    // Updated prioritized list of metrics based on the given criteria for a broad overview
			    $metrics = [
			        'Accuracy', 
			        'BalancedAccuracy', // Assuming 'Balanced Accuracy' and 'BalancedAccuracy' are used interchangeably
			        'PredictAUC',
			        'TrainAUC',
			        'F1',
			        'Precision',
			        'Recall',
			        'Specificity',
			        'prAUC',
			        'Kappa',
			        'NegPredValue',
			        'PosPredValue',
			        'DetectionRate',
			        'TrainAccuracy',
			        'TrainBalanced_Accuracy',
			        'TrainF1',
			        'TrainPrecision',
			        'TrainRecall',
			        'TrainSpecificity',
			        'TrainMean_Balanced_Accuracy',
			        'TrainMean_F1',
			        'TrainMean_Precision',
			        'TrainMean_Recall',
			        'TrainMean_Sensitivity',
			        'TrainMean_Specificity',
			        'TrainNeg_Pred_Value',
			        'TrainPos_Pred_Value',
			        'TrainlogLoss',
			        'TrainprAUC'
			    ];
			    
			    foreach ($metrics as $metric) {
			        // Assign -INF if metric is missing to ensure models with missing metrics are ranked lower
			        $aMetric = isset($a['performance'][$metric]) ? $a['performance'][$metric] : -INF;
			        $bMetric = isset($b['performance'][$metric]) ? $b['performance'][$metric] : -INF;

			        // Compare the current metric, prioritizing higher values
			        if ($aMetric != $bMetric) {
			            return $aMetric < $bMetric ? 1 : -1;
			        }
			    }

			    // If all compared metrics are equal or missing, sort by modelID as a last resort
			    // This ensures a consistent order even if performance metrics are the same
			    return $a['modelID'] - $b['modelID'];
			});



			$message = Array(
				'resamplesList' => $resamplesList,
				'modelsList' => $modelsList,
				'queueDetails' => $queueDetails,
				'performaceVariables' => $resamplesPerformaceVariables,
			);
		} else {
			$success = false;
		}

	} else {
		$success = false;
	}

	return $response->withJson(["success" => $success, "message" => $message]);
});

/**
 * Dashboard => modal details
 */
$app->get('/backend/queue/details', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];

	$DatasetResamples = $this->get('PANDORA\Dataset\DatasetResamples');

	$config = $this->get('Noodlehaus\Config');
	$redirectURL = $config->get('default.frontend.server.url');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$queueIDs = $request->getQueryParam('queueIDs', []);

	foreach ($queueIDs as $queueID) {
		$data = $DatasetResamples->getDatasetResamples($queueID, $user_id);
		$message = array_merge($message, $data);
	}

	if (count($message) < 1) {
		$success = false;
	}

	return $response->withJson(["success" => $success, "message" => $message]);
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

	$resampleIDs = $request->getQueryParam('resampleIDs', 0);
	$measurements = $request->getQueryParam('measurements', []);

	if (is_array($resampleIDs)) {

		$Models = $this->get('PANDORA\Models\Models');

		// $modelsWhereClause = [($hideFailedModels === false ? "models.error LIKE '%'" : "models.error = ''")];
		$modelsWhereClause = [];
		$modelsList = $Models->getDatasetResamplesModels($resampleIDs, $user_id, $modelsWhereClause);

		$modelsListIDs = array_column($modelsList, 'modelID');
		$ModelsPerformance = $this->get('PANDORA\Models\ModelsPerformance');

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
		$DatasetResamples = $this->get('PANDORA\Dataset\DatasetResamples');
		$options = $DatasetResamples->getResampleOptions($resampleID, $user_id);

		$DatasetProportions = $this->get('PANDORA\Dataset\DatasetProportions');

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
