<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:23:40
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-05 15:36:24
 */
$container->share('Monolog\Logger', function () use ($container) {
	$settings = $container->get('settings')['logger'];
	$logger = new \Monolog\Logger($settings['name']);
	$logger->pushProcessor(new \Monolog\Processor\UidProcessor());
	$logger->pushHandler(new \Monolog\Handler\StreamHandler($settings['path'], $settings['level']));
	return $logger;
});
