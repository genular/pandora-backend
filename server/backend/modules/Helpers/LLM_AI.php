<?php

/**
 * @Author: LogIN-
 * @Date:   2018-04-03 12:22:33
 * @Last Modified by:   LogIN-
 * @Last Modified time: 2019-01-25 16:24:16
 */
namespace PANDORA\Helpers; 

use \PANDORA\Helpers\Helpers as Helpers;
use \Monolog\Logger;

class LLM_AI {
	protected $logger;
	protected $Helpers;

	public function __construct(
		Logger $logger,
		Helpers $Helpers
	) {
		$this->logger = $logger;
		$this->Helpers = $Helpers;
	}

	public function get($prompt, $open_ai_key) {

		$client = \OpenAI::client($open_ai_key);
		$content = false;

		try {
			$response =  $client->chat()->create([
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

			$content = "";
			foreach ($response->choices as $result) {
				$content = $result->message->content; // '\n\nHello there! How can I assist you today?'
			}
		} catch (\OpenAI\Exceptions\ErrorException $e) {
			$this->logger->error("OpenAI API key is not valid!");
		}

		return $content;
	}
}
