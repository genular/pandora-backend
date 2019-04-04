<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-04-04 09:53:18
 */
namespace SIMON\System;
use Aws\S3\S3Client as S3Client;
use League\Flysystem\Adapter\Local as Local;
use League\Flysystem\AwsS3v3\AwsS3Adapter as AwsS3Adapter;
use League\Flysystem\Config as FConfig;
use League\Flysystem\Filesystem as Flysystem;
use Noodlehaus\Config as Config;
use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Cache as Cache;
use \SIMON\Helpers\Helpers as Helpers;

class FileSystem {

	protected $database;
	protected $logger;
	protected $client;
	protected $table_name = "users_files";

	protected $filesystem;

	protected $Config;
	protected $Cache;
	protected $Helpers;
	// Used for saving temporary files
	private $temp_dir = "/tmp";
	private $storage_type = "remote";

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

		$this->temp_dir = sys_get_temp_dir() . "/" . $this->Config->get('default.salt') . "/downloads";
		$this->logger->addInfo("==> INFO: SIMON\System\FileSystem constructed: " . $this->temp_dir);
		// Create temporary directory if it doesn't exists
		if (!file_exists($this->temp_dir)) {
			$this->Helpers->createDirectory($this->temp_dir);
		}

		// Check if S3 storage is configured!
		$s3_configured = true;
		if ($this->Config->get('default.storage.s3.secret') === null ||
			$this->Config->get('default.storage.s3.secret') === "PLACEHOLDER") {
			$s3_configured = false;
		}

		// If we are inside a DOCKER or there is no Internet available or remote storage is not configured use Local storage
		if ($this->Config->get('settings')["is_docker"] === true ||
			$this->Config->get('settings')["is_connected"] === false ||
			$s3_configured === false) {

			$this->logger->addInfo("==> INFO: SIMON\System\FileSystem using local storage: " . $this->Config->get('default.storage.local.data_path'));

			$this->storage_type = "local";
			$adapter = new Local(
				$this->Config->get('default.storage.local.data_path'),
				0,
				Local::DISALLOW_LINKS,
				[
					'file' => [
						'public' => 0777,
						'private' => 0777,
					],
					'dir' => [
						'public' => 0777,
						'private' => 0777,
					],
				]);

			// Otherwise use remote s3 storage
		} else if ($this->Config->get('settings')["is_connected"] === true && $s3_configured === true) {

			$this->logger->addInfo("==> INFO: SIMON\System\FileSystem using S3 remote storage");

			$this->client = new S3Client([
				'credentials' => [
					'key' => $this->Config->get('default.storage.s3.key'),
					'secret' => $this->Config->get('default.storage.s3.secret'),
				],
				'region' => $this->Config->get('default.storage.s3.region'),
				'version' => 'latest',
				'endpoint' => "https://" . $this->Config->get('default.storage.s3.region') . "." . $this->Config->get('default.storage.s3.endpoint'),
			]);
			$adapter = new AwsS3Adapter($this->client, $this->Config->get('default.storage.s3.bucket'));

		} else {
			throw new Exception("Error: SIMON\System\FileSystem Cannot configure file-system", 1);
		}

