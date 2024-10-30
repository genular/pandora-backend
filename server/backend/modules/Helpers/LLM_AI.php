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


    public $SYSTEM_PROMPT = "You are an expert machine learning assistant analyzing and comparing the performance of a single model based on training and testing metrics, with a primary focus on AUCROC. Your task is to provide a concise and detailed explanation of the model’s performance and generalization ability.

        Output your findings in Markdown (.MD) format where:
        1. Training AUCROC: Describe what the model’s AUCROC during training reveals about its learning quality, such as successful learning patterns or potential overfitting.
        2. Testing AUCROC: Explain what the AUCROC score on the testing set indicates about the model’s performance on unseen data, such as its generalization capacity.
        3. Comparison and Insights: Offer a comparison of training vs. testing AUCROC values to assess robustness, potential overfitting, or underfitting. Identify any signs of imbalance, and provide insights on whether adjustments may improve performance.

        Structure your response as follows:

        Summary:
        	A detailed comparison of training and testing AUCROC performance. Explanation should cover learning quality, generalization capability, and any observed overfitting or underfitting.
        Top models:
			Identify the top-performing models. Include insights on their performance and potential areas for improvement.
        
        Make sure to maintain accuracy and clarity, ensuring the explanation is easily understandable for readers with basic machine learning knowledge.";

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
	public function get($USER_PROMPT, $USER_IMAGES = [], $SYSTEM_PROMPT = null, $open_ai_key) {
		$client = \OpenAI::client($open_ai_key);
		$content = false;
		
		if ($SYSTEM_PROMPT === null) {
			$SYSTEM_PROMPT = $this->SYSTEM_PROMPT;
		}

		// System and user prompt messages
		$messages = [
		    [
		        "role" => "system",
		        "content" => $SYSTEM_PROMPT
		    ],
		    [
		        "role" => "user",
		        "content" => $USER_PROMPT
		    ]
		];

		// Encode each image and add it to the messages array
		foreach ($USER_IMAGES as $image) {
		    $encoded_image = $image;
		    $messages[] = [
		        "role" => "user",
		        "content" => [
		            [
		                "type" => "image_url",
		                "image_url" => [
		                    "url" => "data:image/png;base64," . $encoded_image
		                ]
		            ]
		        ]
		    ];
		}

		try {
			$response = $client->chat()->create([
			    'model' => 'gpt-4o-mini-2024-07-18',
			    'messages' => $messages,
			    'max_tokens' => 5000
			]);

			$content = "";
			foreach ($response->choices as $result) {
				$content = $result->message->content;
			} 
			// Remove URLs from the markdown content
        	$content = preg_replace('/\[(.*?)\]\((https?:\/\/[^\s)]+)\)/i', '$1', $content);
		} catch (\OpenAI\Exceptions\ErrorException $e) {
			$this->logger->error("OpenAI API key is not valid!");
		}
		return $content;
	}

}
