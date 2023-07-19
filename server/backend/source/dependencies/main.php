<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:23:00
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-07-05 15:30:24
 */

// Dependency Container
// Slim uses a dependency container to prepare, manage, and inject application
// dependencies. Slim supports containers that implement PSR-11 or the
// Container-Interop interface. -
// https://www.slimframework.com/docs/concepts/di.html
// Pleague Container
// Pleague Container is used in this app instead of Slim’s built-in container
// (based on Pimple).
// http://container.thephpleague.com/
// http://container.thephpleague.com/2.x/
$container = $app->getContainer();

require 'config.php';
require 'notFound.php';
require 'database.php';
require 'logger.php';
require 'renderer.php';
