<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:23:50
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-05 13:14:40
 */

// Tell the container how to construct the db.
// SHARED - http://container.thephpleague.com/2.x/getting-started/
$container->share('Medoo\Medoo', function () use ($container) {
	$config = $container->get('Noodlehaus\Config');
	$db_config = [
		'database_type' => 'mysql',
		'database_name' => $config->get('default.database.dbname'),
		// Started using customized DSN connection
		// 'dsn' => [
		// 	// The PDO driver name for DSN driver parameter
		// 	'driver' => 'mysql',
		// 	// The parameters with key and value for DSN
		// 	'server' => $config->get('default.database.host'),
		// 	'port' => $config->get('default.database.port'),
		// ],
		'server' => $config->get('default.database.host'),
		'port' => $config->get('default.database.port'),
		'username' => $config->get('default.database.user'),
		'password' => $config->get('default.database.password'),
		'logging' => true,
	];

	return new \Medoo\Medoo($db_config);
});
