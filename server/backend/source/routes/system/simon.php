<?php

/**
 * @Author: LogIN-
 * @Date:   2018-06-08 15:11:00
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-15 15:01:53
 */

use Slim\Http\Request;
use Slim\Http\Response;

$app->post('/backend/system/simon/available-packages', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = "";
	$packages = Array();

	$post = $request->getParsedBody();
	if (isset($post['selectedFiles'])) {
		$selectedFiles = json_decode(base64_decode(urldecode($post['selectedFiles'])), true);
	}

	$ModelsPackages = $this->get('SIMON\Models\ModelsPackages');
	$avaliablePackages = $ModelsPackages->getPackages();

	$preselectedPackages = ["naive_bayes", "hdda", "pcaNNet", "LogitBoost", "svmLinear2"];

	$packages = array_map(function ($package) use ($preselectedPackages) {
		if (in_array($package['internal_id'], $preselectedPackages)) {
			$package['preselected'] = 1;
		} else {
			$package['preselected'] = 0;
		}

		return $package;

	}, $avaliablePackages
	);

	return $response->withJson(["success" => $success, "message" => $packages]);

});

$app->get('/backend/system/simon/header/{selectedFiles:.*}/verify', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = array();

	$config = $this->get('Noodlehaus\Config');
	$FileSystem = $this->get('SIMON\System\FileSystem');
	$Helpers = $this->get('SIMON\Helpers\Helpers');

	$selectedFiles = [];
	if (isset($args['selectedFiles'])) {
		$selectedFiles = json_decode(base64_decode(urldecode($args['selectedFiles'])), true);
	}

	$file_id = 0;
	if (count($selectedFiles) > 0) {
		if (isset($selectedFiles[0]["id"])) {
			$file_id = $selectedFiles[0]["id"];
		}
	}

	$fileDetails = false;
	if ($file_id > 0) {
		// Retrieve first line from database
		$fileDetails = $FileSystem->getFileDetails($file_id);
	}

	if ($fileDetails !== false && isset($fileDetails["details"])) {
		$details = $fileDetails["details"];
		unset($fileDetails);
		if (isset($details["header"]) && isset($details["header"]["formatted"])) {
			$message = array_slice($details["header"]["formatted"], 0, 50);
			$message = array_values($message);
			unset($details);
		} else {
			$success = false;
			$message[] = "Cannot read file header.";
		}

	} else {
		$success = false;
		$message[] = "File not found";
	}

	return $response->withJson(["success" => $success, "message" => $message]);

});

$app->get('/backend/system/simon/header/{selectedFiles:.*}/suggest/{userInput:.*}', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = array();

	$config = $this->get('Noodlehaus\Config');
	$FileSystem = $this->get('SIMON\System\FileSystem');
	$Helpers = $this->get('SIMON\Helpers\Helpers');

	$userInput = base64_decode(urldecode($args['userInput']));

	$selectedFiles = [];
	if (isset($args['selectedFiles'])) {
		$selectedFiles = json_decode(base64_decode(urldecode($args['selectedFiles'])), true);
	}

	$file_id = 0;
	if (count($selectedFiles) > 0) {
		if (isset($selectedFiles[0]["id"])) {
			$file_id = $selectedFiles[0]["id"];
		}
	}

	$fileDetails = false;
	if ($file_id > 0) {
		// Retrieve first line from database
		$fileDetails = $FileSystem->getFileDetails($file_id);
	}

	if ($fileDetails !== false && isset($fileDetails["details"])) {
		$details = $fileDetails["details"];
		unset($fileDetails);
		if (isset($details["header"])) {
			if (is_array($details["header"]["formatted"])) {
				$message = $details["header"]["formatted"];
				unset($details);

				if (trim($userInput) !== "") {
					usort($message, function ($a, $b) use ($userInput) {
						similar_text($userInput, $a["original"], $percentA);
						similar_text($userInput, $b["original"], $percentB);

						return $percentA === $percentB ? 0 : ($percentA > $percentB ? -1 : 1);
					});
				}

				$message = array_slice($message, 0, 50);
				$message = array_values($message);
			}

		} else {
			$success = false;
			$message[] = "Cannot read file header";
		}

	} else {
		$success = false;
		$message[] = "File not found";
	}

	return $response->withJson(["success" => $success, "message" => $message]);

});

