<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2020-04-07 13:20:23
 */
namespace SIMON\Dataset;

use League\Csv\Reader;
use League\Csv\Statement;
use League\Csv\Writer;
use Noodlehaus\Config as Config;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;

class DatasetIntersection {

	protected $logger;
	protected $Config;
	protected $Helpers;

	public $outcomeColumn = "";
	public $selectedFeatures = [];
	// Used for saving temporary uploaded files
	private $temp_dir = "/tmp";

	public function __construct(
		Logger $logger,
		Config $Config,
		Helpers $Helpers
	) {

		$this->logger = $logger;
		$this->Config = $Config;
		$this->Helpers = $Helpers;

		$this->temp_dir = sys_get_temp_dir() . "/" . $this->Config->get('default.salt') . "/uploads";
		$this->logger->addInfo("==> INFO => SIMON\Dataset\DatasetIntersection constructed: " . $this->temp_dir);

		if (!file_exists($this->temp_dir)) {
			$this->Helpers->createDirectory($this->temp_dir);
		}
	}

	/**
	 * [array_remove_keys description]
	 * @param  [type] $array [description]
	 * @param  [type] $keys  [description]
	 * @return [type]        [description]
	 */
	public function array_remove_keys($array, $keys) {

		// array_diff_key() expected an associative array.
		$assocKeys = array();
		foreach ($keys as $key) {
			$assocKeys[$key] = true;
		}

		return array_diff_key($array, $assocKeys);
	}

	/**
	 * Create new Resample Dataset from Intersect Calculation
	 * Creates new CSV files from original file and keeps only columns and samples for specific intersection
	 * @param  [type] $queueID            [description]
	 * @param  [type] $tempFilePath       [description]
	 * @param  [type] $resamples          [description]
	 * @param  [type] $allOtherSelections [description]
	 * @return [type]                     [description]
	 */
	public function generateResamples($queueID, $tempFilePath, $queuesGenerated, $allOtherSelections) {
		$datasets = array();

		$reader = Reader::createFromPath($tempFilePath, 'r');
		$reader->setHeaderOffset(0);
		$dataHeader = $reader->getHeader();

		$stmt = (new Statement())
			->offset(0);

		$records = $stmt->process($reader);

		// Loop all records in original FILE
		foreach ($records as $recordID => $record) {
			$recordColumns = array_keys($record);

			// Loop all different queues
			foreach ($queuesGenerated as $queueKey => $queueValue) {

				// Loop all created intersections
				foreach ($queueValue["data"] as $resampleGroupDataKey => $resampleGroupDataValue) {
					if (!isset($datasets[$resampleGroupDataKey])) {
						$filename = 'genSysFile_queue_' . $queueID . '_group_' . $queueKey . '_resample_' . $resampleGroupDataKey . '.csv';
						$queuesGenerated[$queueKey]["data"][$resampleGroupDataKey]["resamplePath"] = $this->temp_dir . '/' . $filename;

						$datasets[$resampleGroupDataKey] = array(
							"header" => false,
							"writer" => Writer::createFromPath($queuesGenerated[$queueKey]["data"][$resampleGroupDataKey]["resamplePath"], 'w+'),
						);
					}

					$listFeatures = $resampleGroupDataValue["listFeatures"];

					$ourColumns = array_merge($listFeatures, $allOtherSelections);
					$keepColumns = array_intersect($ourColumns, $recordColumns);
					$keepColumns = array_flip($keepColumns);

					// Every resample has different record header! Make a copy
					$recordCopy = $record;
					foreach ($recordCopy as $recordKey => $recordValue) {

						if (!isset($keepColumns[$recordKey])) {
							unset($recordCopy[$recordKey]);
						}
					}
					ksort($recordCopy, SORT_NATURAL);

					$listSamples = $resampleGroupDataValue["listSamples"];
					foreach ($listSamples as $sampleRange) {
						$range = explode("-", $sampleRange);

						if (isset($range[0]) && !isset($range[1])) {
							$range[1] = $range[0];
						}

						$range = array_map('intval', $range);

						if (($range[0] <= $recordID) && ($recordID <= $range[1])) {

							if ($datasets[$resampleGroupDataKey]["header"] === false) {
								$datasets[$resampleGroupDataKey]["header"] = true;
								$datasets[$resampleGroupDataKey]["writer"]->setFlushThreshold(1);
								$datasets[$resampleGroupDataKey]["writer"]->insertOne(array_keys($recordCopy));
							}

							try {
								$datasets[$resampleGroupDataKey]["writer"]->insertOne(array_values($recordCopy));
							} catch (CannotInsertRecord $e) {
								$this->logger->addInfo("==> ERROR => SIMON\Dataset\DatasetIntersection CannotInsertRecord " . $queueID . ": " . json_encode($e->getData()));
							}
						}
					}

				} // resample loop
			}
		}
		return ($queuesGenerated);
	}

