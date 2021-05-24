<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2021-02-03 15:27:08
 */
namespace SIMON\Helpers;
use \Monolog\Logger;

class Helpers {

	protected $logger;

	public function __construct(
		Logger $logger
	) {

		$this->logger = $logger;
		// Log anything.
		$this->logger->addInfo("==> INFO SIMON\Helpers\Helpers constructed");
	}

	/**
	 * [castArrayValues description]
	 * @param  [type] $input [description]
	 * @return [type]        [description]
	 */
	public function castArrayValues($input) {
		// Cast all numeric values to INT
		foreach ($input as $rowKey => $rowItem) {
			foreach ($rowItem as $rowItemKey => $rowItemValue) {
				if (is_numeric($rowItemValue)) {
					// Try to convert the string to a float
					$floatVal = floatval($rowItemValue);
					// If the parsing succeeded and the value is not equivalent to an int
					if ($floatVal && intval($floatVal) != $floatVal) {
						$input[$rowKey][$rowItemKey] = floatval($rowItemValue);
					} else {
						$input[$rowKey][$rowItemKey] = intval($rowItemValue);
					}
				}
			}
		}
		return $input;
	}
	/**
	 * Checks if device has Internet connection
	 * @return boolean
	 */
	public static function is_connected() {
		$connected = @fsockopen("www.google.com", 80);
		if ($connected) {
			$is_conn = true; //action when connected
			fclose($connected);
		} else {
			$is_conn = false; //action in connection failure
		}
		return $is_conn;
	}

	/**
	 * @param string $csvFile Path to the CSV file
	 * @return string Delimiter
	 */
	public function detectDelimiter($csvFile) {
		$delimiters = array(
			';' => 0,
			',' => 0,
			"\t" => 0,
			"|" => 0,
		);

		$handle = fopen($csvFile, "r");
		$firstLine = fgets($handle);
		fclose($handle);
		foreach ($delimiters as $delimiter => &$count) {
			$count = count(str_getcsv($firstLine, $delimiter));
		}

		return array_search(max($delimiters), $delimiters);
	}
	/**
	 * [which_cmd description]
	 * @param  [type] $bin_file [description]
	 * @return [type]           [description]
	 */
	public function which_cmd($bin_file) {
		$path = exec("which " . $bin_file);
		$path = trim($path);

		if ($path === "") {
			// Maybe exec function is disabled
			$additional_paths = ["/bin/", "/usr/bin/"];
			foreach ($additional_paths as $root_path) {
				$tmp_path = $root_path . $bin_file;
				if (file_exists($tmp_path) && $path === "") {
					$path = $tmp_path;
				}
			}
			if ($path === "") {
				$path = false;
			}
		}
		return ($path);
	}

	/**
	 * [renamePath]
	 * @param  [type] $file_from
	 * @param  [type] $file_to
	 * @return [type]
	 */
	public function renamePathToHash($path_parts) {
		$file_from = $path_parts['dirname'] . "/" . $path_parts['basename'];
		$file_to = $path_parts['dirname'] . "/" . md5($path_parts['basename']);

		if (!rename($file_from, $file_to)) {
			$file_to = false;
		}

		return $file_to;
	}

	/**
	 * [compressPath description]
	 * @param  [type] $file_from
	 * @return [type]
	 */
	public function compressPath($file_from) {
		// 1. Archive file
		$targz = $this->which_cmd("tar");
		// Check if tar is available
		if ($targz === false) {
			die("error: cannot detect path to tar library compressPath: " . $this->targz);
		}

		$tar_cmd = $targz . " -zcvf " . $file_from . ".tar.gz -C " . dirname($file_from) . " " . basename($file_from);
		$gzipped = exec($tar_cmd);

		return $file_from . ".tar.gz";
	}

	/**
	 * [normalizeDataNames description]
	 * @param  [type] $string [description]
	 * @return [type]         [description]
	 */
	public function normalizeDataNames($string) {
		$string = trim($string);
		$string = str_replace("+", " pos ", $string);
		$string = str_replace("-", " neg ", $string);
		$string = preg_replace('/\s+/', '_', $string);
		$string = str_replace("__", "_", $string);
		$string = str_replace("/", "_", $string);
		$string = str_replace("(", "", $string);
		$string = str_replace(")", "", $string);
		$string = str_replace(":", "", $string);
		$string = preg_replace("/[^A-Za-z0-9_]/", '', $string);
		$string = str_replace("__", "_", $string);
		$string = str_replace("__", "_", $string);

		return $string;
	}
	/**
	 * Convert a multi-dimensional, associative array to CSV data
	 * @param  array $data the array of data
	 * @return string       CSV text
	 */
	public function str_putcsv($data) {
		# Generate CSV data from array
		$fh = fopen('php://temp', 'rw'); # don't create a file, attempt
		# to use memory instead

		# write out the data
		fputcsv($fh, $data);
		rewind($fh);
		$csv = stream_get_contents($fh);
		fclose($fh);

		return $csv;
	}

