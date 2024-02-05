<?php

/**
 * Provides an interface to interact with OpenAI's models, specifically designed to
 * facilitate AI-driven chat responses.
 */
namespace PANDORA\Helpers; 

use \PANDORA\Helpers\Helpers as Helpers;
use \Monolog\Logger;

class LLM_AI {
	/**
     * Logger instance to log events and errors.
     * @var Logger
     */
    protected $logger;

    /**
     * Instance of Helpers for utility functions.
     * @var Helpers
     */
    protected $Helpers;

    /**
     * Initializes the LLM_AI helper class with necessary dependencies.
     * 
     * @param Logger  $logger  Monolog logger instance for logging.
     * @param Helpers $Helpers Helpers instance for utility functions.
     */
    public function __construct(
        Logger $logger,
        Helpers $Helpers
    ) {
        $this->logger = $logger;
        $this->Helpers = $Helpers;
    }

    /**
     * Generates a response from OpenAI's model based on the provided prompt and API key.
     * 
     * This function sends a prompt to OpenAI's chat model and returns the generated response.
     * If an error occurs (e.g., invalid API key), it logs the error and returns false.
     * 
     * @param string $prompt     The user's input prompt to which the AI should respond.
     * @param string $open_ai_key API key for authenticating with OpenAI's API.
     * 
     * @return string|false The generated response from the AI model, or false on error.
     * 
     * @throws \OpenAI\Exceptions\ErrorException If there's an issue with the request.
     */
	public function get($prompt, $open_ai_key) {
		$client = \OpenAI::client($open_ai_key);
		$content = false;

		try {
			$response = $client->chat()->create([
			    'model' => 'gpt-4',
			    'messages' => [
			        [
			            "role" => "system",
			            "content" => "You are a highly knowledgeable and professional assistant with expertise in both supervised and unsupervised machine learning, data analysis, and AI technologies. You provide accurate, detailed, and understandable explanations tailored to a technical audience."
			        ],
			        [
			            "role" => "user",
			            "content" => $prompt
			        ]
			    ],
			    'temperature' => 0.7, // A lower temperature for more deterministic, less creative responses.
			    'max_tokens' => 1500, // Increase if you need more detailed responses.
			    'frequency_penalty' => 0.5, // Penalize frequent tokens to encourage diversity.
			    'presence_penalty' => 0.5, // Penalize new tokens to encourage topic focus.
			]);

			$content = "";

			foreach ($response->choices as $result) {
				$content = $result->message->content;
			}
		} catch (\OpenAI\Exceptions\ErrorException $e) {
			$this->logger->error("OpenAI API key is not valid!");
		}
		return $content;
	}
}
