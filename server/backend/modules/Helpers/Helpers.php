<?php
namespace PANDORA\Helpers;

use Monolog\Logger;

class Helpers {

    protected $logger;

    /**
     * Constructor for the Helpers class.
     * 
     * Initializes the class with a logger instance for logging purposes.
     * 
     * @param Logger $logger A Monolog logger instance.
     */
    public function __construct(Logger $logger) {
        $this->logger = $logger;
        // Uncomment the following line to enable logging upon construction.
        // $this->logger->addInfo("==> INFO PANDORA\Helpers\Helpers constructed");
    }


    /**
     * Checks if a given string is a valid JSON.
     * 
     * @param string $string The string to be checked.
     * @return bool Returns true if the string is a valid JSON, false otherwise.
     */
    public function isJson($string) {
        json_decode($string);
        return json_last_error() === JSON_ERROR_NONE;
    }

    /**
     * Remaps the headers from their remapped names to their original names.
     * 
     * @param array $headerDetails An associative array where each key-value pair represents
     *                             the remapped header name and its original name.
     * @return array An associative array mapping remapped header names back to their original names.
     */
    public function remapHeadersToOriginal($headerDetails) {
        $remapToOriginal = [];
        foreach ($headerDetails as $key => $value) {
            $remapToOriginal[$value["remapped"]] = $value["original"];
        }
        return $remapToOriginal;
    }

    /**
     * Casts numeric values within an array to their appropriate data types.
     * 
     * Numeric strings are converted to integers or floats as appropriate, and strings
     * that are valid JSON objects or arrays are decoded into their respective PHP arrays.
     * 
     * @param array $input The array containing the values to be cast.
     * @return array The array with its numeric values cast to int or float, and JSON strings decoded.
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
				}else if ($this->isJson($rowItemValue)) {
					$input[$rowKey][$rowItemKey] = json_decode($rowItemValue, true);
				}
			}
		}
		return $input;
	}

	/**
	 * Checks if the device has an Internet connection.
	 *
	 * This method attempts to ping a well-known DNS server (Google's public DNS at 8.8.8.8)
	 * to determine if the device has an active Internet connection. It uses the `shell_exec`
	 * function to execute the ping command, which is platform-dependent and may require
	 * specific permissions or configurations on some systems.
	 *
	 * Note: This function may not work on all server configurations, especially on Windows servers
	 * or environments where `shell_exec` is disabled for security reasons.
	 *
	 * @return bool Returns true if the ping command receives a response, indicating an Internet connection is present; false otherwise.
	 */

	public static function is_connected() {
	    // First try 8.8.8.8 with a 1-second timeout
	    $output = shell_exec("ping -c 1 -W 1 8.8.4.4 2>&1");
	    if (!empty($output) && stripos($output, '1 received') !== false) {
	        return true;
	    }

	    // Then fallback to 1.1.1.1
	    $output = shell_exec("ping -c 1 -W 1 1.1.1.1 2>&1");
	    if (!empty($output) && stripos($output, '1 received') !== false) {
	        return true;
	    }

	    return true;
	}


	/**
	 * Detects the delimiter used in a CSV file.
	 *
	 * This function reads the first line of a CSV file and attempts to determine the
	 * delimiter by testing against a predefined set of possible delimiters. It counts
	 * the occurrences of each delimiter in the first line and returns the one with the
	 * highest count, assuming that is the delimiter used in the file.
	 *
	 * Supported delimiters are semicolon (;), comma (,), tab (\t), and pipe (|).
	 *
	 * Note: If multiple delimiters have the same highest count, the function will return
	 * the one that appears first in the `$delimiters` array. This function only reads
	 * the first line of the file to determine the delimiter, which may not be accurate
	 * for files with inconsistent delimiting.
	 *
	 * @param string $csvFile Path to the CSV file to be analyzed for its delimiter.
	 * @return string The detected delimiter character. If no delimiter could be detected,
	 *                the function will return `false`.
	 */
	public function detectDelimiter($csvFile) {
	    $delimiters = [
	        ';' => 0,
	        ',' => 0,
	        "\t" => 0,
	        "|" => 0,
	    ];

	    $handle = fopen($csvFile, "r");
	    if (!$handle) {
	        return false; // Could not open file
	    }
	    $firstLine = fgets($handle);
	    fclose($handle);
	    
	    foreach ($delimiters as $delimiter => &$count) {
	        $count = count(str_getcsv($firstLine, $delimiter));
	    }

	    return array_search(max($delimiters), $delimiters);
	}

