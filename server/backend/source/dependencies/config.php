<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:24:26
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-07 12:36:18
 */

$container->share('Noodlehaus\Config', function () use ($container) {
	$config_path = realpath(__DIR__ . '/../../../../config.yml');

	$config = new \Noodlehaus\Config($config_path);

	// Inject container settings from server/backend/source/config/settings.php
	$config['settings'] = $container->get('settings');

	return $config;
});
