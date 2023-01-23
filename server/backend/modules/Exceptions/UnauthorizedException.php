<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:52
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:24:41
 */
namespace PANDORA\Exceptions;

use Slim\Middleware\TokenAuthentication\UnauthorizedExceptionInterface;

class UnauthorizedException extends \Exception implements UnauthorizedExceptionInterface {
}