$app->post('/backend/system/simon/pre-analysis', function (Request $request, Response $response, array $args) {
	$success = true;
	$message = [];
	$queue_message = [];

	$start = microtime(true);

	$config = $this->get('Noodlehaus\Config');

	$FileSystem = $this->get('SIMON\System\FileSystem');
	$DatasetIntersection = $this->get('SIMON\Dataset\DatasetIntersection');
	$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');
	$DatasetResamples = $this->get('SIMON\Dataset\DatasetResamples');
	$DatasetCalculations = $this->get('SIMON\Dataset\DatasetCalculations');
	$Helpers = $this->get('SIMON\Helpers\Helpers');

	$user_details = $request->getAttribute('user');
	$initial_db_connect = $user_details['initial_db_connect'];
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	if (isset($post['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($post['submitData'])), true);
		$submitData["selectedPartitionSplit"] = (int) $submitData["selectedPartitionSplit"];
	}

	$tempFilePath = $FileSystem->downloadFile($submitData["selectedFiles"][0]);

	$queuesGenerated = [];
	$queueID = 0;
	$sparsity = 0;

	if ($tempFilePath !== false && file_exists($tempFilePath)) {
		$totalDatasetsGenerated = 0;

		$mainFileDetails = $FileSystem->getFileDetails($submitData["selectedFiles"][0]);

		// Check if user has selected ALL Switch, in that case just exclude other Features from Header
		$selectALLSwitch = array_search("ALL", array_column($submitData["selectedFeatures"], 'remapped'));
		if ($selectALLSwitch !== false) {

			$excludeKeys = ["excludeFeatures", "selectedOutcome", "selectedFormula", "selectedClasses"];

			$selectedFeatures = $mainFileDetails["details"]["header"]["formatted"];
			foreach ($excludeKeys as $excludeValue) {
				$excludeItems = $submitData[$excludeValue];

				foreach ($excludeItems as $excludeItem) {
					foreach ($selectedFeatures as $selectedFeaturesKey => $selectedFeaturesValue) {
						if ($selectedFeaturesValue["position"] === $excludeItem["position"]) {
							unset($selectedFeatures[$selectedFeaturesKey]);
						}
					}
				}
			}
			// Keep exclusively only features
			$submitData["selectedFeatures"] = array_values($selectedFeatures);
		}

		$allOtherOptions = array_merge($submitData["selectedOutcome"], $submitData["selectedFormula"], $submitData["selectedClasses"]);
		$allOtherSelections = [];
		foreach ($allOtherOptions as $option) {
			if (!isset($allOtherSelections[$option["remapped"]])) {
				$allOtherSelections[$option["remapped"]] = true;
			}
		}
		ksort($allOtherSelections, SORT_NATURAL);
		$allOtherSelections = array_keys($allOtherSelections);

		$allSelectedFeatures = [];
		foreach ($submitData["selectedFeatures"] as $feature) {
			if (!isset($allSelectedFeatures[$feature["remapped"]])) {
				$allSelectedFeatures[$feature["remapped"]] = true;
			}
		}
		ksort($allSelectedFeatures, SORT_NATURAL);
		$allSelectedFeatures = array_keys($allSelectedFeatures);

		$queueID = $DatasetQueue->createQueue($user_id, $submitData, $allOtherSelections, $allSelectedFeatures);

		$queueSparsity = true;
		if ($queueID !== 0) {
			// CALCULATE INTERSECTIONS
			foreach ($submitData["selectedOutcome"] as $selectedOutcome) {
				$resamples = $DatasetIntersection->generateDataPresets($tempFilePath, $selectedOutcome, $allSelectedFeatures, $submitData["extraction"]);
				// If we didn't do multi-set intersection check if some of the columns contain Invalid data
				if ($submitData["extraction"] === false && count($resamples["info"]["invalidColumns"]) > 0) {
					foreach ($resamples["info"]["invalidColumns"] as $invalidColumn) {
						array_push($queue_message, ["msg_info" => "invalid_columns", "data" => $invalidColumn]);
					}
					// remove resamples and force user needs to select new columns since some have non  numeric data
					continue;
				}
				// Check if have good amount of samples and adjust appropriate status and message variables
				$resamples["resamples"] = $DatasetCalculations->validateSampleSize($resamples["resamples"], $submitData["selectedPartitionSplit"]);

				// Update sparsity values only once per main queue not for each resample
				if ($queueSparsity === true) {
					$sparsity = $resamples["info"]["sparsity"];
					$queueSparsity = $DatasetQueue->updateTable("sparsity", $sparsity, "id", $queueID);
				}

				$queuesGenerated[] = ["outcome" => $selectedOutcome, "data" => $resamples["resamples"]];
				$totalDatasetsGenerated += count($resamples["resamples"]);
			}

			if ($totalDatasetsGenerated > 0) {
				// Create Re-sample Files to temporary place on file-system
				$queuesGenerated = $DatasetIntersection->generateResamples($queueID, $tempFilePath, $queuesGenerated, $allOtherSelections);
				// Upload each of them to the storage
				foreach ($queuesGenerated as $resampleGroupKey => $resampleGroupValue) {

					foreach ($resampleGroupValue["data"] as $resampleGroupDataKey => $resampleGroupDataValue) {

						$uploaded_path = $resampleGroupDataValue["resamplePath"];
						// Validate File Header and rename it to standardize column names!
						$details = $Helpers->validateCSVFileHeader($uploaded_path);
						$details["details"] = $mainFileDetails["details"];

						$renamed_path = $Helpers->renamePathToHash($details);
						// Compress original file to GZ archive format
						$gzipped_path = $Helpers->compressPath($renamed_path);
						// Upload compressed file to the Storage
						$remote_path = $FileSystem->uploadFile($user_id, $gzipped_path, "uploads/queue/" . $queueID);
						// Save reference to Database
						$file_id = $FileSystem->insertFileToDatabase($user_id, $details, $remote_path);

						// Delete and cleanup local files
						if (file_exists($uploaded_path)) {
							@unlink($uploaded_path);
						}
						if (file_exists($renamed_path)) {
							@unlink($renamed_path);
						}
						if (file_exists($gzipped_path)) {
							@unlink($gzipped_path);
						}

						$resampleID = $DatasetResamples->createResample($queueID, $file_id, $resampleGroupDataValue, $resampleGroupValue["outcome"], $submitData);

						$queuesGenerated[$resampleGroupKey]["data"][$resampleGroupDataKey]["id"] = $resampleID;
						$queuesGenerated[$resampleGroupKey]["data"][$resampleGroupDataKey]["fileID"] = $file_id;

						unset($queuesGenerated[$resampleGroupKey]["data"][$resampleGroupDataKey]["listFeatures"]);
						unset($queuesGenerated[$resampleGroupKey]["data"][$resampleGroupDataKey]["resamplePath"]);
					}
				}
			} else {
				array_push($queue_message, ["msg_info" => "no_resamples"]);
			}
			// @unlink($tempFilePath);
		} else {
			$success = false;
			array_push($queue_message, ["msg_info" => "queue_exists"]);
		}

	} else {
		array_push($message, ["msg_info" => "source_not_found"]);
	}
	$time_elapsed_secs = microtime(true) - $start;

	return $response->withJson(["success" => $success,
		"details" => array(
			"queueID" => $queueID,
			"sparsity" => $sparsity,
			"dataset_queues" => $queuesGenerated,
			"message" => $queue_message),
		"message" => $message,
		"time_elapsed_secs" => $time_elapsed_secs,
		"initial_db_connect" => $initial_db_connect]);

});

$app->post('/backend/system/simon/dataset-queue', function (Request $request, Response $response, array $args) {
	$success = true;
	$updateCount = 0;

	$DatasetResamples = $this->get('SIMON\Dataset\DatasetResamples');
	$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');

	// 1 - Global Administrator / 2 - User / 3 - Organization Administrator / 4 - Organization User
	// $user_details["user"]["id"]
	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();

	$submitData = array();
	if (isset($post['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($post['submitData'])), true);
	}

	if (isset($submitData['resamples'])) {
		// 1. Activate or deactivate each resample
		foreach ($submitData['resamples'] as $resamples) {
			foreach ($resamples['data'] as $resample) {
				$updateCount += $DatasetResamples->updateStatus($resample, $submitData['queueID']);
			}
		}
		// 2. Change status in Dataset Queue
		if ($updateCount > 0) {
			// Set Queue as active for cron to pick it up
			$DatasetQueue->setProcessingStatus($submitData['queueID'], 1);
		}
	}

	return $response->withJson(["success" => $success, "message" => $updateCount]);

});

$app->post('/backend/system/simon/dataset-queue/cancel', function (Request $request, Response $response, array $args) {
	$success = true;

	$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	$submitData = array();

	if (isset($post['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($post['submitData'])), true);
	}

	if (isset($submitData['queueID'])) {
		$DatasetQueue->setProcessingStatus($submitData['queueID'], 2);
	}

	return $response->withJson(["success" => $success]);

});

/**
 * Deletes all queue related data from the system
 */
$app->post('/backend/system/simon/dataset-queue/delete', function (Request $request, Response $response, array $args) {
	$success = false;

	$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	$submitData = array();

	$queueID = false;
	if (isset($post['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($post['submitData'])), true);
		$queueID = $submitData['queueID'];
	}

	$files = [];

	if ($queueID !== false) {

		$DatasetResamples = $this->get('SIMON\Dataset\DatasetResamples');
		$resamplesList = $DatasetResamples->getDatasetResamples($queueID, $user_id);
		$resamplesListIDs = array_column($resamplesList, 'resampleID');

		foreach ($resamplesList as $resample) {
			$files[] = $resample['ufid'];
			$files[] = $resample['ufid_train'];
			$files[] = $resample['ufid_test'];
		}

		$Models = $this->get('SIMON\Models\Models');
		$modelsList = $Models->getDatasetResamplesModels($resamplesListIDs, $user_id);
		$modelsListIDs = array_column($modelsList, 'modelID');

		foreach ($modelsList as $model) {
			$files[] = $model['ufid'];

		}

		// 2. models_performance
		$ModelsPerformance = $this->get('SIMON\Models\ModelsPerformance');
		$ModelsPerformance->deleteByModelIDs($modelsListIDs);

		// 3. models
		$Models->deleteByResampleIDs($resamplesListIDs);

		$ModelsVariables = $this->get('SIMON\Models\ModelsVariables');
		$ModelsVariables->deleteByModelIDs($modelsListIDs);

		// 3. dataset_resamples_mappings
		$DatasetResamplesMappings = $this->get('SIMON\Dataset\DatasetResamplesMappings');
		$DatasetResamplesMappings->deleteByQueueIDs($queueID);

		// 3. dataset_resamples
		$DatasetResamples->deleteByQueueIDs($queueID);

		// 3. dataset_proportions
		$DatasetProportions = $this->get('SIMON\Dataset\DatasetProportions');
		$DatasetProportions->deleteByResampleIDs($resamplesListIDs);

		// 3. dataset_queue
		$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');
		$DatasetQueue->deleteByQueueIDs($queueID);

		$FileSystem = $this->get('SIMON\System\FileSystem');

		$FileSystem->deleteFilesByIDs(array_unique($files));

		$success = true;
	}

	return $response->withJson(["success" => $success]);

});

/**
 * Deletes all queue related data from the system
 */
$app->get('/backend/system/simon/dataset-resample/delete/{submitData:.*}', function (Request $request, Response $response, array $args) {
	$success = false;

	$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');

	$user_details = $request->getAttribute('user');
	$user_id = $user_details['user_id'];

	$post = $request->getParsedBody();
	$submitData = array();

	$submitData = false;
	if (isset($args['submitData'])) {
		$submitData = json_decode(base64_decode(urldecode($args['submitData'])), true);
	}

	$resampleID = false;
	if ($submitData && isset($submitData['resampleID'])) {
		$resampleID = (int) $submitData['resampleID'];
	}
	if ($resampleID !== false) {

	}

	return $response->withJson(["success" => $success]);

});