	/**
	 * [validateCSVFileHeader description]
	 * @param  [type] $filePath [description]
	 * @return [type]           [description]
	 */
	public function validateCSVFileHeader($filePath) {

		$this->logger->addInfo("==> INFO: SIMON\Helpers\Helpers\validateCSVFileHeader: filePath: " . $filePath);

		$path_parts = pathinfo($filePath);

		// Check if we have BOM in the file
		$fileContent = file_get_contents($filePath);
		$bom = pack("CCC", 0xef, 0xbb, 0xbf);
		if (0 === strncmp($fileContent, $bom, 3)) {
			// BOM Detected
			$bom = pack('H*','EFBBBF');
    		$fileContent = preg_replace("/^$bom/", '', $fileContent);
			//$fileContent = mb_convert_encoding($fileContent, "UTF-8");
			file_put_contents($filePath, $fileContent);
		}

		$data = array(
			'info' => $path_parts,
			'dirname' => $path_parts['dirname'],
			'basename' => $path_parts['basename'],
			'filename' => $path_parts['filename'],
			'item_type' => (substr($path_parts['filename'], 0, 10) !== "genSysFile") ? 1 : 2,
			'extension' => isset($path_parts['extension']) ? '.' . strtolower($path_parts['extension']) : '',
			'mime_type' => mime_content_type($filePath),
			'filesize' => filesize($filePath),
			'file_hash' => hash_file('sha256', $filePath),
			'details' => array("header" => array("original" => "", "formatted" => [])),
			'message' => []
		);
		// Skip header check for system files and do it only for user files
		if (file_exists($filePath) && $data['item_type'] === 1) {
			$header = trim(fgets(fopen($filePath, 'r')));
			// Remove newline character from header
			if (substr($header, -2) === "\n") {
				$header = substr($header, 0, -2);
			}

			$data['details']["header"]["original"] = $header;
			// ($row, $delimiter, $enclosure , $escape)
			$header_items = str_getcsv($header, ",", '"', "\\");
			unset($header);
			// We need at least 3 columns one outcome + features
			if (is_array($header_items) && count($header_items) > 2) {
				$remapped = array();
				foreach ($header_items as $itemKey => $itemValue) {
					$itemValueHash = md5($itemKey . $itemValue);
					$remapped[$itemKey] = "column" . $itemKey;
					if (!isset($data['details']["header"]["formatted"][$itemValueHash])) {
						$data['details']["header"]["formatted"][$itemValueHash] = array("original" => $itemValue, "position" => $itemKey, "remapped" => $remapped[$itemKey]);
					}
				}

				$headerReplacedCSV = "\"" . implode('","', $remapped) . "\"\n";

				// read into array
				$arr = file($filePath);
				// edit first line
				$arr[0] = $headerReplacedCSV;
				// write back to file
				file_put_contents($filePath, implode($arr));

				$pandas_command = <<<EOFC
eval "$(conda shell.bash hook)"
pn_cmd=`cat <<EOF
import pandas as pd
df = pd.read_csv('{$filePath}')
print(df.nunique().to_json())
EOF`
python -c "\$pn_cmd"
EOFC;

				$pandas_output = shell_exec($pandas_command);

				$this->logger->addInfo("==> INFO: SIMON\Helpers\Helpers\validateCSVFileHeader: pandas_command: ");
				$this->logger->addInfo($pandas_command);

				// $this->logger->addInfo("==> INFO: SIMON\Helpers\Helpers\validateCSVFileHeader: pandas_output: ");
				// $this->logger->addInfo($pandas_output);

				$pandas_output = json_decode(trim($pandas_output), true);

				foreach ($data['details']["header"]["formatted"] as $itemKey => $itemValue) {
					if (is_array($pandas_output) && isset($pandas_output[$itemValue["remapped"]])) {
						$itemValue["unique_count"] = $pandas_output[$itemValue["remapped"]];
						$data['details']["header"]["formatted"][$itemKey] = $itemValue;
					} else {
						$itemValue["unique_count"] = false;
						$data['details']["header"]["formatted"][$itemKey] = $itemValue;
					}
				}

			} else {
				array_push($data['message'], "delimiters_check");
			}
		}

		return ($data);
	}

	/**
	 * Determine if the provided value contains only alpha characters with dashed and underscores.
	 * @param  [type] $input [description]
	 * @return [type]        [description]
	 */
	public function validateHeaderItem($input) {
		if (empty($input)) {
			return false;
		}
		$pattern = '/^([a-z0-9ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÒÓÔÕÖßÙÚÛÜÝàáâãäåçèéêëìíîïðòóôõöùúûüýÿ_-])+$/i';
		if (!preg_match($pattern, $input) !== false) {
			return false;
		}
		return true;
	}

