<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-04 16:28:54
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-03-05 15:21:02
 */

require 'source/middlewares/authorization.php';

// Executed first as it's last in (LIFE)
// Thats important! since preflight OPTIONS will otherwise fail
require 'source/middlewares/preflight.php';
