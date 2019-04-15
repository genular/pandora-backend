<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-04-15 15:02:51
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

	/**
	 * [deleteByModelIDs description]
	 * @param  [int] $modelIDs [description]
	 * @return [int]           [description]
	 */
	public function deleteByModelIDs($modelIDs) {
		$data = $this->database->delete($this->table_name, [
			"AND" => [
				"mid" => $modelIDs,
			],
		]);
		return ($data->rowCount());
	}

	/**
	 * [countTotalVariables description]
	 * @param  [array] $modelsID [description]
	 * @return [int]           [description]
	 */
	public function countTotalVariables($modelsID) {
		$mids = join(',', array_map('intval', $modelsID));

		$sql = "SELECT COUNT(id) AS total
				FROM   models_variables
				WHERE  models_variables.mid IN (" . $mids . ")";

		$details = $this->database->query($sql)->fetch(\PDO::FETCH_ASSOC);
		return ((int) $details["total"]);
	}

	/**
	 * [getVariableImportance description]
	 * @param  [type] $modelsID   [description]
	 * @param  [type] $page       [description]
	 * @param  [type] $page_size  [description]
	 * @param  [type] $sort       [description]
	 * @param  [type] $sort_by    [description]
	 * @return [type]             [description]
	 */
	public function getVariableImportance($modelsID, $page, $page_size, $sort, $sort_by) {

		$start_limit = (($page - 1) * $page_size);
		$end_limit = $page_size;

		$mids = join(',', array_map('intval', $modelsID));

		$sql = "SELECT models_variables.id                     AS id,
				       models.id           					   AS model_id,
				       models_packages.internal_id             AS model_internal_id,
				       models_variables.feature_name           AS feature_name,
				       Round(Avg(models_variables.score_perc)) AS score_perc,
				       Round(Avg(models_variables.score_no))   AS score_no,
				       Round(Avg(models_variables.rank))       AS rank
				FROM   models_variables

				LEFT JOIN models ON models_variables.mid = models.id
				LEFT JOIN models_packages ON models.mpid = models_packages.id

				WHERE  models_variables.mid IN (" . $mids . ")";

		if ($sort === true) {
			$sort = "ASC";
		} else {
			$sort = "DESC";
		}

		$sql = $sql . " GROUP BY models_variables.id, models.id ORDER BY " . $sort_by . " " . $sort . " LIMIT :start_limit, :end_limit;";

		$details = $this->database->query($sql, [
			":start_limit" => $start_limit,
			":end_limit" => $end_limit,
		])->fetchAll(\PDO::FETCH_ASSOC);

		$details = $this->Helpers->castArrayValues($details);

		return ($details);
	}

}
