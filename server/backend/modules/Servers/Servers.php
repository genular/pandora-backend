<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-10-16 13:54:57
 */
namespace SIMON\Servers;

// PSR 7 standard.
use DateTime;
use GuzzleHttp\Client as HTTPClient;
use GuzzleHttp\Exception\ClientException;
use GuzzleHttp\RequestOptions;
use Noodlehaus\Config as Config;
use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;

class Servers {
	protected $endpiont = "https://api.hetzner.cloud/v1/servers";

	protected $database;
	protected $logger;

	protected $Config;
	protected $HTTPClient;
	protected $Helpers;

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
		$this->logger->addInfo("==> INFO: SIMON\Servers constructed");
	}
	/** Create a Server
	 * Creates a new server. Returns preliminary information
	 * about the server as well as an action that covers progress of creation.
	 */
	public function createQueueServer($name, $type = "cx21", $location = "nbg1", $queueID = 0, $packages = [], $internalServerID) {
		$responseData = "";
		$success = true;

		$access_token = $this->Config->get('default.cloud_providers.hetzner.analysis');

		// http://php.net/manual/en/function.strtotime.php
		$time_start = new DateTime("-1 hour");

		$remoteData = [
			"queueID" => $queueID,
			// IN R check if serverID is 0 - Than make training and testing sets, create new users_files entries and upload them to Spaces
			"internalServerID" => $internalServerID,
			"packages" => $packages,
			"initialization_time" => $time_start->format('Y-m-d\TH:i:s\Z'),
		];
		$remoteData = base64_encode(json_encode($remoteData));
		// http://cloudinit.readthedocs.io/en/latest/topics/examples.html#call-a-url-when-finished
		$cloudConfig = <<<EOF
#cloud-config
# vim: syntax=yaml
write_files:
-   content: |
        $remoteData
    path: /tmp/SIMON_DATA
    permissions: '0777'
EOF;

		var_dump($remoteData);
		exit;

		$postData = Array(
			"name" => "analysis-" . $name,
			"server_type" => $type,
			"start_after_create" => true,
			"image" => 338417,
			"ssh_keys" => [85898],
			"location" => $location,
			"user_data" => $cloudConfig,
		);

		try {
			$res = $this->HTTPClient->request('POST', $this->endpiont,
				['verify' => false,
					'allow_redirects' => true,
					'connect_timeout' => 1200,
					'timeout' => 1200,
					'debug' => false,
					'headers' =>
					[
						'Content-type' => 'application/json',
						'Authorization' => "Bearer " . $access_token,
					],
					RequestOptions::JSON => $postData,
				]);

			$limits = array(
				'RateLimit-Limit' => $res->getHeader('RateLimit-Limit')[0],
				'RateLimit-Remaining' => $res->getHeader('RateLimit-Remaining')[0],
				'RateLimit-Reset' => $res->getHeader('RateLimit-Reset')[0],
			);

			if ($res->getStatusCode() !== 201) {
				$success = false;
			} else {
				if ($res->getBody()) {
					$success = true;
					$data = $res->getBody()->getContents();
					$data = json_decode($data, true);
				}
			}
		} catch (ClientException $e) {
			$success = false;
			$data = json_decode($e->getResponse()->getBody()->getContents(), true);
		}

		return $success;
	}
}