	/**
	 * Locates the full path of a binary file.
	 *
	 * This method attempts to find the full path of the specified binary file using the `which` command.
	 * If the `exec` function is disabled or the binary is not found in the system's `$PATH`, it falls back
	 * to checking predefined common binary directories. This approach provides an alternative way to locate
	 * binary files when execution functions are restricted in the PHP environment.
	 *
	 * @param string $bin_file The name of the binary file to locate.
	 * @return string|false The full path to the binary file if found, or `false` if not found.
	 */
	public function which_cmd($bin_file) {
	    // Attempt to use the `which` command to find the binary
	    $path = exec("which " . escapeshellarg($bin_file)); // Escaping for security
	    $path = trim($path);

	    // If the path is empty, try predefined directories
	    if ($path === "") {
	        $additional_paths = ["/bin/", "/usr/bin/"];
	        foreach ($additional_paths as $root_path) {
	            $tmp_path = $root_path . $bin_file;
	            // Check if the file exists in the additional path
	            if (file_exists($tmp_path)) {
	                $path = $tmp_path;
	                break; // Stop searching once found
	            }
	        }

	        // If still not found, set $path to false
	        if ($path === "") {
	            $path = false;
	        }
	    }

	    return $path;
	}


	/**
	 * Renames a file or directory to a new name based on the MD5 hash of its basename.
	 *
	 * This function takes an array of path components as its parameter, constructs the original
	 * path from these components, and then renames the file or directory to a new name generated
	 * by hashing its basename with MD5. The new name retains the original directory path but
	 * replaces the basename with its MD5 hash.
	 *
	 * @param array $path_parts An associative array containing 'dirname' and 'basename'
	 *                          keys, representing the directory path and the original basename
	 *                          of the file or directory to be renamed.
	 * @return string|false Returns the new path if the renaming was successful, or `false` if it failed.
	 */
	public function renamePathToHash($path_parts) {
	    // Construct the full path to the file
	    $file_path = $path_parts['dirname'] . "/" . $path_parts['basename'];

	    if(isset($path_parts['file_hash'])){
	    	$content_hash = $path_parts['file_hash'];
	    }else{
		    // Open the file for reading
		    $file_handle = fopen($file_path, 'rb');
		    if (!$file_handle) {
		        return false; // Return false if file cannot be opened
		    }

		    // Initialize MD5 hash context
		    $ctx = hash_init('md5');
		    while (!feof($file_handle)) {
		        // Update hash with chunks of file
		        $buffer = fread($file_handle, 8192); // Read in 8KB chunks
		        hash_update($ctx, $buffer);
		    }
		    fclose($file_handle);

		    // Finalize the hash
		    $content_hash = hash_final($ctx);
	    }

	    // Construct the new path with the content-based hash
	    $file_to = $path_parts['dirname'] . "/" . $content_hash;

	    // Attempt to rename the file. If unsuccessful, return false.
	    if (!rename($file_path, $file_to)) {
	        return false;
	    }

	    return $file_to;
	}


	/**
	 * [compressPath description]
	 * @param  [type] $file_from
	 * @return [type]
	 */
	public function compressPath($file_from) {
	    // Detect paths to tar and pigz (if available)
	    $targz = $this->which_cmd("tar");
	    $pigz = $this->which_cmd("pigz") ?: "gzip"; // Fallback to gzip if pigz isn't available

	    // Ensure tar is available
	    if ($targz === false) {
	        die("error: cannot detect path to tar library compressPath: " . $this->targz);
	    }

	    // Log the original file size in MB
	    $originalSizeMB = filesize($file_from) / (1024 * 1024);
	    $this->logger->addInfo("==> Original file size: " . round($originalSizeMB, 2) . " MB");

	    // Form the command, using pigz or gzip for faster compression
	    $tar_cmd = $targz . " -cf - -C " . dirname($file_from) . " " . basename($file_from) . " | " . $pigz . " > " . $file_from . ".tar.gz";
	    exec($tar_cmd);

	    // Log the compressed file size in MB
	    $compressedSizeMB = filesize($file_from . ".tar.gz") / (1024 * 1024);
	    $this->logger->addInfo("==> Compressed file size: " . round($compressedSizeMB, 2) . " MB");

	    return $file_from . ".tar.gz";
	}



