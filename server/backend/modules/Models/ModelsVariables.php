<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2018-06-08 16:13:17
 */
namespace SIMON\Models;

use \Medoo\Medoo;
use \Monolog\Logger;
use \SIMON\Helpers\Helpers as Helpers;

class ModelsVariables {
	protected $table_name = "models_variables";
	protected $database;
	protected $logger;
	protected $Helpers;

	public function __construct(
		Medoo $database,
		Logger $logger,
		Helpers $Helpers
	) {
		$this->database = $database;
		$this->logger = $logger;
		$this->Helpers = $Helpers;
		// Log anything.
		$this->logger->addInfo("==> INFO: SIMON\Models\ModelsVariables constructed");
	}

	public function deleteByModelIDs($modelIDs) {
		$data = $this->database->delete($this->table_name, [
			"AND" => [
				"mid" => $modelIDs,
			],
		]);
		return ($data->rowCount());
	}

	public function countTotalVariables($modelsID) {
		$mids = join(',', array_map('intval', $modelsID));

		$sql = "SELECT COUNT(id) AS total
				FROM   models_variables
				WHERE  models_variables.mid IN (" . $mids . ")";

		$details = $this->database->query($sql)->fetch(\PDO::FETCH_ASSOC);
		return (intval($details["total"]));
	}

	public function getVariableImportance($resampleID, $modelsID, $page, $page_size, $sort, $sort_by) {

		$start_limit = (($page - 1) * $page_size);
		$end_limit = $page_size;

		$mids = join(',', array_map('intval', $modelsID));

		$sql = "SELECT models_variables.id                     AS id,
				       models_variables.feature_name           AS feature_name,
				       Round(Avg(models_variables.score_perc)) AS score_perc,
				       Round(Avg(models_variables.score_no))   AS score_no,
				       Round(Avg(models_variables.rank))       AS rank
				FROM   models_variables

				WHERE  models_variables.mid IN (" . $mids . ")";

		if ($sort === "+") {
			$sort = "ASC";
		} else {
			$sort = "DESC";
		}

		$sql = $sql . " GROUP BY feature_name ORDER BY " . $sort_by . " " . $sort . " LIMIT :start_limit, :end_limit;";

		$details = $this->database->query($sql, [
			":start_limit" => $start_limit,
			":end_limit" => $end_limit,
		])->fetchAll(\PDO::FETCH_ASSOC);

		$details = $this->Helpers->castArrayValues($details);

		return ($details);
	}

}