	/**
	 * [removeEmptyOutcomeValues description]
	 * @param  array  $record [description]
	 * @return [type]         [description]
	 */
	public function removeEmptyOutcomeValues(array $record): bool {
		if (isset($record[$this->outcomeColumn]) && trim($record[$this->outcomeColumn]) === "") {
			return (bool) false;
		}
		return (bool) true;
	}

	/**
	 * Removes all non numbers
	 * @param  array  $record [description]
	 * @return [type]         [description]
	 */
	public function removeEmptyValues(array $record): bool {
		foreach (array_keys($this->selectedFeatures) as $featureIndex) {
			if (isset($record[$featureIndex]) && !is_numeric($record[$featureIndex])) {
				return (bool) false;
			}
		}
		return (bool) true;
	}

	/**
	 * generateDataPresets
	 *
	 * Generates JSON (JavaScript Object Notation ) file with
	 * MySQL commands that are necessarily to generate
	 * input vectors of shared data
	 * All other JSON keys except "sql" are just informational
	 *
	 * @param  [string] $outcome [table column containing outcome variable]
	 * @return [string]          [path to the file containing results]
	 */
	public function generateDataPresets($filePath, $outcome, $features, $extraction) {

		$data = [];
		$headerMapping = [];

		$reader = Reader::createFromPath($filePath, 'r');
		// $delimiter = $this->Helpers->detectDelimiter($filePath);
		// $reader->setDelimiter($delimiter);

		$reader->setHeaderOffset(0);
		$dataHeader = $reader->getHeader();
		// file_put_contents("/mnt/genular/simon-backend/SHARED_DATA/uploads/data", implode(',', $dataHeader));
		// exit;
		$this->outcomeColumn = $outcome["remapped"];

		foreach ($features as $feature) {
			if (!isset($this->selectedFeatures[$feature])) {
				$this->selectedFeatures[$feature] = true;
			}
		}

		$stmt = (new Statement())
			->offset(0)
			->where([$this, 'removeEmptyOutcomeValues']);

		// If we are not doing dataset extraction remove all samples/rows that have empty values (non-numerc)

		$records = $stmt->process($reader);
		$samples = array();

		$totalDatapoints = 0;
		$missingDatapoints = 0;
		$sparsity = 0;
		$invalidColumns = [];

		if (count($records) > 0) {
			foreach ($records as $sampleID => $record) {

				if (!isset($samples[$sampleID])) {
					$samples[$sampleID] = array();
				}

				foreach ($record as $recordID => $recordValue) {

					// If column is not in user desired features list skip it
					if (!isset($this->selectedFeatures[$recordID]) || $recordID === $this->outcomeColumn) {
						continue;
					}
					// Map column name to column number
					if (!isset($headerMapping[$recordID])) {
						$headerMapping[$recordID] = array_search($recordID, $dataHeader);
					}
					$isNumeric = is_numeric($recordValue);

					if (!isset($samples[$sampleID][$recordID]) && $isNumeric) {
						$samples[$sampleID][$recordID] = true;
					}

					if (!$isNumeric) {
						$missingDatapoints++;

						if (!isset($invalidColumns[$recordID]) && ctype_alpha($recordValue) || $recordValue === "") {
							$invalidColumns[$recordID] = true;
						}
					}
					$totalDatapoints++;
				}
			}
			if ($missingDatapoints > 0 || $totalDatapoints > 0) {
				$sparsity = ($missingDatapoints / $totalDatapoints);
				$sparsity = round($sparsity, 2);
			}
		} else {
			$sparsity = 1;
		}

		$invalidColumns = array_keys($invalidColumns);

		/** Sort an array by key - Sort subjects by their ID */
		ksort($samples, SORT_NATURAL);

		/** Remove variable thats holding all available data */
		unset($records);

		/** Placeholder for combination across different
		 * subject feature sets
		 */
		$featureSets = array();

		/** Placeholder for combination across different
		 * shared subject feature sets
		 */
		$featureSetsShared = array();
		$totalMultiSetsIntersections = 0;

		$i = 0;
		foreach ($samples as $sampleID => $sampleFeatures) {
			// Limit to maximum number of datasets
			if ($totalMultiSetsIntersections >= 200) {
				continue;
			}

			$sampleFeatures = array_keys($sampleFeatures);

			if ($extraction === false && count($invalidColumns) > 0) {
				$sampleFeatures = array_diff($sampleFeatures, $invalidColumns);
				if (count($sampleFeatures) < 1 || empty($sampleFeatures)) {
					continue;
				}
			}

			/** Sort an array by key - Maintain sorting order
			 * of Features so we can use them in hashing algorithm
			 */
			ksort($sampleFeatures, SORT_NATURAL);

			/** Calculate unique donor features identifier by
			 * using MD5 hashing algorithm
			 */
			$featuresID = hash('sha512', implode(',', $sampleFeatures));

			if (!isset($featureSets[$featuresID])) {
				$featureSets[$featuresID] = $sampleFeatures;
			} else {
				continue;
			}
			ksort($featureSets, SORT_NATURAL);

			foreach ($featureSets as $featuresTempID => $featuresTempValue) {
				$featuresShared = array_intersect(
					$featuresTempValue, $sampleFeatures);

				if (!empty($featuresShared)) {
					ksort($featuresShared, SORT_NATURAL);
					$featuresSharedID = hash('sha512', implode(',', $featuresShared));

					if (!isset($featureSetsShared[$featuresSharedID])) {
						$featureSetsShared[$featuresSharedID] = array(
							'totalFeatures' => count($featuresShared),
							'listFeatures' => array_values($featuresShared),
							'listSamples' => [],
							'totalSamples' => 0,
							'totalDatapoints' => 0,
							'isSelected' => true, // Is preselected on front-end?
							'isValid' => true, // False if there are some errors
							'message' => [], // Array of errors in question
							'resamplePath' => false
						);
						$totalMultiSetsIntersections++;
					}
				}
			}
			$i++;
		}

		// Get number of samples for each feature set
		foreach ($featureSetsShared as $key => $value) {
			foreach ($samples as $sampleKey => $sampleValue) {
				$featuresShared = array_intersect(
					$value["listFeatures"], array_keys($sampleValue));

				if (count($featuresShared) === $value["totalFeatures"]) {
					$featureSetsShared[$key]['totalSamples'] += 1;
					array_push($featureSetsShared[$key]['listSamples'], $sampleKey);
				}
			}
			$featureSetsShared[$key]['totalDatapoints'] = ($featureSetsShared[$key]['totalSamples'] * $featureSetsShared[$key]['totalFeatures']);
			$featureSetsShared[$key]['listSamples'] = $this->generateRanges($featureSetsShared[$key]['listSamples']);
		}

		if (!empty($featureSetsShared)) {
			$data = array_values($featureSetsShared);
			// Sort data by number of totalSamples (more samples first!)
			usort($data, function ($item1, $item2) {
				return $item2['totalSamples'] <=> $item1['totalSamples'];
			});
		}

		return array("resamples" => $data, "info" => array("sparsity" => $sparsity, "missingDatapoints" => $missingDatapoints, "totalDatapoints" => $totalDatapoints, "invalidColumns" => $invalidColumns));
	}

	/**
	 * [generateRanges description]
	 * @param  [type] $aNumbers [description]
	 * @return [type]           [description]
	 */
	public function generateRanges($aNumbers) {
		$aNumbers = array_unique($aNumbers);
		sort($aNumbers);
		$aGroups = array();
		for ($i = 0; $i < count($aNumbers); $i++) {
			if ($i > 0 && ($aNumbers[$i - 1] == $aNumbers[$i] - 1)) {
				array_push($aGroups[count($aGroups) - 1], $aNumbers[$i]);
			} else {
				array_push($aGroups, array($aNumbers[$i]));
			}
		}
		$aRanges = array();
		foreach ($aGroups as $aGroup) {
			if (count($aGroup) == 1) {
				$aRanges[] = $aGroup[0];
			} else {
				$aRanges[] = $aGroup[0] . '-' . $aGroup[count($aGroup) - 1];
			}

		}
		return $aRanges;
	}
}