	/**
	 * Normalizes a string to be used as data names or identifiers.
	 *
	 * This function takes a string and applies several normalization steps to make it suitable
	 * for use as a data name or an identifier. It replaces certain symbols with textual
	 * representations (e.g., "+" to " pos " and "-" to " neg "), converts spaces to underscores,
	 * removes specific characters, and ensures the final string only contains alphanumeric
	 * characters and underscores. Repeated underscores are reduced to a single underscore.
	 *
	 * @param string $string The input string to be normalized.
	 * @return string The normalized string, modified to follow a consistent naming convention
	 *                suitable for identifiers, variable names, or keys.
	 */
	public function normalizeDataNames($string) {
	    $string = trim($string);
	    // Replace "+" and "-" symbols with text representations
	    $string = str_replace(["+", "-"], [" pos ", " neg "], $string);
	    // Convert spaces and consecutive spaces to a single underscore
	    $string = preg_replace('/\s+/', '_', $string);
	    // Replace other special characters with underscores or remove them
	    $string = str_replace(["/", "(", ")", ":"], ["_", "", "", ""], $string);
	    // Remove any characters that are not alphanumeric or underscore
	    $string = preg_replace("/[^A-Za-z0-9_]/", '', $string);
	    // Ensure no consecutive underscores remain
	    $string = preg_replace("/__+/", "_", $string);

	    return $string;
	}

	/**
	 * Converts a multi-dimensional, associative array to CSV data.
	 *
	 * This function takes a multi-dimensional associative array as input and generates
	 * a CSV string representation of it. Each sub-array of the input is expected to represent
	 * a row in the CSV output. The first sub-array is used to determine the header row,
	 * and subsequent sub-arrays provide the data rows.
	 *
	 * Note: All sub-arrays should have the same keys in the same order for consistent CSV columns.
	 *
	 * @param array $data The multi-dimensional associative array of data to be converted into CSV format.
	 * @return string The CSV text generated from the array.
	 */
	public function str_putcsv($data) {
	    // Open a memory stream for writing.
	    $fh = fopen('php://temp', 'rw');

	    // Check if data is not empty and is an array
	    if (!empty($data) && is_array($data)) {
	        // Write the header row to the CSV, if data is associative
	        if (array_keys($data) !== range(0, count($data) - 1)) {
	            fputcsv($fh, array_keys(reset($data)));
	        }

	        // Write out the data rows.
	        foreach ($data as $row) {
	            if (is_array($row)) {
	                fputcsv($fh, $row);
	            }
	        }
	    }

	    // Rewind the memory stream to read from the beginning.
	    rewind($fh);
	    // Read the generated CSV data from the memory stream.
	    $csv = stream_get_contents($fh);
	    // Close the memory stream.
	    fclose($fh);

	    return $csv;
	}
	/**
	 * [validateCSVFileHeader description]
	 * @param  [type] $filePath
	 * @return [type]           [description]
	 */
	public function validateCSVFileHeader($filePath) {

	    $this->logger->addInfo("==> INFO: PANDORA\Helpers\Helpers\validateCSVFileHeader: filePath: " . $filePath);

	    // Extract path information and file details
	    $this->logger->addInfo("==> Starting path and file details extraction.");
	    $path_parts = pathinfo($filePath);

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
	    $this->logger->addInfo("==> File details extracted: ", $data);

	    if (file_exists($filePath) && $data['item_type'] === 1 && $data['extension'] === '.csv') {
	        $this->logger->addInfo("==> Valid CSV file confirmed for header check.");

	        // Open the original file for reading and a temporary file for writing
	        $fileHandle = fopen($filePath, 'r');
	        $tempFilePath = $filePath . '.tmp';
	        $tempFileHandle = fopen($tempFilePath, 'w');

	        if ($fileHandle === false || $tempFileHandle === false) {
	            $this->logger->addError("==> Unable to open files for processing.");
	            if ($fileHandle) fclose($fileHandle);
	            if ($tempFileHandle) fclose($tempFileHandle);
	            return false;
	        }

	        // Read the first line and check for BOM
	        $this->logger->addInfo("==> Reading and processing header.");
	        $header = fgets($fileHandle);
	        $bom = pack("CCC", 0xef, 0xbb, 0xbf);
	        if (strncmp($header, $bom, 3) === 0) {
	            $this->logger->addInfo("==> BOM detected in header. Removing BOM.");
	            $header = substr($header, 3); // Remove BOM from header
	        }

	        // Store and log original header
	        $header = rtrim($header, "\n"); // Remove any newline characters
	        $data['details']["header"]["original"] = $header;
	        $this->logger->addInfo("==> Original header extracted: " . $header);

	        // Remap header items if valid
	        $header_items = str_getcsv($header, ",", '"', "\\");
	        if (is_array($header_items) && count($header_items) > 2) {
	            $this->logger->addInfo("==> Header is valid with at least 3 columns.");

	            $remapped = array_map(function ($index) {
	                return "column" . $index;
	            }, array_keys($header_items));

				foreach ($header_items as $itemKey => $itemValue) {
					$itemValueHash = md5($itemKey . $itemValue);
					if (!isset($data['details']["header"]["formatted"][$itemValueHash])) {
						$data['details']["header"]["formatted"][$itemValueHash] = array("original" => $itemValue, "position" => $itemKey, "remapped" => $remapped[$itemKey]);
					}
				}

	            $headerReplacedCSV = "\"" . implode('","', $remapped) . "\"\n";
	            fwrite($tempFileHandle, $headerReplacedCSV); // Write new header to temporary file
	            $this->logger->addInfo("==> New header written to temporary file.");

	            // Copy remaining lines from the original file
	            $this->logger->addInfo("==> Copying remaining lines to temporary file.");
	            while (($line = fgets($fileHandle)) !== false) {
	                fwrite($tempFileHandle, $line);
	            }

	            fclose($fileHandle);
	            fclose($tempFileHandle);

	            // Replace the original file with the temporary file
	            if (!rename($tempFilePath, $filePath)) {
	                $this->logger->addError("==> Error replacing the original file with the updated file.");
	                return false;
	            }
	            $this->logger->addInfo("==> Header replacement completed successfully.");

	            // Run Pandas command to get unique counts
	            try {
	                $this->logger->addInfo("==> Executing Pandas command for unique counts.");
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
	                if ($pandas_output === null) {
	                    $this->logger->addError("==> Error executing Pandas command. Command returned null.");
	                } else {
	                    $this->logger->addInfo("==> Pandas command executed. Output: " . $pandas_output);
	                }

	                $pandas_output = json_decode(trim($pandas_output), true);
	            } catch (Exception $e) {
	                $this->logger->addError("==> Error during Pandas command execution: " . $e->getMessage());
	                return false;
	            }

	            // Process unique counts and update header information
	            $this->logger->addInfo("==> Processing unique counts for each column.");
	            foreach ($data['details']["header"]["formatted"] as $itemKey => $itemValue) {
	                if (is_array($pandas_output) && isset($pandas_output[$itemValue["remapped"]])) {
	                    $itemValue["unique_count"] = $pandas_output[$itemValue["remapped"]];
	                    $data['details']["header"]["formatted"][$itemKey] = $itemValue;
	                } else {
	                    $itemValue["unique_count"] = false;
	                    $data['details']["header"]["formatted"][$itemKey] = $itemValue;
	                }
	            }
	            $this->logger->addInfo("==> Unique counts processed and updated.");

	        } else {
	            $this->logger->addWarning("==> Invalid header: less than 3 columns found.");
	            array_push($data['message'], "delimiters_check");
	        }
	    } else {
	        $this->logger->addWarning("==> Skipped header check for system files or non-CSV files.");
	    }

	    $this->logger->addInfo("==> Completed validateCSVFileHeader process.");
	    return $data;
	}


