<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:24:16
 */
namespace SIMON\Helpers;
use \League\Flysystem\Adapter\Local as Local;
use \League\Flysystem\Filesystem as Filesystem;
use \MatthiasMullie\Scrapbook\Adapters\Flysystem as Flysystem;
use Noodlehaus\Config as Config;
use \SIMON\Helpers\Helpers as Helpers;
use \Monolog\Logger;

// https://www.scrapbook.cash/interfaces/key-value-store/
class Cache {
	protected $Cache;
	protected $Config;
	protected $logger;
	protected $Helpers;

	public function __construct(
		Logger $logger,
		Config $Config,
		Helpers $Helpers
	) {

		$this->logger = $logger;
		$this->Config = $Config;
		$this->Helpers = $Helpers;
		
		$this->logger->addInfo("==> INFO: SIMON\Helpers\Cache constructed");

		$cache_directory = sys_get_temp_dir() . "/" . $this->Config->get('default.salt') . "/cache";

		$this->Helpers->rrmdir($cache_directory);

		if (!is_dir($cache_directory)) {
			$check = $this->Helpers->createDirectory($cache_directory);
			$this->logger->addInfo("==> INFO => SIMON\Helpers\Cache directory created: " . $cache_directory); 
		}else{
			$this->logger->addInfo("==> INFO => SIMON\Helpers\Cache directory exists: " . $cache_directory);
		}
		// create Flysystem object
		$adapter = new Local($cache_directory,  0);
		
		$filesystem = new Filesystem($adapter);
		// create Scrapbook KeyValueStore object
		$cache = new Flysystem($filesystem);

		$this->Cache = $cache;
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
