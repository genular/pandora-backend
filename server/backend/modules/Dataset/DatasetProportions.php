<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-04-15 10:31:21
 */
namespace PANDORA\Dataset;

use \Medoo\Medoo;
use \Monolog\Logger;
use \PANDORA\Helpers\Helpers as Helpers;

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
		$this->logger->addInfo("==> INFO: PANDORA\Dataset\DatasetProportions constructed");
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
	 * For each proportion column add additional array key "original" and put original column name in it column7 => Outcome
	 * @param  string $searchColumn    [description]
	 * @param  array $searchArray     [description]
	 * @param  array $selectedOptions Array containing original values
	 * @return array
	 */
	public function mapRenamedToOriginal($searchColumn, $searchArray, $selectedOptions) {
		$mappingExist = false;
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
								if ($mappingExist === false) {
									$mappingExist = true;
								}
								break 2;
							}
						}
					}
				}

			}
		}
		// No mapping detected this means we made PCA or some other preprocessing method and set our own column names
		if ($mappingExist === false) {
			foreach ($searchArray as $searchArrayKey => $searchArrayValue) {
				$searchArray[$searchArrayKey]["original"] = $searchArrayValue[$searchColumn];
			}
		}
		return $searchArray;
	}

	/**
	 * Converts proportions generated by getDatasetResamplesProportions() to json object
	 * @param  array $resamplesProportions [description]
	 * @param  array $resamplesList        [description]
	 * @return array                       [description]
	 */
	public function mergeProportions($resamplesProportions, $resamplesList) {
		$td = [];
		$uniqueValues = [];

		// Loop all proportions from database and map it to resample
		foreach ($resamplesProportions as $dKey => $dValue) {

			if (!isset($td[$dValue["resampleID"]])) {
				$td[$dValue["resampleID"]] = [];
			}
			$class_original = $dValue["class_original"];

			// Additional exploration classes. So no Outcome but user selected one like Age/Gender...
			// Lets put those with global prefix
			if (trim($class_original) === "") {
				$class_original = "global";
				//$dValue["dataset"] = "global";
			}

			if (!isset($td[$dValue["resampleID"]][$dValue["original"]])) {
				$td[$dValue["resampleID"]][$dValue["original"]] = array();
			}
			if (!isset($td[$dValue["resampleID"]][$dValue["original"]][$dValue["dataset"]])) {
				$td[$dValue["resampleID"]][$dValue["original"]][$dValue["dataset"]] = array();
			}

			$dValue["value_type"] = str_replace("_class", "", $dValue["value_type"]);
			$dValue["value_type"] = str_replace("_column", "", $dValue["value_type"]);

			$hashKeep = array("percentage", "numeric");
			if ($class_original !== "global" && in_array($dValue["value_type"], $hashKeep)) {
				$uniquehash = md5($dValue["original"]);
				if (!isset($uniqueValues[$uniquehash])) {
					$uniqueValues[$uniquehash] = [];
				}
				if (!isset($uniqueValues[$uniquehash][$class_original])) {
					$uniqueValues[$uniquehash][$class_original] = true;
				}
			}
			// Outcome=>training=>A
			if (!isset($td[$dValue["resampleID"]][$dValue["original"]][$dValue["dataset"]][$dValue["value_type"]])) {
				$td[$dValue["resampleID"]][$dValue["original"]][$dValue["dataset"]][$dValue["value_type"]] = [];
			}
			if (!isset($td[$dValue["resampleID"]][$dValue["original"]][$dValue["dataset"]][$dValue["value_type"]][$class_original])) {
				$td[$dValue["resampleID"]][$dValue["original"]][$dValue["dataset"]][$dValue["value_type"]][$class_original] = $dValue["value"];
			} else {
				var_dump("proportions error");
				var_dump($dValue);
				exit;
			}
		}

		// Add all collected unique labels to items
		foreach ($td as $dKey => $dValue) {
			foreach ($dValue as $dValueKey => $dValueVal) {
				$uniquehash = md5($dValueKey);
				if (isset($uniqueValues[$uniquehash])) {
					$td[$dKey][$dValueKey]["unique_labels"] = array_keys($uniqueValues[$uniquehash]);
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

				       COALESCE(drm2.class_original, drm1.class_original, dataset_proportions.value) AS class_original,
					   COALESCE(drm2.class_remapped, drm1.class_remapped, dataset_proportions.value) AS class_remapped,

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
	public function getUniqueValuesCountForClasses(array $resampleIDs, array $classes): array {
		// Check if $resampleIDs or $classes array is empty and return early if true.
		if (empty($resampleIDs) || empty($classes)) {
			return [];
		}
	
		$details = $this->database->select(
			$this->table_name,
			[
				"class_name",
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
			]
		);
	
		// Map SQL sum values into classes array
		foreach ($classes as $classesKey => &$classesValue) {
			$isClassMapped = false;
			foreach ($details as $detailsItem) {
				if ($detailsItem["class_name"] === $classesValue["remapped"]) {
					$classesValue["unique"] = intval($detailsItem["result"]);
					$isClassMapped = true;
					break;
				}
			}
	
			// In case we didn't make a mapping since database values are missing, add unique value manually
			if (!$isClassMapped) {
				$this->logger->addError("==> ERROR: PANDORA\Dataset\DatasetProportions\getUniqueValuesCountForClasses cannot find mapping: " . $classesKey . " - " . implode(",", $resampleIDs));
				$classesValue["unique"] = 0;
			}
		}
		unset($classesValue); // End reference to avoid unexpected behavior later
	
		return $classes;
	}	
}
