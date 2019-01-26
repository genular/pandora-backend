<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:19:22
 */
namespace SIMON\Models;

use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;

class ModelsPerformance {
	protected $table_name = "models_performance";
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
		$this->logger->addInfo("==> INFO: SIMON\Models\ModelsPerformance constructed");
	}

	/**
	 * [deleteByModelIDs description]
	 * @param  [type] $modelIDs [description]
	 * @return [type]           [description]
	 */
	public function deleteByModelIDs($modelIDs) {
		$data = $this->database->delete($this->table_name, [
			"AND" => [
				"mid" => $modelIDs,
			],
		]);
		return ($data->rowCount());
	}

	/**
	 * [getPerformaceVariables description]
	 * @param  [type] $ids           [description]
	 * @param  string $groupColumn   [description]
	 * @param  string $aggregateFunc [description]
	 * @param  [type] $measurements  [description]
	 * @return [type]                [description]
	 */
	public function getPerformaceVariables($ids, $groupColumn = "queueID", $aggregateFunc = "MAX", $measurements) {

		$ids = join(',', array_map('intval', $ids));
		if (!is_array($measurements) || count($measurements) < 1) {
			$measurements = ['Accuracy', 'F1', 'Kappa', 'Precision', 'PredictAUC', 'Recall', 'Sensitivity', 'Specificity', 'TrainAccuracy', 'TrainAUC', 'TrainF1', 'TrainprAUC', 'TrainPrecision', 'TrainRecall', 'TrainSensitivity', 'TrainSpecificity'];
		}
		$grouppings = Array("queueID" => "dataset_queue.id", "resampleID" => "dataset_resamples.id", "modelID" => "models.id");

		$sql = "SELECT
					dataset_queue.id AS queueID,
					dataset_resamples.id AS resampleID,
					models.id AS modelID,

					" . $aggregateFunc . "(ROUND(models_performance.prefValue, 4))  AS prefValue,
					models_performance_variables.value      AS prefName
				FROM dataset_queue
				    LEFT JOIN dataset_resamples
				        ON dataset_queue.id = dataset_resamples.dqid
				    INNER JOIN models
				        ON dataset_resamples.id = models.drid
				    INNER JOIN models_performance
				    	ON models.id = models_performance.mid
				    INNER JOIN models_performance_variables
				    	ON models_performance.mpvid = models_performance_variables.id
				WHERE " . $grouppings[$groupColumn] . " IN (" . $ids . ")
				AND models_performance_variables.value IN ('" . join("','", $measurements) . "')
				GROUP BY
					" . $grouppings[$groupColumn] . ", models_performance_variables.value;";

		$details = $this->database->query($sql)->fetchAll(\PDO::FETCH_ASSOC);
		$details = $this->Helpers->castArrayValues($details);

		$performace = [];
		$performaceVariables = [];

		foreach ($details as $performaceValue) {

			if (!isset($performace[$performaceValue[$groupColumn]])) {
				$performace[$performaceValue[$groupColumn]] = ["performance" => Array()];
			}
			if (!isset($performace[$performaceValue[$groupColumn]]["performance"][$performaceValue["prefName"]])) {
				$performace[$performaceValue[$groupColumn]]["performance"][$performaceValue["prefName"]] = $performaceValue["prefValue"];
			}

			if (!isset($performaceVariables[$performaceValue["prefName"]])) {
				$performaceVariables[$performaceValue["prefName"]] = true;
			}

		}

		return (array($performace, array_unique(array_keys($performaceVariables))));
	}
}
