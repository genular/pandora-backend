<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-11 15:12:24
 */
namespace SIMON\System;
use Noodlehaus\Config as Config;

// PSR 7 standard.
use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;

class ResumableUpload {
	protected $database;
	protected $logger;
	protected $Config;
	protected $Helpers;

	protected $errors = [];
	protected $temp_upload_dir = "/tmp/uploads";

	public function __construct(
		Medoo $database,
		Logger $logger,
		Config $Config,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Config = $Config;
		$this->Helpers = $Helpers;

		$this->temp_upload_dir = $this->Config->get('default.backend.data_path') . "/tmp/uploads";

		$this->logger->addInfo("==> INFO: SIMON\System\ResumableUpload constructed: " . $this->temp_upload_dir);

		if (!file_exists($this->temp_upload_dir)) {
			mkdir($this->temp_upload_dir, 0777, true);
		}
	}
	/**
	 * Moves the uploaded file to the upload directory and assigns it a unique name
	 * to avoid overwriting an existing uploaded file.
	 * @param file $uploaded file uploaded file to move
	 */
	function moveUploadedFile($tmp_file_path, $filename) {
		$filename = $this->Helpers->sanitizeFileName($filename); # remove problematic symbols

		$info = pathinfo($filename);
		$extension = isset($info['extension']) ? '.' . strtolower($info['extension']) : '';
		$filename = $info['filename'];

		$saveName = $this->getNextAvailableFilename($this->temp_upload_dir, $filename, $extension);
		$savePath = $this->temp_upload_dir . "/" . $saveName . $extension;

		if (move_uploaded_file($tmp_file_path, $savePath)) {
			return $savePath;
		} else {
			return false;
		}
	}

	/**
	 * [resumableUpload description]
	 * @param  [string] $tmp_file_path [description]
	 * @param  [string] $filename      [description]
	 * @param  [array] $post          [description]
	 * @return [array]                [description]
	 */
	public function resumableUpload($tmp_file_path, $filename, $post) {
		$successes = array();
		$warnings = array();

		$identifier = (isset($post['dzuuid'])) ? trim($post['dzuuid']) : '';
		$file_chunks_folder = $this->temp_upload_dir . "/" . $identifier;
		if (!is_dir($file_chunks_folder)) {
			mkdir($file_chunks_folder, 0777, true);
		}

		$filename = $this->Helpers->sanitizeFileName($filename); # remove problematic symbols

		$info = pathinfo($filename);
		$extension = isset($info['extension']) ? '.' . strtolower($info['extension']) : '';
		$filename = $info['filename'];
		$totalSize = (isset($post['dztotalfilesize'])) ? (int) $post['dztotalfilesize'] : 0;
		$totalChunks = (isset($post['dztotalchunkcount'])) ? (int) $post['dztotalchunkcount'] : 0;
		$chunkInd = (isset($post['dzchunkindex'])) ? (int) $post['dzchunkindex'] : 0;
		$chunkSize = (isset($post['dzchunksize'])) ? (int) $post['dzchunksize'] : 0;
		$startByte = (isset($post['dzchunkbyteoffset'])) ? (int) $post['dzchunkbyteoffset'] : 0;
		$chunk_file = "$file_chunks_folder/{$filename}.part{$chunkInd}";

		if (!move_uploaded_file($tmp_file_path, $chunk_file)) {
			$this->errors[] = array('text' => 'Move error', 'name' => $filename, 'index' => $chunkInd);
		}

		if (count($this->errors) == 0 and $new_path = $this->checkAllParts($file_chunks_folder,
			$filename,
			$extension,
			$totalSize,
			$totalChunks,
			$successes, $warnings)) {
			return array('final' => true, 'path' => $new_path, 'successes' => $successes, 'errors' => $this->errors, 'warnings' => $warnings);
		}

		return array('final' => false, 'successes' => $successes, 'errors' => $this->errors, 'warnings' => $warnings);
	}

	/**
	 * [checkAllParts description]
	 * @param  [type] $file_chunks_folder [description]
	 * @param  [type] $filename           [description]
	 * @param  [type] $extension          [description]
	 * @param  [type] $totalSize          [description]
	 * @param  [type] $totalChunks        [description]
	 * @param  [type] &$successes         [description]
	 * @param  [type] &$warnings          [description]
	 * @return [type]                     [description]
	 */
	public function checkAllParts($file_chunks_folder,
		$filename,
		$extension,
		$totalSize,
		$totalChunks,
		&$successes, &$warnings) {
		// reality: count all the parts of this file
		$parts = glob("$file_chunks_folder/*");
		$successes[] = count($parts) . " of $totalChunks parts done so far in $file_chunks_folder";

		// check if all the parts present, and create the final destination file
		if (count($parts) == $totalChunks) {
			$loaded_size = 0;

			foreach ($parts as $file) {
				$loaded_size += filesize($file);
			}

			if ($loaded_size >= $totalSize and $new_path = $this->createFileFromChunks(
				$file_chunks_folder,
				$filename,
				$extension,
				$totalSize,
				$totalChunks,
				$successes, $warnings) and count($this->errors) == 0) {
				$this->cleanUp($file_chunks_folder);

				return $new_path;
			}
		}
		return false;
	}

	/**
	 * [cleanUp description]
	 * @param  [type] $file_chunks_folder [description]
	 * @return [type]                     [description]
	 */
	public function cleanUp($file_chunks_folder) {
		// rename the temporary directory (to avoid access from other concurrent chunks uploads) and than delete it
		if (rename($file_chunks_folder, $file_chunks_folder . '_UNUSED')) {
			$this->Helpers->rrmdir($file_chunks_folder . '_UNUSED');
		} else {
			$this->Helpers->rrmdir($file_chunks_folder);
		}
	}

	/**
	 * Check if all the parts exist, and
	 * gather all the parts of the file together
	 * @param string $file_chunks_folder - the temporary directory holding all the parts of the file
	 * @param string $fileName - the original file name
	 * @param string $totalSize - original file size (in bytes)
	 */
	public function createFileFromChunks($file_chunks_folder, $fileName, $extension, $total_size, $total_chunks,
		&$successes, &$warnings) {
		$saveName = $this->getNextAvailableFilename($this->temp_upload_dir, $fileName, $extension);

		if (!$saveName) {
			return false;
		}

		$fp = fopen($this->temp_upload_dir . "/" . $saveName . $extension, 'w');
		if ($fp === false) {
			$this->errors[] = 'cannot create the destination file';
			return false;
		}

		for ($i = 0; $i < $total_chunks; $i++) {
			fwrite($fp, file_get_contents($file_chunks_folder . '/' . $fileName . '.part' . $i));
		}
		fclose($fp);

		return $this->temp_upload_dir . "/" . $saveName . $extension;
	}

	/**
	 * [getNextAvailableFilename description]
	 * @param  [type] $rel_path       [description]
	 * @param  [type] $orig_file_name [description]
	 * @param  [type] $extension      [description]
	 * @return [type]                 [description]
	 */
	public function getNextAvailableFilename($rel_path, $orig_file_name, $extension) {

		if (file_exists($rel_path . "/" . $orig_file_name . $extension)) {
			$i = 0;
			while (file_exists($rel_path . "/" . $orig_file_name . "_" . (++$i) . $extension) and $i < 10000) {}
			if ($i >= 10000) {
				$this->errors = "Can not create unique name for saving file " . $orig_file_name . $extension;
				return false;
			}
			return $orig_file_name . "_" . $i;
		}
		return $orig_file_name;
	}
}
