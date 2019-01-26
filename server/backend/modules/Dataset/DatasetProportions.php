<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:26:45
 */
namespace SIMON\Dataset;

use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;

class DatasetProportions {
	protected $table_name = "dataset_proportions";
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
		$this->logger->addInfo("==> INFO: SIMON\Dataset\DatasetProportions constructed");
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
	 * [mapRenamedToOriginal description]
	 * @param  [type] $searchColumn    [description]
	 * @param  [type] $searchArray     [description]
	 * @param  [type] $selectedOptions [description]
	 * @return [type]                  [description]
	 */
	public function mapRenamedToOriginal($searchColumn, $searchArray, $selectedOptions) {
		$mappings = [];
		foreach ($searchArray as $searchArrayKey => $searchArrayValue) {
			$remappedValue = $searchArrayValue[$searchColumn];
			if (isset($mappings[$remappedValue])) {
				$searchArray[$searchArrayKey]["original"] = $mappings[$remappedValue];
				continue;
			}
			foreach ($selectedOptions as $selectedOptionsSubArrays) {
				if (is_array($selectedOptionsSubArrays)) {
					foreach ($selectedOptionsSubArrays as $subKey => $subValue) {
						if (isset($subValue["remapped"]) && $subValue["remapped"] === $remappedValue) {
							if (!isset($mappings[$remappedValue])) {
								$mappings[$remappedValue] = $subValue["original"];
								$searchArray[$searchArrayKey]["original"] = $mappings[$remappedValue];
								break 2;
							}
						}
					}
				}

			}
		}
		return $searchArray;
	}

