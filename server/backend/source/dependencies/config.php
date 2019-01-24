<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:24:26
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-05 15:36:35
 */

$container->share('Noodlehaus\Config', function () {
	$config_path = realpath(__DIR__ . '/../../../../config.yml');
	return new \Noodlehaus\Config($config_path);
});
