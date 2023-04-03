<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:24:16
 */
namespace PANDORA\Helpers;

use Orhanerday\OpenAi\OpenAi;
use \PANDORA\Helpers\Helpers as Helpers;
use \Monolog\Logger;

class OpenAI {
	protected $logger;
	protected $Helpers;

	public function __construct(
		Logger $logger,
		Helpers $Helpers
	) {
		$this->logger = $logger;
		$this->Helpers = $Helpers;
	}

	public function get($prompt) {

		$open_ai_key = "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";
		$open_ai = new OpenAi($open_ai_key);

		$complete = $open_ai->chat([
		   'model' => 'gpt-3.5-turbo',
		   'messages' => [
		       [
		           "role" => "system",
		           "content" => "You are a helpful assistant."
		       ],
		       [
		           "role" => "user",
		           "content" => $prompt
		       ]
		   ],
		   'temperature' => 1.0,
		   'max_tokens' => 1000,
		   'frequency_penalty' => 0,
		   'presence_penalty' => 0,
		]);
	}
}
