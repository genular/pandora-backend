<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:52
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-06-07 17:34:02
 */
namespace SIMON\Exceptions;

use Slim\Middleware\TokenAuthentication\UnauthorizedExceptionInterface;

class UnauthorizedException extends \Exception implements UnauthorizedExceptionInterface {
}