	/**
	 * [mergeProportions description]
	 * @param  [type] $resamplesProportions [description]
	 * @param  [type] $resamplesList        [description]
	 * @return [type]                       [description]
	 */
	public function mergeProportions($resamplesProportions, $resamplesList) {
		$td = [];

		foreach ($resamplesProportions as $dKey => $dValue) {

			if (!isset($td[$dValue["resampleID"]])) {
				$td[$dValue["resampleID"]] = [];
			}

			$class_original = $dValue["class_original"];

			$mappings = [
				'median_class' => 'details', 'min_class' => 'details', 'max_class' => 'details',
				'numeric' => 'prop', 'percentage' => 'prop',
				'median_column' => 'details', 'min_column' => 'details', 'max_column' => 'details',
			];

			if ($class_original === null) {
				$class_original = "global";
			}

			if (isset($mappings[$dValue["value_type"]])) {
				$mapping = $mappings[$dValue["value_type"]];
			} else {
				$mapping = "details";
			}

			if (!isset($td[$dValue["resampleID"]][$dValue["original"]])) {
				$td[$dValue["resampleID"]][$dValue["original"]] = array();
				$td[$dValue["resampleID"]][$dValue["original"]]["classes"] = array();
			}

			if (!isset($td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]])) {
				$td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]] = array();
			}

			if (!isset($td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]][$class_original])) {
				$td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]][$class_original] = array();
			}

			$dValue["value_type"] = str_replace("_class", "", $dValue["value_type"]);
			$dValue["value_type"] = str_replace("_column", "", $dValue["value_type"]);

			$finalItem = ["type" => $dValue["value_type"], "value" => floatval($dValue["value"])];

			if (!isset($td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]][$class_original][$mapping])) {
				$td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]][$class_original][$mapping] = $finalItem;
			} else {
				if ($mapping === "prop") {
					$previus = $td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]][$class_original][$mapping];
					$newItem = "";

					if ($dValue["value_type"] === "numeric") {
						$newItem = ($previus["value"] * 100) . "% (" . $dValue["value"] . ")";
					} else if (is_array($previus)) {
						$val1 = floatval($dValue["value"]);
						$val2 = floatval($previus["value"]);
						$newItem = ($val1 * 100) . "% (" . $val2 . ")";

					}
					if ($newItem !== "") {
						$td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]][$class_original][$mapping] = $newItem;
					}

				}

				if ($mapping === "details") {
					$previus = $td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]][$class_original][$mapping];

					if (is_array($previus)) {
						$newItem = $previus["value"] . " " . $previus["type"] . " <br /> " . $dValue["value"] . " " . $dValue["value_type"] . " ";
					} else {
						$newItem = $previus . " - " . $dValue["value"] . " " . $dValue["value_type"] . "";
					}

					$td[$dValue["resampleID"]][$dValue["original"]]["classes"][$dValue["dataset"]][$class_original][$mapping] = $newItem;
				}
			}

		}

		foreach ($resamplesList as $resamplesListKey => $resamplesListValue) {
			if (isset($td[$resamplesListValue["resampleID"]])) {
				$resamplesList[$resamplesListKey]["proportions"] = [];
				foreach ($td[$resamplesListValue["resampleID"]] as $propKey => $propValue) {
					$resamplesList[$resamplesListKey]["proportions"][] = array_merge(["label" => $propKey], $propValue);
				}
			}
		}

		return $resamplesList;
	}

	/**
	 * [getDatasetResamplesProportions description]
	 * @param  [type] $drids dataset resamples ids
	 * @return [type]        [description]
	 */
	public function getDatasetResamplesProportions($drids) {

		$drids = join(',', array_map('intval', $drids));

		$sql = " SELECT dataset_proportions.id                     AS proportionID,
				       dataset_proportions.drid                   AS resampleID,
				       dataset_proportions.class_name             AS column_remapped,
				       CASE
				         WHEN dataset_proportions.feature_set_type = 1 THEN 'training'
				         WHEN dataset_proportions.feature_set_type = 2 THEN 'testing'
				         ELSE 'validation'
				       END                                        AS dataset,

				       IF(drm1.class_original IS NULL, drm2.class_original, drm1.class_original) AS class_original,
					   IF(drm1.class_remapped IS NULL, drm2.class_remapped, drm1.class_remapped) AS class_remapped,

				       CASE
				         WHEN dataset_proportions.measurement_type = 1 THEN 'numeric'
				         WHEN dataset_proportions.measurement_type = 2 THEN 'percentage'

				         WHEN dataset_proportions.measurement_type = 3 AND dataset_proportions.value = '' THEN 'median_column'
				         WHEN dataset_proportions.measurement_type = 4 AND dataset_proportions.value = '' THEN 'min_column'
				         WHEN dataset_proportions.measurement_type = 5 AND dataset_proportions.value = '' THEN 'max_column'
				         #WHEN dataset_proportions.measurement_type = 6 AND dataset_proportions.value = '' THEN 'unique_column'
				         #WHEN dataset_proportions.measurement_type = 7 AND dataset_proportions.value = '' THEN 'total_column'

				         WHEN dataset_proportions.measurement_type = 3 AND dataset_proportions.value != '' THEN 'median_class'
				         WHEN dataset_proportions.measurement_type = 4 AND dataset_proportions.value != '' THEN 'min_class'
				         WHEN dataset_proportions.measurement_type = 5 AND dataset_proportions.value != '' THEN 'max_class'
				         #WHEN dataset_proportions.measurement_type = 6 AND dataset_proportions.value != '' THEN 'unique_class'
				         #WHEN dataset_proportions.measurement_type = 7 AND dataset_proportions.value = '' THEN 'total_class'

				         ELSE NULL
				       END                                        AS value_type,
				       dataset_proportions.result                 AS value
				FROM   dataset_proportions
				       left outer join dataset_resamples_mappings drm1
				                    ON dataset_proportions.drid = drm1.drid
				                       AND dataset_proportions.class_name = drm1.class_column
				                       AND dataset_proportions.value = drm1.class_remapped
				       left outer join dataset_resamples_mappings as drm2
				                    ON dataset_proportions.drid = drm2.drid
				                       AND dataset_proportions.proportion_class_name = drm2.class_column
				                       AND dataset_proportions.value = drm2.class_remapped

				WHERE  dataset_proportions.drid  IN (" . $drids . ") AND dataset_proportions.measurement_type IN(1,2,3,4,5) ORDER BY measurement_type ASC;";

		$details = $this->database->query($sql)->fetchAll(\PDO::FETCH_ASSOC);
		$details = $this->Helpers->castArrayValues($details);

		return ($details);

	}

	/**
	 * [getUniqueValuesCountForClasses description]
	 * @param  [type] $resampleIDs [description]
	 * @param  [type] $classes     [description]
	 * @return [type]              [description]
	 */
	public function getUniqueValuesCountForClasses($resampleIDs, $classes) {

		$details = $this->database->select($this->table_name,
			["class_name",
				"result" => Medoo::raw('SUM(<result>)'),
			],
			[
				"measurement_type" => 6,
				"class_name" => array_column($classes, 'remapped'),
				"drid" => $resampleIDs,
				'GROUP' => [
					'class_name',
					'proportion_class_name',
				],
			]);
		// Map sql sum values into classes array
		foreach ($classes as $classesKey => $classesValue) {
			foreach ($details as $detailsItem) {
				if ($detailsItem["class_name"] === $classesValue["remapped"]) {
					$classes[$classesKey]["unique"] = intval($detailsItem["result"]);
					break;
				}
			}
		}
		return ($classes);
	}
}
