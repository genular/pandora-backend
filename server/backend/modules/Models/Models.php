<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-13 17:47:10
 */
namespace SIMON\Models;

use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;

class Models {
	protected $table_name = "models";
	protected $database;
	protected $logger;
	protected $Helpers;

	public function __construct(
		Medoo $database,
		Logger $logger,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Helpers = $Helpers;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\Models constructed");
	}

	/**
	 * [getStatistics description]
	 * @param  integer $user_id [description]
	 * @return [type]           [description]
	 */
	public function getStatistics($user_id = 14) {
		$data = $this->database->query("SELECT COUNT(DISTINCT dq.id) AS total_queue,
					       COUNT(DISTINCT dr.id) AS total_resamples,
					       COUNT(DISTINCT m.id)  AS total_models,
					       COUNT(DISTINCT mp.id) AS total_features
					FROM   dataset_queue dq
					       LEFT JOIN dataset_resamples dr
					              ON dr.dqid = dq.id
					       LEFT JOIN models m
					              ON m.drid = dr.id
					       LEFT JOIN models_performance mp
					              ON mp.mid = m.id
					WHERE  dq.uid = :user_id", [":user_id" => $user_id])->fetch(\PDO::FETCH_ASSOC);

		return $data;

	}

	/**
	 * [deleteByResampleIDs description]
	 * @param  [type] $resampleIDs [description]
	 * @return [type]              [description]
	 */
	public function deleteByResampleIDs($resampleIDs) {
		$data = $this->database->delete($this->table_name, [
			"AND" => [
				"drid" => $resampleIDs,
			],
		]);
		return ($data->rowCount());
	}

	/**
	 * [assignMesurmentsToModels description]
	 * @param  [type] $modelsList                [description]
	 * @param  [type] $modelsPerformace          [description]
	 * @param  [type] $modelsPerformaceVariables [description]
	 * @return [type]                            [description]
	 */
	public function assignMesurmentsToModels($modelsList, $modelsPerformace, $modelsPerformaceVariables) {
		$modelsPerformaceVariablesDefults = array_map(function ($val) {return 0;}, array_flip($modelsPerformaceVariables));

		// Assign performance variables to models
		foreach ($modelsList as $modelKey => $modelsListValue) {
			$modelID = $modelsListValue["modelID"];
			if (isset($modelsPerformace[$modelID])) {
				$modelsList[$modelKey]["performance"] = $modelsPerformace[$modelID]["performance"];
				// Is some measurement is missing add it with default 0
				$mesurmensDiff = array_diff($modelsPerformaceVariables, array_keys($modelsList[$modelKey]["performance"]));
				if ((count($mesurmensDiff) == 0) == false) {
					$mesurmensDiff = array_map(function ($val) {return 0;}, array_flip($mesurmensDiff));
					$modelsList[$modelKey]["performance"] = array_merge($modelsList[$modelKey]["performance"], $mesurmensDiff);
				}

			} else {
				// Is measurements are missing add it with default 0
				$modelsList[$modelKey]["performance"] = $modelsPerformaceVariablesDefults;
			}
		}

		return $modelsList;
	}

	/**
	 * [getDatasetResamplesModels description]
	 * @param  [type] $drid    [description]
	 * @param  [type] $user_id [description]
	 * @return [type]          [description]
	 */
	public function getDatasetResamplesModels($drid, $user_id) {
		$drids = join(',', array_map('intval', $drid));

		$sql = " SELECT
				       dataset_resamples.id AS resampleID,
				       models.id         AS modelID,
				       models.ufid         AS ufid,
				       models.status     AS status,
				       models.error      AS error,
				       models.processing_time    AS processing_time,
				       models_packages.internal_id AS modelName

				FROM   models
				       INNER JOIN dataset_resamples
				              ON models.drid = dataset_resamples.id
				       INNER JOIN dataset_queue
				              ON dataset_resamples.dqid = dataset_queue.id
				       LEFT JOIN models_packages
				              ON models.mpid = models_packages.id
				WHERE  models.drid IN (" . $drids . ")
				       AND dataset_queue.uid = :user_id
				ORDER BY models.status DESC;";

		$details = $this->database->query($sql, [
			":user_id" => $user_id,
		])->fetchAll(\PDO::FETCH_ASSOC);

		$details = $this->Helpers->castArrayValues($details);

		return ($details);
	}
}
