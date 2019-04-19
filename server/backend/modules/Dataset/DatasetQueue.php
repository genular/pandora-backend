<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-04-18 13:12:00
 */
namespace SIMON\Dataset;

use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;
use \SIMON\Models\ModelsPackages as ModelsPackages;

class DatasetQueue {
	protected $table_name = "dataset_queue";
	protected $database;
	protected $logger;
	protected $Helpers;

	protected $ModelsPackages;

	public function __construct(
		Medoo $database,
		Logger $logger,
		ModelsPackages $ModelsPackages,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;

		$this->ModelsPackages = $ModelsPackages;
		$this->Helpers = $Helpers;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\Dataset\DatasetQueue constructed");
	}
	/**
	 * Checks if file is owned by specific user
	 * @return boolean [description]
	 */
	public function isOwner($user_id, $queueID) {
		$queue = $this->getDetailsByID($queueID, $user_id);
		return $queue;
	}

	/**
	 * [deleteByQueueIDs description]
	 * @param  [type] $queueIDs [description]
	 * @return [type]           [description]
	 */
	public function deleteByQueueIDs($queueIDs) {
		$data = $this->database->delete($this->table_name, [
			"AND" => [
				"id" => $queueIDs,
			],
		]);
		return ($data->rowCount());
	}

	/**
	 * [updateTable description]
	 * @param  [type] $column      [description]
	 * @param  [type] $value       [description]
	 * @param  [type] $whereColumn [description]
	 * @param  [type] $whereValue  [description]
	 * @return [type]              [description]
	 */
	public function updateTable($column, $value, $whereColumn, $whereValue) {

		$data = $this->database->update($this->table_name, [
			$column => $value,
		], [
			$whereColumn => $whereValue,
		]);

		// Returns the number of rows affected by the last SQL statement
		return ($data->rowCount());
	}

	/**
	 * [setProcessingStatus description]
	 * @param [type] $dqID   [description]
	 * @param [type] $status [description]
	 */
	public function setProcessingStatus($dqID, $status) {
		$details = $this->database->update($this->table_name, [
			"status" => $status,
		], [
			"id" => $dqID,
		]);
		// Returns the number of rows affected by the last SQL statement
		return ($details->rowCount());
	}

	/**
	 * Get all Queue Entries where status = 1 eg. just created
	 * @return [type] [description]
	 */
	public function getProcessingEntries() {
		$columns = [
			"id [Int]",
			"uid [Int]",
			"packages [JSON]",
		];
		$conditions = [
			"status" => 1,
			"ORDER" => ["id" => "DESC"],
		];
		$details = $this->database->select($this->table_name, $columns, $conditions);

		return ($details);
	}

	/**
	 * [createQueue description]
	 * @param  [type] $user_id             [description]
	 * @param  [type] $submitData          [description]
	 * @param  [type] $allOtherSelections  [description]
	 * @param  [type] $allSelectedFeatures [description]
	 * @return [type]                      [description]
	 */
	public function createQueue($user_id, $submitData, $allOtherSelections, $allSelectedFeatures) {
		$queue_id = 0;
		$serverGroups = 2;

		$selectedPackages = $this->ModelsPackages->getPackages(1, $submitData["selectedPackages"]);

		$totalTime = 0;
		// Add some demo data
		foreach ($selectedPackages as $selectedPackagesKey => $selectedPackagesValue) {
			if (is_null($selectedPackages[$selectedPackagesKey]['time_per_million'])) {
				$time_per_m = rand(2, 2500);
				$totalTime += $time_per_m;
				$selectedPackages[$selectedPackagesKey]['time_per_million'] = $time_per_m;
			}
		}
		// Sort array from smallest to biggest exec time
		usort($selectedPackages, function ($item1, $item2) {
			return $item1['time_per_million'] <=> $item2['time_per_million'];
		});
		// Group selected algorithms in groups
		$packages = [];
		$processedPackages = [];
		$totalPackages = (count($selectedPackages) - 1);
		$counter = 0;
		do {
			$groupCounter = 0;
			for ($group = 0; $group < $serverGroups; $group++) {
				$tmpCounter = ($counter + $groupCounter);
				if ($tmpCounter > $totalPackages) {
					continue;
				}
				$index = $tmpCounter;
				if (isset($selectedPackages[$index])) {
					$packageID = $selectedPackages[$index]["id"];
					if (!isset($processedPackages[$packageID])) {
						$packages[] = array("packageID" => $packageID, "serverGroup" => $group);
						$processedPackages[$packageID] = true;
					}
				}
				$index = $totalPackages - $tmpCounter;
				if (isset($selectedPackages[$index])) {
					$packageID = $selectedPackages[$index]["id"];
					if (!isset($processedPackages[$packageID])) {
						$packages[] = array("packageID" => $packageID, "serverGroup" => $group);
						$processedPackages[$packageID] = true;
					}
				}
				$groupCounter++;
			}
			$counter = $counter + $serverGroups;
		} while ($counter < $totalPackages);

		/** hash of selected files details */
		$queueHashString = $user_id . $submitData["selectedFilesHash"] . json_encode($allSelectedFeatures) . json_encode($allOtherSelections) . json_encode($submitData["selectedPackages"]) . json_encode($submitData["backwardSelection"]) . json_encode($submitData["extraction"]);
		// TODO: development override
		$queueHash = hash('sha256', $queueHashString . time());

		$existsCheck = $this->database->has($this->table_name, [
			"uniqueHash" => $queueHash,
		]);

		if ($existsCheck === false) {
			$this->database->insert($this->table_name, [
				"uid" => $user_id,
				"ufid" => $submitData["selectedFiles"][0],
				"name" => $submitData["display_filename"],
				"uniqueHash" => $queueHash,
				"selectedOptions" => json_encode(["features" => $submitData["selectedFeatures"],
					"excludeFeatures" => $submitData["excludeFeatures"],
					"outcome" => $submitData["selectedOutcome"],
					"classes" => $submitData["selectedClasses"],
					"formula" => $submitData["selectedFormula"],
					"preProcess" => $submitData["selectedPreProcess"],
					"partitionSplit" => $submitData["selectedPartitionSplit"]]),
				"impute" => intval($submitData["backwardSelection"]),
				"extraction" => intval($submitData["extraction"]),
				"sparsity" => 0,
				"packages" => json_encode($packages),
				"status" => 0,
				"processing_time" => 0,
				"servers_total" => $serverGroups,
				"created" => Medoo::raw("NOW()"),
				"created_ip_address" => Medoo::raw("NULL"),
				"updated" => Medoo::raw("NOW()"),
				"updated_ip_address" => Medoo::raw("NULL"),
			]);

			$queue_id = $this->database->id();
		}

		return ($queue_id);
	}

