<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-08 16:25:29
 */
namespace SIMON\System;
use Aws\S3\S3Client as S3Client;
use League\Flysystem\Adapter\Local as Local;
use League\Flysystem\AwsS3v3\AwsS3Adapter as AwsS3Adapter;
use League\Flysystem\Filesystem as Flysystem;
use Noodlehaus\Config as Config;
use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Cache as Cache;

class FileSystem {

	protected $database;
	protected $logger;
	protected $client;
	protected $table_name = "users_files";

	protected $filesystem;

	protected $Config;
	protected $Cache;

	protected $temp_download_dir = "/tmp/downloads";
	protected $storage_type = "remote";

	public function __construct(
		Medoo $database,
		Logger $logger,

		Config $Config,
		Cache $Cache
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Config = $Config;
		$this->Cache = $Cache;
		$this->temp_download_dir = $this->Config->get('default.backend.data_path') . "/tmp";

		$this->logger->addInfo("==> INFO: SIMON\System\FileSystem constructed");

		if (!file_exists($this->Config->get('default.backend.data_path'))) {
			mkdir($this->Config->get('default.backend.data_path'));
		}

		if (!file_exists($this->temp_download_dir)) {
			mkdir($this->temp_download_dir, 0777, true);
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

			$this->logger->addInfo("==> INFO: SIMON\System\FileSystem using local storage: " . $this->Config->get('default.backend.data_path'));

			$this->storage_type = "local";
			$adapter = new Local($this->Config->get('default.backend.data_path'));

			// Otherwise use remote s3 storage
		} else if ($this->Config->get('settings')["is_connected"] === true && $s3_configured === true) {

			$this->logger->addInfo("==> INFO: SIMON\System\FileSystem using S3 remote storage: " . $this->Config->get('default.backend.data_path'));

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

		$this->filesystem = new Flysystem($adapter);

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
	public function getDownloadLink($filesystem_path) {
		$downloadLink = false;

		if ($this->storage_type === "remote") {
			return $this->getPreSignedURL($filesystem_path, $this->Config->get('default.storage.s3.bucket'), '+1 day', false);

		} else if ($this->storage_type === "local") {
			$public_directory = realpath(__DIR__ . '/../../public/downloads');
			// Clean old files
			$this->deleteOldFiles($public_directory);

			$copy_from = realpath($this->Config->get('default.backend.data_path') . "/" . $filesystem_path);
			$copy_to = $public_directory . "/" . basename($filesystem_path);

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
	 * @param string $path_initial eg /tmp/filename.txt
	 * @param string $path_renamed eg /tmp/filename
	 * @param string $upload_directory
	 */
	public function insertFileToDatabase($user_id, $details, $path_initial, $path_renamed, $path_remote, $upload_directory) {
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
			"path_initial" => $path_initial,
			"path_renamed" => $path_renamed,
			"path_remote" => $path_remote,
			"display_filename" => $details['filename'],
			"upload_directory" => $upload_directory,
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
	public function deleteFileByID($file_id, $remote_file_path) {
		$response = false;
		$data = $this->database->delete($this->table_name, [
			"id" => $file_id,
		]);
		if ($data->rowCount() > 0) {
			$response = $this->filesystem->delete($remote_file_path);
		}

		return ($response);
	}

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
				'upload_directory[~]' => $upload_directory,
			];
			$details = $this->database->select($this->table_name, $columns, $conditions);
			$this->Cache->setArray($cache_key, $details, 5000);
		}

		return ($details);
	}

	public function getFileDetails($file_id, $cache = true) {

		$cache_key = $this->table_name . "_getFileDetails_" . md5($file_id);

		$details = $this->Cache->getArray($cache_key);
		if ($cache === false || $details === false) {
			$columns = "*";
			$conditions = [
				'id' => $file_id,
			];
			$details = $this->database->get($this->table_name, $columns, $conditions);
			$this->Cache->setArray($cache_key, $details);
		}
		$details["details"] = json_decode($details["details"], true);
		return ($details);
	}

	public function readFirstLine($file_id) {

		$details = $this->getFileDetails($file_id);

		// Retrieve a read-stream
		$stream = $this->filesystem->readStream($details["path_remote"]);
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
	 * @param string $local_path eg /tmp/filename.txt
	 * @param string $upload_directory Relative directory name: eg uploads
	 */
	public function uploadFile($user_id, $local_path, $upload_directory) {

		$info = pathinfo($local_path);
		$extension = isset($info['extension']) ? '.' . strtolower($info['extension']) : '';
		$filename = $info['filename'];

		$remote_path = $user_id . "/" . $upload_directory . "/" . $filename . $extension;

		$exists = $this->filesystem->has($remote_path);
		if ($exists === true) {
			$remote_path = $user_id . "/" . $upload_directory . "/" . crc32(round(microtime(true) * 1000)) . "_" . $filename . $extension;
		}

		$stream = fopen($local_path, 'r+');
		$this->filesystem->writeStream(
			$remote_path,
			$stream
		);
		if (is_resource($stream)) {
			fclose($stream);
		}

		return $remote_path;
	}

	/**
	 * Downloads file from remote server to temporary place in our local file-system
	 * @param  [type] $input can be file_id from users_files table or full path to the requested file
	 * @return [type]          [description]
	 */
	public function downloadFile($input, $new_file_name = false) {

		$remotePath = $input;
		if (is_numeric($input)) {
			$details = $this->getFileDetails($input, false);
			if (isset($details["path_remote"])) {
				$remotePath = $details["path_remote"];
			} else {
				return false;
			}
		}
		$file = new \SplFileInfo($remotePath);
		$file_path = $this->temp_download_dir . "/" . $file->getBasename('.tar.gz');
		$file_path_gz = $file_path . ".tar.gz";

		// Skip downloading if file is already downloaded and extracted
		if (file_exists($file_path)) {
			@unlink($file_path_gz);
			return $file_path;
		}

		$ungz_cmd = "tar xf " . $file_path_gz . " -C " . $this->temp_download_dir;
		// Skip downloading if compressed file is already downloaded
		if (file_exists($file_path_gz)) {
			exec($ungz_cmd);
			return $file_path;
		}

		// Retrieve a read-stream
		$stream = $this->filesystem->readStream($remotePath);
		$contents = stream_get_contents($stream);
		if (is_resource($contents)) {
			fclose($contents);
		}

		file_put_contents($file_path_gz, $contents);
		exec($ungz_cmd);
		@unlink($file_path_gz);

		if ($new_file_name !== false) {
			$new_file_name = $this->temp_download_dir . "/" . $new_file_name;
			rename($file_path, $new_file_name);

			$file_path = $new_file_name;
		}

		return $file_path;
	}

	/**
	 * Initialize user workspace directory on file-system
	 * @param  [int] $user_id [description]
	 * @return [string]
	 */
	public function initilizeUserWorkspace($user_id) {
		$workspace_directory = $user_id;

		$sub_directories = array('tasks', 'uploads', 'public');

		// Create user workspace sub-directories
		foreach ($sub_directories as $sub_directory) {
			$path = $workspace_directory . "/" . $sub_directory;
			$exists = $this->filesystem->has($path);

			if (!$exists) {
				$response = $this->filesystem->createDir($path);
				if ($this->storage_type === "local") {
					chmod($path, 0777);
				}
			}
		}

		return $workspace_directory;
	}
}