		$this->filesystem = new Flysystem($adapter, new FConfig([
			'disable_asserts' => true,
		]));
	}
	/**
	 * Create a link to a S3 object from a bucket. If expiration is not empty, then it is used to create
	 * a signed URL
	 *
	 * @param  string     $pathRemote The object name (full path)
	 * @param  string     $bucket The bucket name
	 * @param  string|int $expiration The Unix timestamp to expire at or a string that can be evaluated by strtotime
	 * @param  string     $customFilename Custom filename of the file
	 * @return string
	 */
	private function getPreSignedURL($pathRemote, $bucket = 'genular', $expiration = '+1 day', $customFilename = false) {

		$bucket = $bucket . '/' . dirname($pathRemote);
		$object = basename($pathRemote);

		if ($expiration) {
			$commandArgs = ['Bucket' => $bucket, 'Key' => $object];
			if ($customFilename) {
				$commandArgs['ResponseContentDisposition'] = 'attachment; filename=' . $customFilename;
			}
			$command = $this->client->getCommand('GetObject', $commandArgs);
			return $this->client->createPresignedRequest($command, $expiration)->getUri()->__toString();
		} else {
			return $this->client->getObjectUrl($bucket, $object);
		}
	}
	/**
	 * [getDownloadLink description]
	 * @param  [type] $filesystem_path [description]
	 * @return [type]                  [description]
	 */
	public function getDownloadLink($filesystem_path, $customFilename = false) {
		$downloadLink = false;

		if ($this->storage_type === "remote") {
			return $this->getPreSignedURL($filesystem_path, $this->Config->get('default.storage.s3.bucket'), '+1 day', $customFilename);

		} else if ($this->storage_type === "local") {
			$public_directory = realpath(__DIR__ . '/../../public/downloads');
			// Clean old files
			$this->deleteOldFiles($public_directory);

			$copy_from = $this->Config->get('default.storage.local.data_path') . "/" . $filesystem_path;

			if ($customFilename !== false) {
				$copy_to_filename = $customFilename;
			} else {
				$copy_to_filename = basename($filesystem_path);
			}
			$copy_to = $public_directory . "/" . $copy_to_filename;
			$downloadLink = $this->Config->get('default.backend.server.url') . "/downloads/" . basename($filesystem_path);

			if (!file_exists($copy_to)) {
				if (file_exists($copy_from)) {
					if (!copy($copy_from, $copy_to)) {
						$downloadLink = false;
					}
				} else {
					$downloadLink = false;
				}
			}
		}
		return $downloadLink;
	}
	/**
	 * Delete files older than 2 days
	 * @param  [type] $directory [description]
	 * @return [type]            [description]
	 */
	public function deleteOldFiles($directory) {
		if (file_exists($directory)) {
			foreach (new \DirectoryIterator($directory) as $fileInfo) {
				if ($fileInfo->isDot()) {
					continue;
				}
				if ($fileInfo->isFile() && time() - $fileInfo->getCTime() >= 2 * 24 * 60 * 60) {
					unlink($fileInfo->getRealPath());
				}
			}
		}
	}
	/**
	 * Insert remote file reference into local database
	 *
	 * @param string $user_id Database ID of the current user
	 * @param array $details file-info array
	 * @param string $remote_path
	 */
	public function insertFileToDatabase($user_id, $details, $remote_path) {
		// Display user friendly name for system files
		if ($details['item_type'] === 2) {
			if (substr($details['filename'], 0, 17) !== "genSysFile_queue_") {
				$details['filename'] = str_replace("genSysFile_queue_", "", $details['filename']);
			}
		}

		$this->database->insert($this->table_name, [
			"uid" => $user_id,
			"ufsid" => 1,
			"item_type" => $details['item_type'],
			"file_path" => $remote_path,
			"filename" => md5($details['basename']),
			"display_filename" => $details['filename'],
			"size" => $details['filesize'],
			"extension" => $details['extension'],
			"mime_type" => $details['mime_type'],
			"details" => json_encode($details['details']),
			"file_hash" => $details['file_hash'],
			"created" => Medoo::raw("NOW()"),
			"updated" => Medoo::raw("NOW()"),
		]);

		return $this->database->id();
	}
	/**
	 * [deleteFilesByIDs description]
	 * @param  [type] $ids [description]
	 * @return [type]      [description]
	 */
	public function deleteFilesByIDs($ids) {
		foreach ($ids as $id) {
			if (!is_numeric($id)) {
				continue;
			}
			$this->logger->addInfo("==> INFO: SIMON\System\FileSystem deleteFilesByIDs: " . $id);
			$details = $this->getFileDetails($id, ["file_path"], true);
			$this->deleteFileByID($id, $details['file_path']);
		}
	}
	/**
	 * [deleteFileByID description]
	 * @param  [type] $file_id          [description]
	 * @param  [type] $remote_file_path [description]
	 * @return [type]                   [description]
	 */
	public function deleteFileByID($file_id, $remote_file_path) {
		$response = false;
		$data = $this->database->delete($this->table_name, [
			"id" => $file_id,
		]);
		if ($data->rowCount() > 0) {
			if ($this->filesystem->has($remote_file_path)) {
				$response = $this->filesystem->delete($remote_file_path);
			}
		}

		return ($response);
	}

	/**
	 * [getAllFilesByUserID description]
	 * @param  [type]  $user_id          [description]
	 * @param  [type]  $upload_directory [description]
	 * @param  boolean $cache            [description]
	 * @return [type]                    [description]
	 */
	public function getAllFilesByUserID($user_id, $upload_directory, $cache = true) {
		$cache_key = $this->table_name . "_getAllFilesByUserID_" . md5($user_id . $upload_directory);
		$details = $this->Cache->getArray($cache_key);

		if ($cache === false || $details === false) {
			$columns = [
				"id",
				"item_type",
				"size",
				"display_filename",
				"extension",
				"mime_type",
			];
			$conditions = [
				'uid' => $user_id,
				'item_type' => 1,
				'file_path[~]' => $upload_directory,
			];
			$details = $this->database->select($this->table_name, $columns, $conditions);
			$this->Cache->setArray($cache_key, $details, 5000);
		}

		return ($details);
	}

	public function getFileDetails($file_id, $columns = ["*"], $cache = true) {
		// Make unique cache key for query
		$cache_key = $this->table_name . "_getFileDetails_" . md5($file_id) . "_" . md5(json_encode($columns));

		$details = $this->Cache->getArray($cache_key);
		if ($cache === false || $details === false) {
			$conditions = [
				'id' => $file_id,
			];
			$details = $this->database->get($this->table_name, $columns, $conditions);
			$this->Cache->setArray($cache_key, $details);
		}
		if (isset($details["details"])) {
			$details["details"] = json_decode($details["details"], true);
		}

		return ($details);
	}

	public function readFirstLine($file_id) {

		$details = $this->getFileDetails($file_id, ["file_path"], true);

		// Retrieve a read-stream
		$stream = $this->filesystem->readStream($details["file_path"]);
		$contents = stream_get_contents($stream, 1000000);
		if (is_resource($contents)) {
			fclose($contents);
		}

		$contents = strtok($contents, "\n");

		return $contents;
	}

	/**
	 * Upload file on remote filesystem
	 * @param string $user_id Database ID of the current user
	 * @param string $file_from eg /tmp/filename.txt
	 * @param string $upload_directory Relative directory name: eg uploads
	 */
	public function uploadFile($user_id, $file_from, $upload_directory) {
		$file_basename = basename($file_from);

		$file_to = "users/" . $user_id . "/" . $upload_directory . "/" . $file_basename;

		$exists = $this->filesystem->has($file_to);
		if ($exists === true) {
			$file_to = "users/" . $user_id . "/" . $upload_directory . "/" . crc32(round(microtime(true) * 1000)) . "_" . $file_basename;
		}

		$stream = fopen($file_from, 'r+');
		$this->filesystem->writeStream(
			$file_to,
			$stream
		);

		if (is_resource($stream)) {
			fclose($stream);
		}

		return $file_to;
	}

	/**
	 * Downloads file from remote server to temporary place in our local file-system
	 * @param  [type] $input can be file_id from users_files table or full path to the requested file
	 * @return [type]          [description]
	 */
	public function downloadFile($input, $new_file_name = false) {
		$this->logger->addInfo("==> INFO: SIMON\System\FileSystem downloadFile: " . $input);

		$remotePath = $input;
		if (is_numeric($input)) {
			$details = $this->getFileDetails($input, ["file_path"], false);
			if (isset($details["file_path"])) {
				$remotePath = $details["file_path"];
			} else {
				return false;
			}
		}
		$file = new \SplFileInfo($remotePath);
		$file_path = $this->temp_dir . "/" . $file->getBasename('.tar.gz');
		$file_path_gz = $file_path . ".tar.gz";

		$this->logger->addInfo("==> INFO: SIMON\System\FileSystem downloadFile local file-path: " . $file_path);
		// Skip downloading if file is already downloaded and extracted
		if (file_exists($file_path)) {
			@unlink($file_path_gz);
			return $file_path;
		}

		$ungz_cmd = "/usr/bin/tar xf " . $file_path_gz . " -C " . $this->temp_dir . " --verbose";
		// Skip downloading if compressed file is already downloaded
		if (file_exists($file_path_gz)) {
			$extracted_file = trim(shell_exec($ungz_cmd));
			if ($file->getBasename('.tar.gz') !== $extracted_file) {
				$file_path = str_replace($file->getBasename('.tar.gz'), $extracted_file, $file_path);
			}
			return $file_path;
		}

		$this->logger->addInfo("==> INFO: SIMON\System\FileSystem downloadFile remote file-path: " . $file_path);

		// Retrieve a read-stream
		$stream = $this->filesystem->readStream($remotePath);
		$contents = stream_get_contents($stream);
		if (is_resource($contents)) {
			fclose($contents);
		}
		file_put_contents($file_path_gz, $contents);

		$extracted_file = trim(shell_exec($ungz_cmd));
		if ($file->getBasename('.tar.gz') !== $extracted_file) {
			$file_path = str_replace($file->getBasename('.tar.gz'), $extracted_file, $file_path);
		}

		if ($new_file_name !== false) {
			$new_file_name = $this->temp_dir . "/" . $new_file_name;
			rename($file_path, $new_file_name);

			$file_path = $new_file_name;

		}
		@unlink($file_path_gz);

		return $file_path;
	}
	/**
	 * [getDisplayFilename description]
	 * @param  [type] $filename [description]
	 * @return [type]           [description]
	 */
	public function getDisplayFilename($filename, $extension) {

		$display_filename = "";

		if ($this->Helpers->startsWith($filename, 'genSysFile_queue')) {
			$display_filename = "resample_data";
		} else if ($this->Helpers->endsWith($filename, 'training_partition')) {
			$display_filename = "training_partition";
		} else if ($this->Helpers->endsWith($filename, 'testing_partition')) {
			$display_filename = "testing_partition";
		} else if ($this->Helpers->startsWith($filename, 'modelID')) {
			// TODO: This is temporary
			if ($extension == ".csv") {
				$extension = ".RData";
			}
			$display_filename = str_replace("modelID", "model", $filename);
		} else {
			$display_filename = $filename;
		}
		if ($extension) {
			$display_filename = $display_filename . $extension;
		}
		return ($display_filename . ".tar.gz");
	}
}
