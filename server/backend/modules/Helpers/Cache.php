<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-10 08:55:16
 */
namespace SIMON\Helpers;
use \League\Flysystem\Adapter\Local as Local;
use \League\Flysystem\Filesystem as Filesystem;
use \MatthiasMullie\Scrapbook\Adapters\Flysystem as Flysystem;
use \Monolog\Logger;

// https://www.scrapbook.cash/interfaces/key-value-store/
class Cache {
	protected $Cache;
	protected $logger;

	public function __construct(
		Logger $logger
	) {

		$this->logger = $logger;
		// Log anything.
		$this->logger->addInfo("==> INFO => SIMON\Helpers\Cache constructed");

		// create Flysystem object
		$adapter = new Local(sys_get_temp_dir(), LOCK_EX);
		$filesystem = new Filesystem($adapter);
		// create Scrapbook KeyValueStore object
		$cache = new Flysystem($filesystem);

		$this->Cache = $cache;
	}
	/**
	 * Retrieves an item from the cache.
	 */
	public function get($key) {
		return $this->Cache->get($key);
	}
	/**
	 * Stores a value, regardless of whether or not the key already exists (in which case it will overwrite the existing value for that key)
	 */
	public function set($key, $value, $expire = 0) {
		return $this->Cache->set($key, $value, $expire);
	}

	/**
	 * Retrieves an item from the cache.
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
	 */
	public function setArray($key, $value, $expire = 0) {
		$value = json_encode($value);
		return $this->Cache->set($key, $value, $expire);
	}

	/**
	 * Deletes an item from the cache.
	 * Returns true if item existed & was successfully deleted, false otherwise.
	 */
	public function delete($key) {
		return $this->Cache->delete($key);
	}
	/**
	 * Retrieves multiple items at once.
	 */
	public function getMulti($key) {
		return $this->Cache->getMulti($key);
	}
	/**
	 * Store multiple values at once.
	 */
	public function setMulti($items, $expire = 0) {
		return $this->Cache->setMulti($items, $expire);
	}
	/**
	 * Deletes multiple items at once (reduced network traffic compared to individual operations)
	 */
	public function deleteMulti($key) {
		return $this->Cache->deleteMulti($key);
	}
	/**
	 * Retrieves an item from the cache.
	 */
	public function flush() {
		return $this->Cache->flush();
	}
}
