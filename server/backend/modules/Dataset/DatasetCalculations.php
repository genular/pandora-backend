<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-15 12:09:37
 */
namespace SIMON\Dataset;

use League\Csv\Reader;
use League\Csv\Statement;
use \Medoo\Medoo;
use \Monolog\Logger;

class DatasetCalculations {
	protected $database;
	protected $logger;

	public function __construct(
		Medoo $database,
		Logger $logger
	) {
		$this->database = $database;
		$this->logger = $logger;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\Dataset\DatasetCalculations constructed");
	}
	/**
	 * Checks if we have good sample size
	 * @param  [type] $resamples      [description]
	 * @param  [type] $partitionSplit [description]
	 * @return [type]                 [description]
	 */
	public function validateSampleSize($resamples, $partitionSplit) {
		// Loop all created intersections
		foreach ($resamples as $resampleGroupDataKey => $resampleGroupDataValue) {
			$isResampleValid = true;
			$message = [];
			$totalSamples = $resampleGroupDataValue["totalSamples"];

			// Number of samples in Test set
			$minimumSamples = ($totalSamples * (100 - $partitionSplit)) / 100;
			$minimumSamples = round($minimumSamples);
			
			if ($minimumSamples < 5) {
				array_push($message, ["msg_info" => "invalid_sample_count_test", "data" => $minimumSamples]);
				$isResampleValid = false;
			}
			if ($isResampleValid === false) {
				$resamples[$resampleGroupDataKey]["isValid"] = false;
				$resamples[$resampleGroupDataKey]["isSelected"] = false;
				$resamples[$resampleGroupDataKey]["message"] = $message;
			}
		}
		return $resamples;
	}

	/**
	 * [preCSVCalculations description]
	 * @param  [type] $submitData [description]
	 * @param  [type] $filePath   [description]
	 * @return [type]             [description]
	 */
	public function preCSVCalculations($submitData, $filePath) {

		$results = [
			"name" => $submitData["feature"],
			"unique" => 0,
			"total" => 0,
			"naValues" => [],
			"totalNaValues" => 0,
			"dataType" => "numeric",
		];
		$unique_placeholder = [];

		$reader = Reader::createFromPath($filePath, 'r');
		$reader->setHeaderOffset(0);
		$results["total"] = count($reader);

		$records = (new Statement())->process($reader);

		$csv_header = $records->getHeader();
		$column_index = array_search($results["name"], $csv_header);

		foreach ($records->fetchColumn($column_index) as $offset => $value) {
			if (!isset($unique_placeholder[$value])) {
				$unique_placeholder[$value] = true;
				$results["unique"]++;
			}

			$isNumeric = is_numeric($value) ? true : false;

			if ($isNumeric === true && $results["dataType"] !== "numeric") {
				$results["dataType"] = "mixed";
			} else if ($isNumeric === false && $results["dataType"] === "numeric") {
				$results["dataType"] = "string";
			}

			if ($isNumeric === false) {
				$results["naValues"][] = $offset;
			}
		}
		$results["totalNaValues"] = count($results["naValues"]);

		return ($results);
	}

}
