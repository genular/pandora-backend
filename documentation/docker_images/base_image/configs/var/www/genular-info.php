<?php

/**
 * @Author: LogIN-
 * @Date:   2019-02-27 09:39:58
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-02-27 09:40:08
 */
phpinfo();

$db_connection = null;
try{
    $dbh = new pdo( 'mysql:host=127.0.0.1:3308;dbname=genular',
                    'genular',
                    'genular',
                    array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION));
    $db_connection = json_encode(array('outcome' => true));
}
catch(PDOException $ex){
    $db_connection = json_encode(array('outcome' => false, 'message' => 'Unable to connect'));
}

echo "===> DB Connection (host=127.0.0.1:3308;dbname=genular) : <br>";
echo $db_connection;

?>