	/**
	 * Validates a header item against a predefined pattern.
	 *
	 * This function checks if the input string is not empty and matches a specific regex pattern.
	 * The pattern allows lowercase and uppercase alphabetic characters, numbers, accented characters,
	 * and specific symbols (underscore and hyphen). It's designed to ensure header items contain only
	 * characters that are typically safe and expected in such contexts.
	 *
	 * @param string $input The header item string to validate.
	 * @return bool Returns true if the input matches the pattern and is not empty, false otherwise.
	 */
	public function validateHeaderItem($input) {
	    // Return false if input is empty
	    if (empty($input)) {
	        return false;
	    }

	    // Define a pattern that includes alphanumeric characters, specific accented characters, underscore, and hyphen
	    $pattern = '/^([a-z0-9ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÒÓÔÕÖßÙÚÛÜÝàáâãäåçèéêëìíîïðòóôõöùúûüýÿ_-])+$/i';
	    
	    // Check if input matches the pattern
	    if (preg_match($pattern, $input) === 0) { // preg_match returns 0 if no match is found
	        return false;
	    }

	    // Input is valid
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

	public function utf8ize($data) {
	    if (is_array($data)) {
	        foreach ($data as $key => $value) {
	            $data[$key] = $this->utf8ize($value);
	        }
	    } else if (is_string($data)) {
	        return mb_convert_encoding($data, 'UTF-8', 'UTF-8');
	    }
	    return $data;
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
