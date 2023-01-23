<?php

/**
 * @Author: LogIN-
 * @Date:   2018-06-08 15:11:00
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2021-02-04 16:13:24
 */

use Slim\Http\Request;
use Slim\Http\Response;

$app->post('/backend/system/pandora/available-packages', function (Request $request, Response $response, array $args) {
    $success = true;
    $message = "";
    $packages = array();

    $post = $request->getParsedBody();
    if (isset($post['selectedFiles'])) {
        $selectedFiles = json_decode(base64_decode(urldecode($post['selectedFiles'])), true);
    }

    $ModelsPackages = $this->get('PANDORA\Models\ModelsPackages');
    $avaliablePackages = $ModelsPackages->getPackages();

    foreach ($avaliablePackages as $packageKey => $packageValue) {
        if($packageValue["internal_id"] === "null"){
            unset($avaliablePackages[$packageKey]);
        }
    }



    $preselectedPackages = []; // ["naive_bayes", "hdda", "pcaNNet", "LogitBoost", "svmLinear2"];

    $avaliablePackages = array_map(function ($package) use ($preselectedPackages) {

        if (in_array($package['internal_id'], $preselectedPackages)) {
            $package['preselected'] = 1;
        } else {
            $package['preselected'] = 0;
        }

        // if ($package['classification'] === false) {
        //  $package['disabled'] = true;
        // } else {
        // Disable all packages and enable/disable them as needed from Javascript
        $package['disabled'] = true;
        // }
        return $package;
    }, $avaliablePackages);

    foreach ($avaliablePackages as $packageKey => $packageValue) {
        array_push($packages, $packageValue);
    }


    return $response->withJson(["success" => $success, "message" => $packages]);
});

