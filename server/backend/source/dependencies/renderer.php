<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:25:48
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-04-04 18:01:18
 */
$container->add('Slim\Views\PhpRenderer', function () use ($container) {
	$settings = $container->get('settings')['renderer'];

	return new Slim\Views\PhpRenderer($settings['template_path']);
});
