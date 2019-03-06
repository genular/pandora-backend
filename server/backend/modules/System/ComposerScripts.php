<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-05 18:17:00
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

	public static function updateConfiguration(Event $event) {
		if (is_array($event->getArguments()) && isset($event->getArguments()[0])) {
			$argument = trim($event->getArguments()[0]);

			if (self::json_validate($argument)) {
				$arguments = json_decode($argument, true);

				$config_path = realpath(__DIR__ . '/../../../../config.yml');
				$config = new \Noodlehaus\Config($config_path);
				$config = $config->all();

				$result = array_merge($config, $arguments);

				$result = [];
				foreach ($arguments as $key => $value) {
					$result[$key] = array_merge($config[$key], $arguments[$key]);
				}
				try {
					$yaml = Yaml::dump($result, 2, 4);
					file_put_contents($config_path, $yaml);
					echo $yaml;
					echo "Configuration successfully changed!\r\n";
				} catch (ParseException $exception) {
					printf('Unable to save the YAML string: %s', $exception->getMessage());
				}
			} else {
				echo "Cannot validate JSON arguments, please check syntax!\r\n";
			}
		} else {
			echo "Cannot detect any arguments! Skipping... \r\n";
		}
	}
}
