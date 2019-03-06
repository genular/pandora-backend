<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-06 10:45:53
 */
namespace SIMON\System;

// PSR 7 standard.
use GuzzleHttp\Client as HTTPClient;
use GuzzleHttp\RequestOptions;
use Noodlehaus\Config as Config;
use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;

class System {
	protected $database;
	protected $logger;

	protected $Config;
	protected $HTTPClient;
	protected $Helpers;

	protected $tables = [
		"dataset_proportions",
		"dataset_queue",
		"dataset_resamples",
		"models",
		// "models_packages",
		"models_performance",
		"models_performance_variables",
		"models_variables",
		"organization",
		"organization_details",
		"users",
		"users_apps",
		"users_details",
		"users_files",
		"users_organization",
		"users_sessions"];

	public function __construct(
		Medoo $database,
		Logger $logger,
		Config $Config,
		HTTPClient $HTTPClient,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Config = $Config;
		$this->HTTPClient = $HTTPClient;
		$this->Helpers = $Helpers;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\System constructed");
	}

	/**
	 * Initialize the system
	 * @return [type] [description]
	 */
	public function init() {
		$this->logger->addInfo("==> INFO: SIMON\System initializing");
		$this->initModelPerformanceVariables();
		$this->initModelsPacakges();
	}

	/**
	 * Reset system data
	 * @return [type] [description]
	 */
	public function reset() {
		foreach ($this->tables as $table) {
			$this->logger->addInfo("==> INFO: SIMON\System deleting records from: " . $table);
			$this->database->delete($table, []);
		}
	}

	/**
	 * Checks if field is in database
	 * @param  [type] $validationTable [description]
	 * @param  [type] $validationField [description]
	 * @param  [type] $validationValue [description]
	 * @return [type]                  [description]
	 */
	public function databaseAvailability($validationTable, $validationField, $validationValue) {
		$columns = [
			'id',
		];
		$conditions = [
			$validationField => $validationValue,
		];
		$field_id = $this->database->get($validationTable, $columns, $conditions);

		return ($field_id);
	}

	/**
	 * List of all model performance measures
	 * @return [type] [description]
	 */
	private function initModelPerformanceVariables() {
		$this->database->insert("models_performance_variables", [
			["value" => "Accuracy"],
			["value" => "AccuracyLower"],
			["value" => "AccuracyNull"],
			["value" => "AccuracyPValue"],
			["value" => "AccuracyUpper"],
			["value" => "Balanced Accuracy"],
			["value" => "Detection Prevalence"],
			["value" => "Detection Rate"],
			["value" => "F1"],
			["value" => "Kappa"],
			["value" => "McnemarPValue"],
			["value" => "Neg Pred Value"],
			["value" => "Pos Pred Value"],
			["value" => "PositiveControl"],
			["value" => "Precision"],
			["value" => "PredictAUC"],
			["value" => "Prevalence"],
			["value" => "Recall"],
			["value" => "Sensitivity"],
			["value" => "Specificity"],
			["value" => "TrainAccuracy"],
			["value" => "TrainAUC"],
			["value" => "TrainBalanced_Accuracy"],
			["value" => "TrainDetection_Rate"],
			["value" => "TrainF1"],
			["value" => "TrainKappa"],
			["value" => "TrainlogLoss"],
			["value" => "TrainNeg_Pred_Value"],
			["value" => "TrainPos_Pred_Value"],
			["value" => "TrainprAUC"],
			["value" => "TrainPrecision"],
			["value" => "TrainRecall"],
			["value" => "TrainSensitivity"],
			["value" => "TrainSpecificity"],
		]);
	}

	/**
	 * [initModelsPacakges description]
	 * @return [type] [description]
	 */
	private function initModelsPacakges() {
		$status = false;
		$data = [];
		$packages = [];

		$endpoint = $this->Config->get('default.analysis.server.url') . "/analysis/other/available-packages";
		$this->logger->addInfo("==> INFO: SIMON\System\initModelsPacakges fetching packages from: " . $endpoint);

		try {
			$res = $this->HTTPClient->request('GET', $endpoint, ['verify' => false, 'allow_redirects' => true, 'connect_timeout' => 1200, 'timeout' => 1200, 'debug' => false]);
			if ($res->getStatusCode() === 200) {
				if ($res->getBody()) {
					$data = $res->getBody()->getContents();
					$data = json_decode($data, true);
					if (is_array($data) && isset($data["data"])) {
						$data = $data["data"];
					}
				}
			}
		} catch (\GuzzleHttp\Exception\ServerException $e) {
			$httpError = $e->getResponse()->getBody()->getContents();
			$this->logger->error("SIMON\System initModelsPacakges ClientException " . $httpError);
		}

		if (count($data) > 0) {
			$status = true;
			foreach ($data as $package_key => $package_value) {
				$tuning_parameters = [];
				if (isset($package_value["tuning_parameters"]) and is_array($package_value["tuning_parameters"])) {
					if (is_array($package_value["tuning_parameters"]["parameter"])) {
						foreach ($package_value["tuning_parameters"]["parameter"] as $t_key => $t_value) {
							if (!isset($tuning_parameters[$t_key])) {
								$tuning_parameters[$t_key] = array(
									"id" => $t_value,
									"class" => $package_value["tuning_parameters"]["class"][$t_key],
									"label" => $package_value["tuning_parameters"]["label"][$t_key],
								);
							}
						}
					} else {
						$tuning_parameters[] = array(
							"id" => $package_value["tuning_parameters"]["parameter"],
							"class" => $package_value["tuning_parameters"]["class"],
							"label" => $package_value["tuning_parameters"]["label"],
						);
					}
				}

				$dependencies = (is_array($package_value["dependencies"]) ? $package_value["dependencies"] : [$package_value["dependencies"]]);
				$tags = (is_array($package_value["tags"]) ? $package_value["tags"] : [$package_value["tags"]]);

				$package = array(
					"internal_id" => $package_key,
					"label" => (isset($package_value["label"]) ? $package_value["label"] : ""),
					"dependencies" => (count($dependencies) > 0 ? json_encode($dependencies) : Medoo::raw("NULL")),
					"classification" => intval($package_value["classification"]),
					"regression" => intval($package_value["regression"]),
					"tags" => (count($tags) > 0 ? json_encode($tags) : Medoo::raw("NULL")),
					"tuning_parameters" => (count($tuning_parameters) > 0 ? json_encode($tuning_parameters) : Medoo::raw("NULL")),
					"citations" => json_encode($package_value["citations"]),
					"time_per_million" => Medoo::raw("NULL"),
					"documentation" => Medoo::raw("NULL"),
					"r_version" => $package_value["r_version"],
					"installed" => intval($package_value["installed"]),
					"created" => Medoo::raw("NOW()"),
				);

				if (!isset($packages[$package_key])) {
					$packages[$package_key] = $package;
				}
			}
			$packages = array_values($packages);
			$this->database->insert("models_packages", $packages);
		}
		return $status;
	}