	/**
	 * Decrypt data from a CryptoJS json encoding string
	 *
	 * @param mixed $passphrase
	 * @param mixed $jsonString
	 * @return mixed
	 */
	public function cryptoJsAesDecrypt($passphrase, $jsonString) {
		$jsondata = json_decode($jsonString, true);
		try {
			$salt = hex2bin($jsondata["s"]);
			$iv = hex2bin($jsondata["iv"]);
		} catch (Exception $e) {return null;}
		$ct = base64_decode($jsondata["ct"]);
		$concatedPassphrase = $passphrase . $salt;
		$md5 = array();
		$md5[0] = md5($concatedPassphrase, true);
		$result = $md5[0];
		for ($i = 1; $i < 3; $i++) {
			$md5[$i] = md5($md5[$i - 1] . $concatedPassphrase, true);
			$result .= $md5[$i];
		}
		$key = substr($result, 0, 32);
		$data = openssl_decrypt($ct, 'aes-256-cbc', $key, true, $iv);
		return json_decode($data, true);
	}

	/**
	 * Encrypt value to a cryptojs compatiable json encoding string
	 *
	 * @param mixed $passphrase
	 * @param mixed $value
	 * @return string
	 */
	public function cryptoJsAesEncrypt($passphrase, $value) {
		$salt = openssl_random_pseudo_bytes(8);
		$salted = '';
		$dx = '';
		while (strlen($salted) < 48) {
			$dx = md5($dx . $passphrase . $salt, true);
			$salted .= $dx;
		}
		$key = substr($salted, 0, 32);
		$iv = substr($salted, 32, 16);
		$encrypted_data = openssl_encrypt(json_encode($value), 'aes-256-cbc', $key, true, $iv);
		$data = array("ct" => base64_encode($encrypted_data), "iv" => bin2hex($iv), "s" => bin2hex($salt));
		return json_encode($data);
	}

	/**
	 * [crc64Table description]
	 * @return array
	 */
	private function crc64Table() {
		$crc64tab = [];

		// ECMA polynomial
		$poly64rev = (0xC96C5795 << 32) | 0xD7870F42;

		// ISO polynomial
		// $poly64rev = (0xD8 << 56);

		for ($i = 0; $i < 256; $i++) {
			for ($part = $i, $bit = 0; $bit < 8; $bit++) {
				if ($part & 1) {
					$part = (($part >> 1) & ~(0x8 << 60)) ^ $poly64rev;
				} else {
					$part = ($part >> 1) & ~(0x8 << 60);
				}
			}

			$crc64tab[$i] = $part;
		}

		return $crc64tab;
	}

	/**
	 * CRC32 string
	 * Formats:
	 *  crc64('php'); // afe4e823e7cef190
	 *  crc64('php', '0x%x'); // 0xafe4e823e7cef190
	 *  crc64('php', '0x%X'); // 0xAFE4E823E7CEF190
	 *  crc64('php', '%d'); // -5772233581471534704 signed int
	 *  crc64('php', '%u'); // 12674510492238016912 unsigned int
	 * @param  [type] $string [description]
	 * @param  string $format [description]
	 * @return mixed
	 */
	public function crc64($string, $format = '%x') {
		static $crc64tab;

		if ($crc64tab === null) {
			$crc64tab = $this->crc64Table();
		}

		$crc = 0;

		for ($i = 0; $i < strlen($string); $i++) {
			$crc = $crc64tab[($crc ^ ord($string[$i])) & 0xff] ^ (($crc >> 8) & ~(0xff << 56));
		}

		return sprintf($format, $crc);
	}

	/**
	 * [generateRandomString description]
	 * @param  integer $length [description]
	 * @return [type]          [description]
	 */
	public function generateRandomString($length = 10) {
		$characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
		$charactersLength = strlen($characters);
		$randomString = '';
		for ($i = 0; $i < $length; $i++) {
			$randomString .= $characters[rand(0, $charactersLength - 1)];
		}
		return $randomString;
	}

	/**
	 * Check if string starts with some another string
	 * @param  string $haystack
	 * @param  string $needle
	 * @return [type]           [description]
	 */
	public function startsWith($haystack, $needle) {
		$length = strlen($needle);
		return (substr($haystack, 0, $length) === $needle);
	}

