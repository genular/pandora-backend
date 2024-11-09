<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-06 10:51:18
 */
namespace PANDORA\System;

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

public static function updateNginxConfig($arguments, $updatePorts) {

    // Define paths to the Nginx configuration files
    $configPaths = [
        'backend' => realpath('/etc/nginx/sites-available/genular.conf') ?: realpath(__DIR__ . '/../../../../documentation/docker_images/base_image/images/genular/etc/nginx/sites-available/genular.conf'),
        'frontend' => realpath('/etc/nginx/sites-available/default') ?: realpath(__DIR__ . '/../../../../documentation/docker_images/base_image/images/genular/etc/nginx/sites-available/default')
    ];

    $success = false;

    // Check if configuration files exist
    foreach ($configPaths as $key => $path) {
        if (!$path) {
            echo ucfirst($key) . " Nginx configuration file not found!\n";
            continue;
        }
        
        // Load the Nginx config file
        $nginxConfig = file_get_contents($path);

        // Define markers and the corresponding URLs and ports from arguments
        $placeholders = [
            '#BACKEND_URL' => $arguments['default']['backend']['server']['url'] ?? null,
            '#ANALYSIS_URL' => $arguments['default']['analysis']['server']['url'] ?? null,
            '#PLOTS_URL' => $arguments['default']['plots']['server']['url'] ?? null,
            '#FRONTEND_URL' => $arguments['default']['frontend']['server']['url'] ?? null,
            '#BACKEND_PORT' => $arguments['default']['backend']['server']['port'] ?? null,
            '#ANALYSIS_PORT' => $arguments['default']['analysis']['server']['port'] ?? null,
            '#PLOTS_PORT' => $arguments['default']['plots']['server']['port'] ?? null,
            '#FRONTEND_PORT' => $arguments['default']['frontend']['server']['port'] ?? null,
        ];

        // Replace each marker with the actual hostname and port if provided
        foreach ($placeholders as $marker => $value) {
            if ($value) {
                $parsedUrl = parse_url($value);
                $hostname = $parsedUrl['host'] ?? null;
                $port = $parsedUrl['port'] ?? (($parsedUrl['scheme'] ?? 'http') === 'https' ? 443 : 80);



                // Replace URLs with hostname in server_name directives
                if (strpos($nginxConfig, $marker) !== false && $hostname) {
                	echo "==> Updating $key Nginx configuration with new hostname: $hostname\n";
					
                    $nginxConfig = preg_replace(
                        "/server_name\s+\S+\s*;\s*$marker/m",
                        "server_name $hostname; $marker",
                        $nginxConfig
                    );
                }else{
                	echo "==> No $marker found in $key\n";
                }

                // Replace ports in listen directives
                if (strpos($nginxConfig, $marker) !== false && $port) {
                	echo "==> Updating $key Nginx configuration with new port: $port\n";
					
                    $nginxConfig = preg_replace_callback(
                        "/listen\s+\d+\s+default_server;\s*$marker/m",
                        function ($matches) use ($port, $marker) {
                            return "listen $port default_server; $marker";
                        },
                        $nginxConfig
                    );

                    $nginxConfig = preg_replace_callback(
                        "/listen\s+\[\:\:\]\:\d+\s+default_server;\s*$marker/m",
                        function ($matches) use ($port, $marker) {
                            return "listen [::]:$port default_server; $marker";
                        },
                        $nginxConfig
                    );
                }else{
                	echo "==> No $marker found in $key\n";
                }
            }
        }

        // Write updated config back to the file
        if (is_writable($path)) {
            $bytesWritten = file_put_contents($path, $nginxConfig);
            if ($bytesWritten === false) {
                echo "Failed to update " . ucfirst($key) . " Nginx configuration!\n";
            } else {
                echo ucfirst($key) . " Nginx configuration successfully updated with new hostnames and ports!\n";
                $success = true;
            }
        } else {
            echo "Permission denied: Cannot write to Nginx configuration at $path. Please adjust permissions.\n";
        }
    }

    // Reload Nginx if changes were made successfully
    if ($success) {
        exec('sudo supervisorctl status nginx:nginx_00', $output, $returnCode);

        var_dump($output);
        var_dump($returnCode);

        if ($returnCode === 0) { // Supervisor is running and managing Nginx
            echo "==> Reloading Nginx via Supervisor...\n";
            exec('sudo supervisorctl restart nginx:nginx_00', $output, $returnCode);
            
            if ($returnCode === 0) {
                echo "==> Nginx reloaded successfully.\n";
            } else {
                echo "==> Failed to reload Nginx via Supervisor.\n";
            }
        } else {
            echo "==> Supervisor not managing Nginx or not running. Skipping restart.\n";
        }
    }
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

				// Check for environment variables
				$frontendUrl = getenv('SERVER_FRONTEND_URL') ?: $arguments['default']['frontend']['server']['url'];

				$backendUrl = getenv('SERVER_BACKEND_URL') ?: $arguments['default']['backend']['server']['url'];
				$analysisUrl = getenv('SERVER_ANALYSIS_URL') ?: $arguments['default']['analysis']['server']['url'];
				$plotsUrl = getenv('SERVER_PLOTS_URL') ?: $arguments['default']['plots']['server']['url'];

				// Update $arguments with the environment variable values if they are set
				if ($frontendUrl) {
					$arguments['default']['frontend']['server']['url'] = $frontendUrl;
				}
				if ($backendUrl) {
					$arguments['default']['backend']['server']['url'] = $backendUrl;
				}
				if ($analysisUrl) {
					$arguments['default']['analysis']['server']['url'] = $analysisUrl;
				}
				if ($plotsUrl) {
					$arguments['default']['plots']['server']['url'] = $plotsUrl;
				}

				$config_path = realpath(__DIR__ . '/../../../../config.yml');
				$config = new \Noodlehaus\Config($config_path);
				$config = $config->all();

				$result = self::array_merge_recursive_distinct($config, $arguments);

				// Check if all environment variables are set before updating Nginx
				if ($frontendUrl || $backendUrl || $analysisUrl || $plotsUrl) {
					self::updateNginxConfig($arguments, true);
				} else {
					echo "Skipping Nginx configuration update: One or more environment variables are not set.\n";
				}

				try {
					$yaml = Yaml::dump($result, 2, 4);
					file_put_contents($config_path, $yaml);
					echo "Configuration successfully changed!\r\n";
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
