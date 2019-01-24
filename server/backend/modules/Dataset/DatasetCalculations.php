<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-10 09:00:54
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
	// selectedFiles: this.submitJobForm["selectedFiles"],
	// feature: feature,
	// isLast: isLast
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
