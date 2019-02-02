<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-02-02 11:30:02
 */
namespace SIMON\PublicDatabases;

use Aws\S3\S3Client as S3Client;
use League\Flysystem\AwsS3v3\AwsS3Adapter as AwsS3Adapter;
use League\Flysystem\Filesystem as Flysystem;
use Noodlehaus\Config as Config;
use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Cache as Cache;
use \SIMON\Helpers\Helpers as Helpers;

class PublicDatabases {
	protected $table_name = "public_databases";
	protected $database;
	protected $logger;
	protected $Helpers;

	protected $filesystem;

	protected $Config;
	protected $Cache;
	protected $temp_download_dir = "/tmp/downloads";

	public function __construct(
		Medoo $database,
		Logger $logger,

		Config $Config,
		Cache $Cache,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Config = $Config;
		$this->Cache = $Cache;

		$this->Helpers = $Helpers;

		$configuration = [
			'credentials' => [
				'key' => $this->Config->get('default.storage.s3.key'),
				'secret' => $this->Config->get('default.storage.s3.secret'),
			],
			'region' => $this->Config->get('default.storage.s3.region'),
			'version' => 'latest',
			'endpoint' => "https://" . $this->Config->get('default.storage.s3.region') . "." . $this->Config->get('default.storage.s3.endpoint'),
		];

		$this->client = new S3Client($configuration);
		$adapter = new AwsS3Adapter($this->client, $this->Config->get('default.storage.s3.bucket'));

		$this->filesystem = new Flysystem($adapter);

		if (!file_exists($this->temp_download_dir)) {
			mkdir($this->temp_download_dir, 0777, true);
		}

		$this->logger->addInfo("==> INFO: SIMON\PublicDatabases\PublicDatabases constructed");
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
		$count = $this->database->count($this->table_name, $columns, $conditions);

		return ($count);
	}

	/**
	 * [getDatasetByID description]
	 * @param  [type]  $datasetID [description]
	 * @param  boolean $cache   [description]
	 * @return [type]           [description]
	 */
	public function getDatasetByID($datasetID, $cache = true) {

		$cache_key = $this->table_name . "_getFileByID_" . md5($datasetID);
		$details = $this->Cache->getArray($cache_key);

		if ($cache === false || $details === false) {
			$columns = "*";
			$conditions = [
				'id' => $datasetID,
			];
			$details = $this->database->get($this->table_name, $columns, $conditions);
			$this->Cache->setArray($cache_key, $details);
		}

		return ($details);
	}
	/**
	 * Downloads file from remote server to temporary place in our local file-system
	 * @param  [type] $datasetID [description]
	 * @return [type]          [description]
	 */
	public function downloadInternalDataset($datasetID) {

		$details = $this->getDatasetByID($datasetID, false);

		$hashName = $details["hash"];
		$fileName = $this->Helpers->sanitizeFileName($details["title"]);

		$local_path_original = $this->temp_download_dir . "/" . $hashName . ".csv";
		$local_path_rename = $this->temp_download_dir . "/" . $fileName . ".csv";

		$local_gzipped_path = $this->temp_download_dir . "/" . $hashName . ".csv.tar.gz";
		$remote_gzipped_path = "/datasets/" . $hashName . ".csv.tar.gz";

		// Skip downloading if file is already downloaded
		if (file_exists($local_path_rename)) {
			@unlink($local_gzipped_path);
			return $local_path_rename;
		}
		$ungz_cmd = "tar xf "
		. escapeshellarg($local_gzipped_path) . " -C "
		. escapeshellarg($this->temp_download_dir) . " && mv "
		. escapeshellarg($local_path_original) . " " . escapeshellarg($local_path_rename);

		// Skip downloading if compressed file is already downloaded
		if (file_exists($local_gzipped_path)) {
			exec($ungz_cmd);
			return $local_path_rename;
		}
		$exists = $this->filesystem->has($remote_gzipped_path);
		if ($exists === true) {
			// Retrieve a read-stream
			$stream = $this->filesystem->readStream($remote_gzipped_path);
			$contents = stream_get_contents($stream);
			if (is_resource($contents)) {
				fclose($contents);
			}
			file_put_contents($local_gzipped_path, $contents);
			exec($ungz_cmd);
			@unlink($local_gzipped_path);
		} else {
			$local_path_rename = false;
		}

		return $local_path_rename;
	}

	/**
	 * Retrive all datasets for specific criteria
	 * @param  [type] $user_id [description]
	 * @param  [type] $page    [description]
	 * @param  [type] $limit   [description]
	 * @param  [type] $sort    [description]
	 * @param  array  $custom [description]
	 * @return [type]          [description]
	 */
	public function getList($user_id, $page, $limit, $sort, $custom, $sql_calc_found_rows = false) {

		$start_limit = (($page - 1) * $limit);
		$end_limit = $limit;

		if ($sort === "+") {
			$sort = "ASC";
		} else {
			$sort = "DESC";
		}

		$filters = [
			":user_id" => $user_id,
		];

		$sql = "SELECT ";
		if ($sql_calc_found_rows === false) {
			$sql = $sql . $this->table_name . ".id    AS datasetID,
				    " . $this->table_name . ".title,
				    " . $this->table_name . ".description,
				    " . $this->table_name . ".format,
				    " . $this->table_name . ".source,
				    " . $this->table_name . ".references,
				    " . $this->table_name . ".example,
				    " . $this->table_name . ".rows,
				    " . $this->table_name . ".columns,
				    " . $this->table_name . ".hash,
				    CONCAT('https://ams3.digitaloceanspaces.com/genular/datasets/', " . $this->table_name . ".hash, '.csv.tar.gz') AS downloadLink,
				    " . $this->table_name . ".sparsity,
				    " . $this->table_name . ".updated";
		} else {
			$sql = $sql . "COUNT(id) AS total";
		}

		$sql = $sql . " FROM " . $this->table_name . "

	            WHERE " . $this->table_name . ".uid = :user_id
	            OR " . $this->table_name . ".uid IS NULL";

		if (trim($custom) !== "") {
			$sql = $sql . " AND MATCH(public_databases.title, public_databases.description, public_databases.format, public_databases.source, public_databases.references) AGAINST('" . $custom . "' IN BOOLEAN MODE)";

		}

		if ($sql_calc_found_rows === false) {
			$filters[":start_limit"] = $start_limit;
			$filters[":end_limit"] = $end_limit;
			$sql = $sql . " ORDER BY " . $this->table_name . ".id " . $sort . " LIMIT :start_limit, :end_limit;";
		} else {
			$sql = $sql . " ORDER BY " . $this->table_name . ".id " . $sort . ";";
		}

		if ($sql_calc_found_rows === false) {
			$details = $this->database->query($sql, $filters)->fetchAll(\PDO::FETCH_ASSOC);
			$totalResults = $this->getList($user_id, $page, $limit, $sort, $custom, true);
			return array($details, $totalResults);
		} else {
			$details = $this->database->query($sql, $filters)->fetch();
			return (int) $details["total"];
		}
	}
}
