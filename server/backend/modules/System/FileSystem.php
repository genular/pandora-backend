<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2021-02-04 16:11:22
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
use \SIMON\Helpers\Helpers as Helpers;
use \SIMON\Users\UsersFiles as UsersFiles;

class FileSystem {

	protected $database;
	protected $logger;
	protected $client;
	protected $table_name = "users_files";

	protected $filesystem;

	protected $Config;
	protected $Helpers;
	protected $UsersFiles;
	// Used for saving temporary files
	private $temp_dir = "/tmp";
	private $storage_type = "remote";
	private $targz = false;

	public function __construct(
		Medoo $database,
		Logger $logger,

		Config $Config,
		Helpers $Helpers,
		UsersFiles $UsersFiles
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Config = $Config;
		$this->Helpers = $Helpers;
		$this->UsersFiles = $UsersFiles;

		// 
		$this->temp_dir = sys_get_temp_dir() . "/" . $this->Config->get('default.salt') . "/downloads";

		$this->logger->addInfo("==> INFO: SIMON\System\FileSystem constructed: " . $this->temp_dir);
		// Create temporary directory if it doesn't exists
		if (!file_exists($this->temp_dir)) {
			$check = $this->Helpers->createDirectory($this->temp_dir);
			$this->logger->addInfo("==> INFO: SIMON\System\FileSystem directory created: " . $check);
		}

		$this->targz = $this->Helpers->which_cmd("tar");

		// Check if S3 storage is configured!
		$s3_configured = true;
		if ($this->Config->get('default.storage.s3.secret') === null ||
			$this->Config->get('default.storage.s3.secret') === "PLACEHOLDER") {
			$s3_configured = false;
		}

		// If we are inside a DOCKER or there is no Internet available or remote storage is not configured use Local storage
		if ($this->Config->get('settings')["is_docker"] === true ||
			$this->Config->get('settings')["is_connected"] === false || $s3_configured === false) {

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
				// https://github.com/aws/aws-sdk-php/issues/1915
				'retries' => 0,
				'endpoint' => "https://" . $this->Config->get('default.storage.s3.region') . "." . $this->Config->get('default.storage.s3.endpoint'),
			]);
			$adapter = new AwsS3Adapter($this->client, $this->Config->get('default.storage.s3.bucket'));

		} else {
			die("Error: SIMON\System\FileSystem Cannot configure file-system");
		}

		// Check if tar is available
		if ($this->targz === false) {
			die("error: cannot detect path to tar library: " . $this->targz);
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
			$public_directory = realpath(realpath(dirname(__DIR__)) . "/../public/downloads");
			// Clean old files
			$this->deleteOldFiles($public_directory);

			$copy_from = $this->Config->get('default.storage.local.data_path') . "/" . $filesystem_path;

			if ($customFilename !== false) {
				$copy_to_filename = $customFilename;
			} else {
				$copy_to_filename = basename($filesystem_path);
			}
			$copy_to = $public_directory . "/" . $copy_to_filename;
			$downloadLink = $this->Config->get('default.backend.server.url') . "/downloads/" . $copy_to_filename;

			$this->logger->addInfo("==> INFO: SIMON\System\FileSystem getDownloadLink: " . $copy_from . " " . $copy_to);

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
	 * @param  [string] $directory [description]
	 * @param  [array] $except [description]
	 * @return [type]            [description]
	 */
	public function deleteOldFiles($directory, $except = ["index.html"]) {
		if (file_exists($directory)) {
			foreach (new \DirectoryIterator($directory) as $fileInfo) {
				if ($fileInfo->isDot()) {
					continue;
				}
				if ($fileInfo->isFile() && time() - $fileInfo->getCTime() >= 2 * 24 * 60 * 60) {
					if (!in_array($fileInfo->getFilename(), $except)) {
						unlink($fileInfo->getRealPath());
					}
				}
			}
		}
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
			$details = $this->UsersFiles->getFileDetails($id, ["file_path"], true);
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
	 * [readFirstLine description]
	 * @param  [type] $file_id [description]
	 * @return [type]          [description]
	 */
	public function readFirstLine($file_id) {

		$details = $this->UsersFiles->getFileDetails($file_id, ["file_path"], true);

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
			$details = $this->UsersFiles->getFileDetails($input, ["file_path"], false);
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

		$ungz_cmd = $this->targz . " xf " . $file_path_gz . " -C " . $this->temp_dir . " --verbose";
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
	 * [compressFileOrDirectory description]
	 * @param  [type] $inputPath  [directory-name]
	 * @param  [type] $outputPath [archive-name.tar.gz]
	 * @return [type]             [description]
	 */

	public function compressFileOrDirectory($inputPath, $outputFileName) {
		$status = false;

		$public_directory = realpath(realpath(dirname(__DIR__)) . "/../public/downloads");

		$ouputPath = $public_directory . "/" . $outputFileName;

		if (file_exists($inputPath)) {
			$status = true;
			$gz_cmd = $this->targz . " -zcvf " . $ouputPath . " " . $inputPath;
			$command_output = trim(shell_exec($gz_cmd));
			$this->logger->addInfo("==> INFO: SIMON\System\FileSystem compressFileOrDirectory: " . $gz_cmd);
		} else {
			$this->logger->addInfo("==> INFO: SIMON\System\FileSystem compressFileOrDirectory file doesn't exsist: " . $inputPath);
		}

		if (file_exists($ouputPath) && $status === true) {
			$status = $this->Config->get('default.backend.server.url') . "/downloads/" . $outputFileName;
		}

		return ($status);
	}
}