	/**
	 * Check if string ends with some another string
	 * @param  string $haystack
	 * @param  string $needle
	 * @return [type]           [description]
	 */
	public function endsWith($haystack, $needle) {
		$length = strlen($needle);

		return $length === 0 ||
			(substr($haystack, -$length) === $needle);
	}
	/**
	 * The directory permissions are affected by the current umask. Set the umask for your webserver,
	 * use PHP's umask function or use the chmod function after the directory has been created.
	 * @param  [type] $path [description]
	 * @return [type]       [description]
	 */
	public function createDirectory($uri) {

		$chunks = explode('/', $uri);
		// remove first element since its empty
		array_splice($chunks, 0, 1);

		$recursive_paths = [];

		foreach ($chunks as $i => $chunk) {
			$recursive_paths[] = '/' . implode('/', array_slice($chunks, 0, $i + 1));

		}
		$recursive_paths = array_unique($recursive_paths);
		foreach ($recursive_paths as $path) {
			if (!file_exists($path) || !is_dir($path)) {
				if (!mkdir($path, 0777, true)) {
					return FALSE;
				}
				if (!chmod($path, 0777)) {
					return FALSE;
				}
			}
		}

		return true;
	}

	/**
	 * Recursively deletes directory. Remove all files, folders and their sub-folders
	 * @param  string $dir
	 * @return [type]      [description]
	 */
	public function rrmdir($dir) {
		if (is_dir($dir)) {
			$objects = scandir($dir);
			foreach ($objects as $object) {
				if ($object != "." && $object != "..") {
					if (filetype($dir . "/" . $object) == "dir") {
						$this->rrmdir($dir . "/" . $object);
					} else {
						unlink($dir . "/" . $object);
					}

				}
			}
			reset($objects);
			if (is_dir($dir)) {
				rmdir($dir);
			}
		}
	}

	/**
	 * Sanitizes a filename replacing whitespace with dashes
	 *
	 * Removes special characters that are illegal in filenames on certain
	 * operating systems and special characters requiring special escaping
	 * to manipulate at the command line. Replaces spaces and consecutive
	 * dashes with a single dash. Trim period, dash and underscore from beginning
	 * and end of filename.
	 *
	 * @since 2.1.0
	 *
	 * @param string $filename The filename to be sanitized
	 * @return string The sanitized filename
	 */
	public function sanitizeFileName($filename) {
		$special_chars = array("?", "[", "]", "/", "\\", "=", "<", ">", ":", ";", ",", "'", "\"", "&", "$", "#", "*", "(", ")", "|", "~", "`", "!", "{", "}");
		$filename = str_replace($special_chars, '', $filename);

		$filename = preg_replace('/[\s-]+/', '-', $filename);
		$filename = trim($filename, '.-_');

		return strtolower($filename);
	}
	/**
	 * Copy remote file over HTTP one small chunk at a time.
	 * https://stackoverflow.com/questions/4000483/how-download-big-file-using-php-low-memory-usage
	 *
	 * @param $infile The full URL to the remote file
	 * @param $outfile The path where to save the file
	 */
	public function copyfile_chunked($infile, $outfile) {
		$chunksize = 10 * (1024 * 1024); // 10 Megs
		/**
		 * parse_url breaks a part a URL into it's parts, i.e. host, path,
		 * query string, etc.
		 */
		$parts = parse_url($infile);
		$i_handle = fsockopen($parts['host'], 80, $errstr, $errcode, 5);
		$o_handle = fopen($outfile, 'wb');

		if ($i_handle == false || $o_handle == false) {
			return false;
		}

		if (!empty($parts['query'])) {
			$parts['path'] .= '?' . $parts['query'];
		}

		/**
		 * Send the request to the server for the file
		 */
		$request = "GET {$parts['path']} HTTP/1.1\r\n";
		$request .= "Host: {$parts['host']}\r\n";
		$request .= "User-Agent: Mozilla/5.0\r\n";
		$request .= "Keep-Alive: 115\r\n";
		$request .= "Connection: keep-alive\r\n\r\n";
		fwrite($i_handle, $request);

		/**
		 * Now read the headers from the remote server. We'll need
		 * to get the content length.
		 */
		$headers = array();
		while (!feof($i_handle)) {
			$line = fgets($i_handle);
			if ($line == "\r\n") {
				break;
			}

			$headers[] = $line;
		}

		/**
		 * Look for the Content-Length header, and get the size
		 * of the remote file.
		 */
		$length = 0;
		foreach ($headers as $header) {
			if (stripos($header, 'Content-Length:') === 0) {
				$length = (int) str_replace('Content-Length: ', '', $header);
				break;
			}
		}

		/**
		 * Start reading in the remote file, and writing it to the
		 * local file one chunk at a time.
		 */
		$cnt = 0;
		while (!feof($i_handle)) {
			$buf = '';
			$buf = fread($i_handle, $chunksize);
			$bytes = fwrite($o_handle, $buf);
			if ($bytes == false) {
				return false;
			}
			$cnt += $bytes;

			/**
			 * We're done reading when we've reached the conent length
			 */
			if ($cnt >= $length) {
				break;
			}

		}

		fclose($i_handle);
		fclose($o_handle);
		return $cnt;
	}
}
