<?php

/**
 * @Author: LogIN-
 * @Date:   2018-06-26 13:41:55
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-24 13:43:14
 */
use Slim\Http\Request;
use Slim\Http\Response;

/** Get all Servers
 * Returns all existing server objects.
 * http://127.0.0.1:8186/backend/system/servers/1/servers
 */
$app->get('/backend/system/servers/{providerID:.*}/servers', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("SIMON '/system/status/{secret:.*}' route");
	$success = false;

	$system = $this->get('SIMON\System\System');
	$config = $this->get('Noodlehaus\Config');

	$providerID = $args['providerID'];

	$access_token = $config->get('default.cloud_providers.hetzner.analysis');

	$HTTPClient = $this->get('GuzzleHttp\Client');
	$endpiont = "https://api.hetzner.cloud/v1/servers";

	try {
		$res = $HTTPClient->request('GET', $endpiont,
			['verify' => false,
				'allow_redirects' => true,
				'connect_timeout' => 1200,
				'timeout' => 1200,
				'debug' => false,
				'headers' =>
				[
					'Authorization' => "Bearer " . $access_token,
				],
			]);
		if ($res->getStatusCode() !== 200) {
			$success = false;
		} else {
			if ($res->getBody()) {
				$success = true;
				$data = $res->getBody()->getContents();
				$data = json_decode($data, true);
			}
		}
	} catch (GuzzleHttp\Exception\ServerException $e) {
		$success = false;
		$ExceptionBody = $e->getResponse()->getBody()->getContents();
		$this->get('Monolog\Logger')->error("SIMON '/backend/system/servers/{providerID:.*}/servers' ClientException " . $ExceptionBody);
	}

	return $response->withJson(["success" => $success, "message" => $data]);
});

/** Get all Images
 * Returns all image objects. You can select specific image types only and sort the results by using URI parameters.
 * http://127.0.0.1:8186/backend/system/servers/1/servers/images
 */
$app->get('/backend/system/servers/{providerID:.*}/images', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("SIMON '/system/status/{secret:.*}' route");
	$success = false;

	$system = $this->get('SIMON\System\System');
	$config = $this->get('Noodlehaus\Config');

	$providerID = $args['providerID'];

	$access_token = $config->get('default.cloud_providers.hetzner.analysis');

	$HTTPClient = $this->get('GuzzleHttp\Client');
	$endpiont = "https://api.hetzner.cloud/v1/images?type=snapshot";

	try {
		$res = $HTTPClient->request('GET', $endpiont,
			['verify' => false,
				'allow_redirects' => true,
				'connect_timeout' => 1200,
				'timeout' => 1200,
				'debug' => false,
				'headers' =>
				[
					'Authorization' => "Bearer " . $access_token,
				],
			]);
		if ($res->getStatusCode() !== 200) {
			$success = false;
		} else {
			if ($res->getBody()) {
				$success = true;
				$data = $res->getBody()->getContents();
				$data = json_decode($data, true);
			}
		}
	} catch (GuzzleHttp\Exception\ServerException $e) {
		$success = false;
		$ExceptionBody = $e->getResponse()->getBody()->getContents();
		$this->get('Monolog\Logger')->error("SIMON '/backend/system/servers/{providerID:.*}/servers' ClientException " . $ExceptionBody);
	}

	return $response->withJson(["success" => $success, "message" => $data]);
});
/** Get all SSH keys
 * Returns all SSH key objects.
 * http://127.0.0.1:8186/backend/system/servers/1/servers/images
 */
$app->get('/backend/system/servers/{providerID:.*}/ssh_keys', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("SIMON '/system/status/{secret:.*}' route");
	$success = false;

	$system = $this->get('SIMON\System\System');
	$config = $this->get('Noodlehaus\Config');

	$providerID = $args['providerID'];

	$access_token = $config->get('default.cloud_providers.hetzner.analysis');

	$HTTPClient = $this->get('GuzzleHttp\Client');
	$endpiont = "https://api.hetzner.cloud/v1/ssh_keys";

	try {
		$res = $HTTPClient->request('GET', $endpiont,
			['verify' => false,
				'allow_redirects' => true,
				'connect_timeout' => 1200,
				'timeout' => 1200,
				'debug' => false,
				'headers' =>
				[
					'Authorization' => "Bearer " . $access_token,
				],
			]);
		if ($res->getStatusCode() !== 200) {
			$success = false;
		} else {
			if ($res->getBody()) {
				$success = true;
				$data = $res->getBody()->getContents();
				$data = json_decode($data, true);
			}
		}
	} catch (GuzzleHttp\Exception\ServerException $e) {
		$success = false;
		$ExceptionBody = $e->getResponse()->getBody()->getContents();
		$this->get('Monolog\Logger')->error("SIMON '/backend/system/servers/{providerID:.*}/servers' ClientException " . $ExceptionBody);
	}

	return $response->withJson(["success" => $success, "message" => $data]);
});
/** Get Metrics for a Server
 * Get Metrics for specified server.
 * You must specify the type of metric to get: cpu, disk or network.
 * You can also specify more than one type by comma separation, e.g. cpu,disk.
 * 127.0.0.1:8186/backend/system/servers/1/servers/metrics/799185
 */