$app->get('/backend/system/pandora/header/{selectedFiles:.*}/verify', function (Request $request, Response $response, array $args) {
    $success = true;
    $message = array();

    $config = $this->get('Noodlehaus\Config');
    $UsersFiles = $this->get('PANDORA\Users\UsersFiles');
    $Helpers = $this->get('PANDORA\Helpers\Helpers');

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
        $fileDetails = $UsersFiles->getFileDetails($file_id, ["details"], true);
    }

    if ($fileDetails !== false && isset($fileDetails["details"])) {
        if (isset($fileDetails["details"]["header"]) && isset($fileDetails["details"]["header"]["formatted"])) {
            $message = array_slice($fileDetails["details"]["header"]["formatted"], 0, 50);
            $message = array_values($message);
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

$app->get('/backend/system/pandora/header/{selectedFiles:.*}/suggest/{userInput:.*}', function (Request $request, Response $response, array $args) {
    $success = true;
    $message = array();

    $config = $this->get('Noodlehaus\Config');
    $UsersFiles = $this->get('PANDORA\Users\UsersFiles');
    $Helpers = $this->get('PANDORA\Helpers\Helpers');

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
        $fileDetails = $UsersFiles->getFileDetails($file_id, ["details"], true);
    }

    if ($fileDetails !== false && isset($fileDetails["details"])) {
        if (isset($fileDetails["details"]["header"])) {
            if (is_array($fileDetails["details"]["header"]["formatted"])) {
                $message = $fileDetails["details"]["header"]["formatted"];
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

$app->post('/backend/system/pandora/pre-analysis', function (Request $request, Response $response, array $args) {
    $success = true;
    $message = [];
    $queue_message = [];

    $start = microtime(true);

    $config = $this->get('Noodlehaus\Config');

    $FileSystem = $this->get('PANDORA\System\FileSystem');
    $UsersFiles = $this->get('PANDORA\Users\UsersFiles');
    $DatasetIntersection = $this->get('PANDORA\Dataset\DatasetIntersection');
    $DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');
    $DatasetResamples = $this->get('PANDORA\Dataset\DatasetResamples');
    $DatasetCalculations = $this->get('PANDORA\Dataset\DatasetCalculations');
    $Helpers = $this->get('PANDORA\Helpers\Helpers');

    $user_details = $request->getAttribute('user');
    $initial_db_connect = $user_details['initial_db_connect'];
    $user_id = $user_details['user_id'];

    $post = $request->getParsedBody();
    if (isset($post['submitData'])) {
        // URL Encode two times, since sometimes utf8 characters from column names are issue for JS btoa
        $submitData = json_decode(urldecode(base64_decode(urldecode($post['submitData']))), true);
        $submitData["selectedPartitionSplit"] = (int) $submitData["selectedPartitionSplit"];
    }

    $tempFilePath = $FileSystem->downloadFile($submitData["selectedFiles"][0]);

    $queuesGenerated = [];
    $queueID = 0;
    $sparsity = 0;

    if ($tempFilePath !== false && file_exists($tempFilePath)) {
        $totalDatasetsGenerated = 0;

        $mainFileDetails = $UsersFiles->getFileDetails($submitData["selectedFiles"][0], ["details", "display_filename"], true);

        // Check if user has selected ALL Switch, in that case just exclude other Features from Header
        $selectALLSwitch = array_search("ALL", array_column($submitData["selectedFeatures"], 'remapped'));
        if ($selectALLSwitch !== false) {
            $excludeKeys = ["excludeFeatures", "selectedOutcome", "selectedFormula", "timeSeriesDate", "selectedClasses"];

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

        $submitData["display_filename"] = $mainFileDetails["display_filename"];

        $allOtherOptions = array_merge($submitData["selectedOutcome"], $submitData["selectedFormula"], $submitData["timeSeriesDate"], $submitData["selectedClasses"]);
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

        // Are we doing impute on analysis
        $isImpute = !empty(array_intersect(["medianImpute", "bagImpute", "knnImpute"], $submitData["selectedPreProcess"]));
        $backwardSelection = $submitData["backwardSelection"];
  

        $queueID = $DatasetQueue->createQueue($user_id, $submitData, $allOtherSelections, $allSelectedFeatures, $isImpute);

        $queueSparsity = true;
        if ($queueID !== 0) {
            // CALCULATE INTERSECTIONS
            foreach ($submitData["selectedOutcome"] as $selectedOutcome) {

                $resamples = $DatasetIntersection->generateDataPresets($tempFilePath, $selectedOutcome, $allSelectedFeatures, $submitData["extraction"], $backwardSelection, $isImpute);


                // If we didn't do multi-set intersection or impute check if some of the columns contain Invalid data
                if ($isImpute === false && $submitData["extraction"] === false && count($resamples["info"]["invalidColumns"]) > 0) {
                    foreach ($resamples["info"]["invalidColumns"] as $invalidColumn) {
                        $originalColumnKey = array_search($invalidColumn, array_column($submitData["selectedFeatures"], 'remapped'));
                        if (isset($submitData["selectedFeatures"][$originalColumnKey])) {
                            $originalColumnName = $submitData["selectedFeatures"][$originalColumnKey]["original"];
                        } else {
                            $originalColumnName = $invalidColumn;
                        }
                        array_push($queue_message, ["msg_info" => "invalid_columns", "data" => $originalColumnName]);
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
                        $file_id = $UsersFiles->insertFileToDatabase($user_id, $details, $remote_path);

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

$app->post('/backend/system/pandora/dataset-queue', function (Request $request, Response $response, array $args) {
    $success = true;
    $updateCount = 0;

    $DatasetResamples = $this->get('PANDORA\Dataset\DatasetResamples');
    $DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');

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

$app->post('/backend/system/pandora/dataset-queue/cancel', function (Request $request, Response $response, array $args) {
    $success = true;

    $DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');

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
 * Deletes all queue related data from the database and filesystem
 */
$app->post('/backend/system/pandora/dataset-queue/delete', function (Request $request, Response $response, array $args) {
    $success = false;

    $DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');

    $user_details = $request->getAttribute('user');
    $user_id = $user_details['user_id'];

    $post = $request->getParsedBody();
    $submitData = array();

    $queueIDs = false;
    if (isset($post['submitData'])) {
        $submitData = json_decode(base64_decode(urldecode($post['submitData'])), true);
        $queueIDs = $submitData['queueID'];
    }

    if ($queueIDs !== false) {
        if (!is_array($queueIDs)) {
            $queueIDs = [$queueIDs];
        }

        $this->get('Monolog\Logger')->info("PANDORA '/backend/system/pandora/dataset-queue/delete' processing queueIDs:" . count($queueIDs));

        foreach ($queueIDs as $queueID) {
            $this->get('Monolog\Logger')->info("PANDORA '/backend/system/pandora/dataset-queue/delete' processing queueID:" . $queueID);

            $files = [];

            $DatasetResamples = $this->get('PANDORA\Dataset\DatasetResamples');
            $resamplesList = $DatasetResamples->getDatasetResamples($queueID, $user_id);
            $resamplesListIDs = array_column($resamplesList, 'resampleID');

            foreach ($resamplesList as $resample) {
                $files[] = $resample['ufid'];
                $files[] = $resample['ufid_train'];
                $files[] = $resample['ufid_test'];
            }

            $Models = $this->get('PANDORA\Models\Models');
            $modelsList = $Models->getDatasetResamplesModels($resamplesListIDs, $user_id);
            $modelsListIDs = array_column($modelsList, 'modelID');

            foreach ($modelsList as $model) {
                $files[] = $model['ufid'];
            }

            // 2. models_performance
            $ModelsPerformance = $this->get('PANDORA\Models\ModelsPerformance');
            $ModelsPerformance->deleteByModelIDs($modelsListIDs);

            // 3. models
            $Models->deleteByResampleIDs($resamplesListIDs);

            $ModelsVariables = $this->get('PANDORA\Models\ModelsVariables');
            $ModelsVariables->deleteByModelIDs($modelsListIDs);

            // 3. dataset_resamples_mappings
            $DatasetResamplesMappings = $this->get('PANDORA\Dataset\DatasetResamplesMappings');
            $DatasetResamplesMappings->deleteByQueueIDs($queueID);

            // 3. dataset_resamples
            $DatasetResamples->deleteByQueueIDs($queueID);

            // 3. dataset_proportions
            $DatasetProportions = $this->get('PANDORA\Dataset\DatasetProportions');
            $DatasetProportions->deleteByResampleIDs($resamplesListIDs);

            // 3. dataset_queue
            $DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');
            $DatasetQueue->deleteByQueueIDs($queueID);

            $FileSystem = $this->get('PANDORA\System\FileSystem');

            $FileSystem->deleteFilesByIDs(array_unique($files));
        }

        $success = true;
    }

    return $response->withJson(["success" => $success]);
});

/**
 * Deletes all queue related data from the system
 */
$app->get('/backend/system/pandora/dataset-resample/delete/{submitData:.*}', function (Request $request, Response $response, array $args) {
    $success = false;

    $DatasetQueue = $this->get('PANDORA\Dataset\DatasetQueue');

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

/**
 * Generate system log file for the debugging purpose
 */
$app->get('/backend/system/pandora/generate-log-file/{submitData:.*}', function (Request $request, Response $response, array $args) {
    $success = false;

    $message = false;

    $FileSystem = $this->get('PANDORA\System\FileSystem');

    $UsersFiles = $this->get('PANDORA\Users\UsersFiles');

    $user_details = $request->getAttribute('user');
    $user_id = $user_details['user_id'];

    $downloadLinks = [];

    $compress_locations = [
        "/var/log/pandora-cron.log" => "pandora_cron_log.tar.gz",
        realpath(realpath(dirname(__DIR__)) . "/../logs/pandora.log") => "pandora_backend_log.tar.gz",
        "/home/login/.pm2/logs" => "pm2_server_logs.tar.gz",
        "/root/.pm2/logs" => "pm2_server_logs.tar.gz",
        "/var/log/nginx" => "nginx_server_logs.tar.gz",
        "/var/log/supervisor/supervisord.log " => "supervisor_supervisord.tar.gz",
        "/var/log/supervisor" => "supervisor_supervisor.tar.gz",
        "/var/log/prepare_storage_log" => "supervisor_prepare_storage_log.tar.gz",
        "/var/log/mariadb_log" => "supervisor_mariadb_log.tar.gz",
        "/var/log/php_log" => "supervisor_php_log.tar.gz",
        "/var/log/nginx_log" => "supervisor_nginx_log.tar.gz",
        "/var/log/pm2_log" => "supervisor_pm2_log.tar.gz",
        "/var/log/cron_log" => "supervisor_cron_log.tar.gz"
    ];

    // Compress PANDORA cron log file
    foreach ($compress_locations as $fileInput => $fileOutput) {
        $download_url = $FileSystem->compressFileOrDirectory($fileInput, $fileOutput);

        if ($download_url !== false) {
            $downloadLinks[] = ["filename" => $fileOutput, "download_url" => $download_url];
        }
    }

    if (count($downloadLinks) > 0) {
        $message = $downloadLinks;
        $success = true;
    }

    return $response->withJson(["success" => $success, "message" => $message]);
});
