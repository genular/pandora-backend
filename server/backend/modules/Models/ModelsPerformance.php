<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2020-03-14 14:40:22
 */
namespace PANDORA\Models;

use \Medoo\Medoo;
use \Monolog\Logger;
use \PANDORA\Helpers\Helpers as Helpers;

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
		$this->logger->addInfo("==> INFO: PANDORA\Models\ModelsPerformance constructed");
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
	 * Retrieves aggregated performance variables from the database for a given set of IDs, grouped by a specified column.
	 *
	 * This function queries the database to fetch and aggregate specified performance measurements (e.g., Accuracy, Precision)
	 * for a set of provided IDs. These IDs can represent queues, resamples, or models, depending on the grouping column specified.
	 * The function supports customization of the aggregate function (e.g., MAX, AVG) and automatically handles missing measurements
	 * by defaulting to a predefined list of performance variables.
	 *
	 * @param array $ids Array of integers representing the IDs for which performance variables are fetched.
	 * @param string $groupColumn The database column used to group results. Defaults to "queueID". Supported values are "queueID", "resampleID", and "modelID".
	 * @param string $aggregateFunc The SQL aggregate function to apply to the performance variables. Defaults to "MAX".
	 * @param array $measurements Array of strings representing the performance measurements to retrieve. If empty or not an array, defaults to a predefined list of common performance metrics.
	 * 
	 * @return array Returns an array consisting of two elements:
	 *               - The first element is an associative array mapping each ID (based on $groupColumn) to its aggregated performance variables.
	 *               - The second element is an array of unique performance variable names that were retrieved.
	 */
	public function getPerformaceVariables($ids, $groupColumn = "queueID", $aggregateFunc = "MAX", $measurements, $selectedOutcomeOptionsIDs = 0) {

		$ids = join(',', array_map('intval', $ids));

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
				WHERE " . $grouppings[$groupColumn] . " IN (" . $ids . ")";

			if(is_array($measurements) && count($measurements) > 0) {
				$sql = $sql . " AND models_performance_variables.value IN ('" . join("','", $measurements) . "')";
			}

			
			if(is_array($selectedOutcomeOptionsIDs) && count($selectedOutcomeOptionsIDs) > 0) {
				$outcomeClassIds = join(',', array_map('intval', $selectedOutcomeOptionsIDs));
				$sql = $sql . " AND models_performance.drm_id IN (" . $outcomeClassIds . ")";
			}

			$sql = $sql." GROUP BY
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