$app->get('/backend/system/servers/{providerID:.*}/servers/metrics/{serverID:.*}', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("SIMON '/system/status/{secret:.*}' route");
	$success = false;
	$data = "";
	$limits = Array();

	$system = $this->get('SIMON\System\System');
	$config = $this->get('Noodlehaus\Config');

	$providerID = $args['providerID'];
	$serverID = intval($args['serverID']);

	$access_token = $config->get('default.cloud_providers.hetzner.analysis');

	$HTTPClient = $this->get('GuzzleHttp\Client');

	// http://php.net/manual/en/function.strtotime.php
	$time_start = new DateTime("-1 hour");
	$time_end = new DateTime();

	$endpiont = "https://api.hetzner.cloud/v1/servers/" . $serverID . "/metrics?type=cpu&start=" . $time_start->format('Y-m-d\TH:i:s\Z') . "&end=" . $time_end->format('Y-m-d\TH:i:s\Z');

	try {
		$res = $HTTPClient->request('GET', $endpiont,
			['verify' => false,
				'allow_redirects' => true,
				'connect_timeout' => 1200,
				'timeout' => 1200,
				'debug' => false,
				'headers' =>
				[
					'Authorization' => "Bearer " . $access_token,
				],
			]);

		$limits = array(
			'RateLimit-Limit' => $res->getHeader('RateLimit-Limit')[0],
			'RateLimit-Remaining' => $res->getHeader('RateLimit-Remaining')[0],
			'RateLimit-Reset' => $res->getHeader('RateLimit-Reset')[0],
		);

		if ($res->getStatusCode() !== 200) {
			$success = false;
		} else {
			if ($res->getBody()) {
				$success = true;
				$data = $res->getBody()->getContents();
				$data = json_decode($data, true);
			}
		}
	} catch (GuzzleHttp\Exception\ClientException $e) {
		$success = false;
		$data = json_decode($e->getResponse()->getBody()->getContents(), true);
	}

	return $response->withJson(["success" => $success, "message" => $data, "limits" => $limits]);
});

$app->get('/backend/system/servers/{providerID:.*}/servers/create', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("SIMON '/system/status/{secret:.*}' route");
	$success = false;
	$data = "";
	$limits = Array();

	$system = $this->get('SIMON\System\System');
	$config = $this->get('Noodlehaus\Config');

	$providerID = $args['providerID'];

	return $response->withJson(["success" => $success, "message" => $data, "limits" => $limits]);
});

/**
 */
$app->get('/backend/system/cron', function (Request $request, Response $response, array $args) {
	$this->get('Monolog\Logger')->info("SIMON '/system/cron' route");
	$success = false;
	$message = array();

	$Servers = $this->get('SIMON\Servers\Servers');
	$Logger = $this->get('Monolog\Logger');
	// 1. Get list of Queue Tasks thats needs to be processed
	$DatasetQueue = $this->get('SIMON\Dataset\DatasetQueue');

	$queueEntries = $DatasetQueue->getProcessingEntries();

	if (count($queueEntries) > 0) {
		foreach ($queueEntries as $queue) {
			// 2. For-each task create server and put info about models thats need to be processed on that server
			$packages = $queue["packages"];
			if (count($packages) > 0) {
				$packageGroups = array();
				foreach ($packages as $package) {
					if (!isset($packageGroups[$package["serverGroup"]])) {
						$packageGroups[$package["serverGroup"]] = [];
					}
					$packageGroups[$package["serverGroup"]][] = $package["packageID"];
				}

				// Create as much servers as much we have many groups
				// But tell 1st created server to partition data and calculate proportions
				$i = 0;
				foreach ($packageGroups as $packageGroupID => $packageGroupValues) {
					$packages = $packageGroupValues;
					$success = $Servers->createQueueServer($queue["uid"] . "-group-" . $packageGroupID, "cx21", "nbg1", $queue["id"], $packages, $i);

					if ($success === true) {
						$update = $DatasetQueue->setProcessingStatus($queue["id"], 3);
						$Logger->info("SIMON '/backend/system/cron' VM Created Queue: " . $queue["id"] . " Group: " . $packageGroupID . " Update: " . $update);
					} else {
						$Logger->error("SIMON '/backend/system/cron' VM creation FAILED Queue: " . $queue["id"] . " Group: " . $packageGroupID);
					}
					$i++;
				}
			}
		}
	} else {
		array_push($message, "Cannot find any queue entries to process");

	}

	return $response->withJson(["success" => $success, "message" => $message]);
});