	/**
	 * [scrapeHelpDocumentation description]
	 * @return [type] [description]
	 */
	public function scrapeHelpDocumentation() {
		$columns = [
			"id",
			"internal_id",
			"dependencies",
		];
		$conditions = [
			"documentation" => null,
		];

		$details = $this->database->select("models_packages", $columns, $conditions);

		$htmlParser = new \DOMDocument;
		$htmlParser->preserveWhiteSpace = false;
		$htmlParser->formatOutput = true;
		libxml_use_internal_errors(true);

		// Loop all packages and download documentation
		foreach ($details as $package) {
			$package_name = $package["internal_id"];
			$dependencies = json_decode($package["dependencies"], true);

			if ($dependencies !== null && !in_array($package_name, $dependencies)) {
				// Select closest dependence by calculating levenshtein
				$input = $package_name;
				// no shortest distance found, yet
				$shortest = -1;
				// loop through words to find the closest
				foreach ($dependencies as $word) {
					// calculate the distance between the input word,
					// and the current word
					$lev = levenshtein($input, $word);
					// check for an exact match
					if ($lev == 0) {
						// closest word is this one (exact match)
						$closest = $word;
						$shortest = 0;
						// break out of the loop; we've found an exact match
						break;
					}
					// if this distance is less than the next found shortest
					// distance, OR if a next shortest word has not yet been found
					if ($lev <= $shortest || $shortest < 0) {
						// set the closest match, and shortest distance
						$closest = $word;
						$shortest = $lev;
					}
				}
				$package_name = $closest;
			}

			$packageDocumentationURL = "";
			$packageDocumentationHTML = "";
			$latestPackageVersion = "";
			$responseError = "";

			try {
				// 1st get documentation URL
				$requestResults = $this->HTTPClient->request('POST', "https://www.rdocumentation.org/rstudio/view?viewer_pane=1",
					['verify' => false,
						'allow_redirects' => true,
						'connect_timeout' => 1200,
						'timeout' => 1200,
						'debug' => false,
						'headers' =>
						[
							'Accept' => "text/html",
							'User-Agent' => "rstudio",
							'Content-Type' => "application/json",
						],
						RequestOptions::JSON => ['called_function' => 'find_package', 'package_name' => $package_name],
					]);

				if ($requestResults->getStatusCode() === 200) {
					$htmlPage = $requestResults->getBody()->getContents();
					$htmlParser->loadHTML($htmlPage);

					$sections = $htmlParser->getElementsByTagName('section');
					foreach ($sections as $section) {
						// get the class attr
						$attribute = $section->getAttribute('data-uri');
						if ($attribute !== "") {
							$packageDocumentationURL = "https://www.rdocumentation.org" . $attribute;
							if (($pos = strpos($attribute, "versions/")) !== FALSE) {
								$latestPackageVersion = substr($attribute, $pos);
								$latestPackageVersion = str_replace("versions/", "", $latestPackageVersion);
							}
						}
					}
				}
			} catch (\GuzzleHttp\Exception\ClientException $e) {}

			// 2nd Download documentation from URL
			if ($packageDocumentationURL !== "") {
				$requestResults = $this->HTTPClient->request('GET', $packageDocumentationURL . "/topics/" . $package_name,
					['verify' => false,
						'allow_redirects' => true,
						'connect_timeout' => 1200,
						'timeout' => 1200,
						'debug' => false,
						'headers' =>
						[
							'Accept' => "text/html",
							'User-Agent' => "rstudio",
						],
					]);

				if ($requestResults->getStatusCode() === 200) {
					$packageDocumentation = $requestResults->getBody()->getContents();
					$htmlParser->loadHTML($packageDocumentation);

					$finder = new \DomXPath($htmlParser);
					$classname = "container";
					$nodes = $finder->query("//*[contains(concat(' ', normalize-space(@class), ' '), ' $classname ')]");

					$tmp_dom = new \DOMDocument();
					foreach ($nodes as $node) {
						$tmp_dom->appendChild($tmp_dom->importNode($node, true));
					}
					$packageDocumentationHTML .= trim($tmp_dom->saveHTML());

					$this->database->update("models_packages", [
						"documentation" => json_encode(
							["packageName" => $package_name,
								"packageVersion" => $latestPackageVersion,
								"html_content" => $packageDocumentationHTML]
						),
					], [
						"id" => $package["id"],
					]);
				}
			}
		}
	}
}
