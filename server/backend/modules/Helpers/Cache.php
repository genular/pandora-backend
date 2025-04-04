<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:24:16 
 */
namespace PANDORA\Helpers;
use \League\Flysystem\Adapter\Local as Local;
use \League\Flysystem\Filesystem as Filesystem;
use \MatthiasMullie\Scrapbook\Adapters\Flysystem as Flysystem;
use Noodlehaus\Config as Config;
use \Monolog\Logger;

// https://www.scrapbook.cash/interfaces/key-value-store/
class Cache {
	protected $Cache;
	protected $Config;
	protected $logger;

	public function __construct(
		Logger $logger,
		Config $Config
	) {

		$this->logger = $logger;
		$this->Config = $Config;
		
		//$this->logger->addInfo("==> INFO: PANDORA\Helpers\Cache constructed");

		$cache_directory = sys_get_temp_dir() . "/" . $this->Config->get('default.salt') . "/cache";

		if (!is_dir($cache_directory)) {
		    $check = $this->createDirectory($cache_directory);
		    $this->logger->addInfo("Created cache directory: " . $cache_directory);
		} else {
		    $this->logger->addInfo("Cache directory exists: " . $cache_directory);
		}
		// create Flysystem object
		$adapter = new Local($cache_directory,  0);
		
		$filesystem = new Filesystem($adapter);
		// create Scrapbook KeyValueStore object
		$cache = new Flysystem($filesystem);

		$this->Cache = $cache;
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
	 * Retrieves an item from the cache.
	 * @param  [type] $key [description]
	 * @return [type]      [description]
	 */
	public function get($key) {
		return $this->Cache->get($key);
	}

	/**
	 * Stores a value, regardless of whether or not the key already exists (in which case it will overwrite the existing value for that key)
	 * @param [type]  $key    [description]
	 * @param [type]  $value  [description]
	 * @param integer $expire [description]
	 */
	public function set($key, $value, $expire = 0) {
		return $this->Cache->set($key, $value, $expire);
	}

	/**
	 * Retrieves an item from the cache.
	 * @param  [type] $key [description]
	 * @return [type]      [description]
	 */
	public function getArray($key) {
		$cache = $this->Cache->get($key);
		if ($cache !== false) {
			$cache = json_decode($cache, true);
		}
		return $cache;
	}

	/**
	 * Stores a value, regardless of whether or not the key already exists (in which case it will overwrite the existing value for that key)
	 * @param [type]  $key    [description]
	 * @param [type]  $value  [description]
	 * @param integer $expire [description]
	 */
	public function setArray($key, $value, $expire = 0) {
		$value = json_encode($value);
		return $this->Cache->set($key, $value, $expire);
	}

	/**
	 * Deletes an item from the cache.
	 * Returns true if item existed & was successfully deleted, false otherwise.
	 * @param  [type] $key [description]
	 * @return [type]      [description]
	 */
	public function delete($key) {
		return $this->Cache->delete($key);
	}

	/**
	 * Retrieves multiple items at once.
	 * @param  [type] $key [description]
	 * @return [type]      [description]
	 */
	public function getMulti($key) {
		return $this->Cache->getMulti($key);
	}

	/**
	 * Store multiple values at once.
	 * @param [type]  $items  [description]
	 * @param integer $expire [description]
	 */
	public function setMulti($items, $expire = 0) {
		return $this->Cache->setMulti($items, $expire);
	}

	/**
	 * Deletes multiple items at once (reduced network traffic compared to individual operations)
	 * @param  [type] $key [description]
	 * @return [type]      [description]
	 */
	public function deleteMulti($key) {
		return $this->Cache->deleteMulti($key);
	}

	/**
	 * Flushes cache
	 * @return [type] [description]
	 */
	public function flush() {
		return $this->Cache->flush();
	}
}