	/**
	 * [getDatasetQueueCount description]
	 * @param  [type] $column  [description]
	 * @param  [type] $value   [description]
	 * @param  array  $filters [description]
	 * @return [type]          [description]
	 */
	public function getDatasetQueueCount($column, $value, $filters = []) {
		$columns = "*";
		$conditions = [
			$column => $value,
		];
		$count = $this->database->count($this->table_name, $columns, array_merge($conditions, $filters));

		return ($count);
	}

	/**
	 * [getDetailsByID description]
	 * @param  [type] $pqid    [description]
	 * @param  [type] $user_id [description]
	 * @return [type]          [description]
	 */
	public function getDetailsByID($pqid, $user_id) {

		$sql = "SELECT
	                dataset_queue.id    AS id,
	                dataset_queue.ufid   AS ufid,
	                dataset_queue.created   AS created,
	                dataset_queue.updated   AS updated,
	                dataset_queue.selectedOptions   AS selectedOptions,
	                dataset_queue.processing_time    AS queueProcessingTime,
	                dataset_queue.status AS status,
	                dataset_queue.extraction AS queueExtraction,
	                dataset_queue.sparsity AS sparsity,
	                users.username  AS username,
	                COUNT(dataset_resamples.id) AS resamplesTotal,
	                COUNT(models.id) AS modelsTotal,
	                SUM(CASE WHEN models.status > 0 THEN 1 ELSE 0 END) AS modelsSuccess

	            FROM dataset_queue

	            LEFT JOIN users
	                ON dataset_queue.uid = users.id
	            LEFT JOIN dataset_resamples
	                ON dataset_queue.id = dataset_resamples.dqid
	            LEFT JOIN models
	                ON dataset_resamples.id = models.drid

	            WHERE dataset_queue.uid = :user_id AND  dataset_queue.id = :pqid";

		$sql = $sql . " GROUP BY dataset_queue.id LIMIT 1;";

		$details = $this->database->query($sql, [
			":user_id" => $user_id,
			":pqid" => $pqid,
		])->fetch(\PDO::FETCH_ASSOC);

		return ($details);

	}

	/**
	 * [getDatasetQueueList description]
	 * @param  [type] $user_id [description]
	 * @param  [type] $page    [description]
	 * @param  [type] $limit   [description]
	 * @param  [type] $sort    [description]
	 * @param  array  $filters [description]
	 * @return [type]          [description]
	 */
	public function getDatasetQueueList($user_id, $page, $limit, $sort, $filters = []) {

		$start_limit = (($page - 1) * $limit);
		$end_limit = $limit;

		$sql = "SELECT
				    dataset_queue.id    AS queueID,
				    dataset_queue.created   AS created,
				    dataset_queue.updated   AS updated,
				    dataset_queue.processing_time    AS queueProcessingTime,
				    dataset_queue.status AS status,
				    dataset_queue.extraction AS queueExtraction,
				    dataset_queue.sparsity AS sparsity,
				    dataset_queue.packages AS packages,
				    dataset_queue.ufid AS ufid,
				    dataset_queue.name AS queueName,
				    users.username  AS username,
				    COUNT(DISTINCT(dataset_resamples.id)) AS resamplesTotal,
				    COUNT(models.id) AS modelsTotal,
				    SUM(CASE WHEN models.status > 0 THEN 1 ELSE 0 END) AS modelsSuccess

				FROM dataset_queue

				INNER JOIN users
				    ON dataset_queue.uid = users.id

				LEFT JOIN dataset_resamples
				    ON dataset_queue.id = dataset_resamples.dqid

				LEFT JOIN models
				    ON dataset_resamples.id = models.drid

	            WHERE dataset_queue.uid = :user_id";

		if ($sort === "+") {
			$sort = "ASC";
		} else {
			$sort = "DESC";
		}

		if (count($filters) > 0) {
			foreach ($filters as $filtersKey => $filtersValue) {
				if (!is_array($filtersValue)) {
					$filtersValue = [$filtersValue];
				}
				$filtersValue = join(',', array_map('intval', $filtersValue));
				$sql = $sql . " AND " . $filtersKey . " IN (" . $filtersValue . ")";

			}
		}

		$sql = $sql . " GROUP BY queueID ORDER BY queueID " . $sort . " LIMIT :start_limit, :end_limit;";

		$details = $this->database->query($sql, [
			":user_id" => $user_id,
			":start_limit" => $start_limit,
			":end_limit" => $end_limit,
		])->fetchAll(\PDO::FETCH_ASSOC);

		$details = $this->Helpers->castArrayValues($details);

		return ($details);
	}

}
