<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:23:32
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-04-04 16:24:00
 */
// Override the default Not Found Handler.
// https://www.slimframework.com/docs/handlers/not-found.html
// https://juriansluiman.nl/article/156/app-notfound-for-slim-v3
$container->add('notFoundHandler', function () use ($container) {
	return function ($request, $response) use ($container) {
		return $container->get('response')
			->withStatus(404)
		// Middleware will take care of this so comment them.
		// ->withHeader('Content-Type', 'text/html')
		// ->write('Page not found')
		;
	};
});
