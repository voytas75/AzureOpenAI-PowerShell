# Invoke-AzureOpenAICompletion

This script makes an API request to an AZURE OpenAI and outputs the response message.

## Description

This script defines functions to make an API request to an AZURE OpenAI and output the response message. The user can input their own messages and specify various parameters such as temperature and frequency penalty.

### Parameters

- `APIVersion`: Version of API.
- `Endpoint`: The endpoint to which the request will be sent.
- `Deployment`: The deployment name.
- `MaxTokens`: The maximum number of tokens to generate in the completion.
- `Temperature`: What sampling temperature to use, between 0 and 2. Higher values mean the model will take more risks. Try 0.9 for more creative applications and 0 (argmax sampling) for ones with a well-defined answer.
- `TopP`: An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass.
- `FrequencyPenalty`: Number between 0 and 2 that penalizes new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.
- `PresencePenalty`: Number between 0 and 2 that penalizes new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.
- `n`: How many completions to generate for each prompt.
- `best_of`: Generates best_of completions server-side and returns the "best" (the one with the highest log probability per token).
- `Stop`: Up to 4 sequences where the API will stop generating further tokens.
- `Stream`: Whether to stream back partial progress.
- `logit_bias`: Controls sampling by adding a bias term to the logits.
- `logprobs`: Include the log probabilities on the logprobs most likely tokens.
- `suffix`: Attaches a suffix to all prompt texts to help model differentiate prompt from other text encountered during training.
- `echo`: If true, the returned result will include the provided prompt.
- `completion_config`: Configuration object for the completions.
- `User`: The user to which the request will be sent. If empty, the API will select a user automatically.

## Usage

```powershell
Invoke-AzureOpenAICompletion `
    -APIVersion "2023-06-01-preview" `
    -Endpoint "https://example.openai.azure.com" `
    -Deployment "example_model_gpt35_1" `
    -model "gpt-35-turbo" `
    -MaxTokens 500 `
    -Temperature 0.7 `
    -TopP 0.8 `
    -User "BobbyK"
```

This example makes an API request to an AZURE OpenAI chatbot and outputs the response message.

# Function Name: Invoke-APICall

## Description
This function sends an HTTP request to an API endpoint and retrieves the response using the Invoke-RestMethod cmdlet in PowerShell.

## Syntax

```powershell
Invoke-APICall -RawAPIUrl <string>
```

## Parameters

- `-RawAPIUrl` (Required): Specifies the URL of the API endpoint to make the request to.

## Example

```powershell
$response = Invoke-APICall -RawAPIUrl "https://api.example.com/endpoint"
```

## Output

The function retrieves the specification REST API for AZURE OpenAI version '2023-06-01-preview' <https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview/2023-06-01-preview>. 
Other versions:<https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference>.
