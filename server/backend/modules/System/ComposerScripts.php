<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-06 10:51:18
 */
namespace SIMON\System;

use Composer\Script\Event;
use Symfony\Component\Yaml\Yaml;

class ComposerScripts {
	/**
	 * check if a string is JSON
	 * @param  [type] $string [description]
	 * @return [type]         [description]
	 */
	public static function json_validate($string) {
		// decode the JSON data
		json_decode($string);
		return (json_last_error() == JSON_ERROR_NONE);
	}
	/**
	 * Check if a string is a valid path or just regular content
	 * @param  string $path_or_content [description]
	 * @return [type]                  [description]
	 */
	public static function get_content(string $path_or_content) {
		$content = @file_exists($path_or_content)
		? file_get_contents($path_or_content)
		: $path_or_content;

		return $content;
	}

	/**
	 * [generateDockerConfiguration description]
	 * @param  Event  $event [description]
	 * @return [type]        [description]
	 */
	public static function generateDockerConfiguration(Event $event) {
		$config_file = "config.example.yml";
		if (is_array($event->getArguments()) && isset($event->getArguments()[0])) {
			$config_file = "config.yml";
		}
		$config_path = realpath(__DIR__ . '/../../../../' . $config_file);
		$config = new \Noodlehaus\Config($config_path);
		$config = $config->all();

		$configuration_example = json_encode($config, JSON_PRETTY_PRINT);

		file_put_contents(__DIR__ . '/../../../../documentation/docker_images/configuration.json', $configuration_example);
	}
	/**
	 * array_merge_recursive does indeed merge arrays, but it converts values with duplicate
	 * keys to arrays rather than overwriting the value in the first array with the duplicate
	 * value in the second array, as array_merge does. I.e., with array_merge_recursive,
	 * this happens (documented behavior):
	 *
	 * array_merge_recursive(array('key' => 'org value'), array('key' => 'new value'));
	 *     => array('key' => array('org value', 'new value'));
	 *
	 * array_merge_recursive_distinct does not change the datatypes of the values in the arrays.
	 * Matching keys' values in the second array overwrite those in the first array, as is the
	 * case with array_merge, i.e.:
	 *
	 * array_merge_recursive_distinct(array('key' => 'org value'), array('key' => 'new value'));
	 *     => array('key' => array('new value'));
	 *
	 * Parameters are passed by reference, though only for performance reasons. They're not
	 * altered by this function.
	 *
	 * @param array $array1
	 * @param array $array2
	 * @return array
	 * @author Daniel <daniel (at) danielsmedegaardbuus (dot) dk>
	 * @author Gabriel Sobrinho <gabriel (dot) sobrinho (at) gmail (dot) com>
	 */
	public static function array_merge_recursive_distinct(array &$array1, array &$array2) {
		$merged = $array1;
		foreach ($array2 as $key => &$value) {
			if (is_array($value) && isset($merged[$key]) && is_array($merged[$key])) {
				$merged[$key] = self::array_merge_recursive_distinct($merged[$key], $value);
			} else {
				$merged[$key] = $value;
			}
		}
		return $merged;
	}
	/**
	 * [updateConfiguration description]
	 * @param  Event  $event [description]
	 * @return [type]        [description]
	 */
	public static function updateConfiguration(Event $event) {

		if (is_array($event->getArguments()) && isset($event->getArguments()[0])) {
			$argument = trim($event->getArguments()[0]);
			$argument = self::get_content($argument);

			if (self::json_validate($argument)) {
				$arguments = json_decode($argument, true);

				$config_path = realpath(__DIR__ . '/../../../../config.yml');
				$config = new \Noodlehaus\Config($config_path);
				$config = $config->all();

				$result = self::array_merge_recursive_distinct($config, $arguments);

				try {
					$yaml = Yaml::dump($result, 2, 4);
					file_put_contents($config_path, $yaml);
					echo "Configuration successfully changed!\r\n";
					echo "==> " . $yaml . " <==\r\n";
					echo "=========================\r\n";
				} catch (ParseException $exception) {
					printf('Unable to save the YAML string: %s', $exception->getMessage());
				}
			} else {
				echo "==> ERROR: Cannot validate JSON arguments, please check syntax!\r\n";
				echo "==> " . $argument . " <==\r\n";
				echo "=========================\r\n";
			}
		} else {
			echo "Cannot detect any arguments! Skipping... \r\n";
		}
	}
}
