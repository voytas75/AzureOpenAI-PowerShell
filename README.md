# AzureOpenAI-PowerShell

![AzureOpenAI-PowerShell](https://github.com/voytas75/AzureOpenAI-PowerShell/blob/master/images/MSOpenAI_830x200.jpg?raw=true "AzureOpenAI-PowerShell")

Welcome to the GitHub repository for Azure OpenAI PowerShell Module and Functions! This project provides a collection of PowerShell functions that allow you to interact with Azure OpenAI's powerful language models.

## &nbsp;

> [!IMPORTANT]
> ![PSAOAI](https://github.com/voytas75/AzureOpenAI-PowerShell/blob/master/images/PSAOAI128.png?raw=true "PowerShell AZURE OpenAI")
> 
> <dl>
>  <dt><h3>Effortlessly interact with Azure OpenAI using PowerShell AZURE OpenAI (PSAOAI) Module</h3></dt>
>  <dd>
>  Streamline your interaction with Azure OpenAI's language models using PowerShell AZURE OpenAI (PSAOAI)! This comprehensive module consolidates a collection of powerful functions, empowering you to:
>
> - Simplify Management: PSAOAI centralizes all Azure OpenAI functions in one place, fostering efficient organization and access.
> - Effortless Interaction: Seamlessly interact with Azure OpenAI's language models using intuitive PowerShell commands.
> - Enhanced Productivity: Automate tasks and workflows, accelerating your development process with PSAOAI's functionalities.
>
> </dl>
> 
> <a href="./PSAOAI/README.md">:arrow_forward: Go to module page</a>

##

[What is Azure OpenAI Service?](https://learn.microsoft.com/en-us/azure/cognitive-services/openai/overview)

<details>

  <summary>Completion, Chat Completion, Embedding, and image generation</summary>

In Azure OpenAI, Completion, Chat Completions, and Embeddings are specific functionalities that leverage the power of language models to perform different tasks. Here's a brief overview of each:

1. **Completion**: Completion is a functionality that allows you to generate text completions based on a given prompt. You provide a partial sentence or context, and the language model continues the text, completing it in a way that makes sense. It's useful for tasks like content generation, text auto-completion, drafting emails, or writing code snippets. Completion models excel at generating human-like text and can provide creative and coherent completions.

2. **Chat Completion**: Chat Completions enable you to simulate interactive conversations with the language model. Instead of providing a single prompt, you provide a series of messages, including user and system messages. The model responds to each message in the conversation, maintaining context and generating appropriate replies. This functionality is particularly useful for building chatbots, virtual assistants, or automating conversational tasks such as customer support interactions.

3. **Embedding**: Embeddings refer to the numerical representations of text generated by the language models. These representations capture the semantic meaning and contextual information of the text. Embeddings allow you to measure similarity between different texts, cluster documents based on their content, or perform other operations that require understanding the relationships between pieces of text. With embeddings, you can enhance your applications with advanced language understanding and processing capabilities.

4. **DALL-E 3**: The DALL-E models, currently in preview, generate images from text prompts that the user provides.

These functionalities are part of Azure OpenAI's offering and are powered by state-of-the-art language models, such as GPT-4. They provide developers with powerful tools to leverage natural language processing and generation capabilities within their applications, automation workflows, or any task that involves working with text data.
</details>

<details>
<summary>API Key</summary>

The PowerShell code provides a function called `Get-Headers` that retrieves the headers required to make an API request to the Azure OpenAI service. One of the parameters for this function is `ApiKeyVariable`, which represents the name of the environment variable where the API key is stored. The code checks if the API key is valid by verifying if the specified environment variable exists and retrieves the API key value from it.

The API key is an essential component for authenticating and authorizing requests to the Azure OpenAI service. It acts as a unique identifier and security credential that grants access to the service. In the context of the PowerShell code, the API key is used to construct the headers for the API request, ensuring that the request is authenticated and authorized.

The `Get-Headers` function retrieves the API key from the specified environment variable and constructs the headers with the necessary content type and API key values. These headers are then used in the subsequent API request to the Azure OpenAI service.

By providing the API key through the `ApiKeyVariable` parameter when invoking the `Get-Headers` function, users can securely and conveniently authenticate their API requests to the Azure OpenAI service.

`ApiKeyVariable` = `API_AZURE_OPENAI`

</details>

## Parameters

`API version`: [preview](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview), [stable](https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable)

## Functionalities

- [x] Completion - Function [`Invoke-AzureOpenAICompletion`](#function-invoke-azureopenaicompletion)
- [x] Chat completion - Function [`Invoke-AzureOpenAIChatCompletion`](#function-invoke-azureopenaichatcompletion) ([source code](./AIEventAnalyzer/Invoke-AzureOpenAIChatCompletion.ps1))
- [x] Embedding - Function [`Invoke-AzureOpenAIEmbedding`](#function-invoke-azureopenaiembedding)
- [x] DALL-E 3 - Function [`Invoke-AzureOpenAIDalle3`](#function-invoke-azureopenaidalle3)
- [x] Helper function for displaying information about request parameters - Function [`Invoke-APICall`](#function-invoke-apicall)
- [x] AI Event Analyzer - Function [`Start-AIEventAnalyzer`](./AIEventAnalyzer/README.md) ([source code](./AIEventAnalyzer/Start-AIEventAnalyzer.ps1))

### Function: `Invoke-AzureOpenAICompletion`

This script makes an API request to an AZURE OpenAI and outputs the response message.

This script defines functions to make an API request to an AZURE OpenAI and output the response message. The user can input their own messages and specify various parameters such as temperature and frequency penalty.

#### Parameters

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
- `User`: The user to which the request will be sent. Can be empty.
- `model`: Deployed model to connect to (used in `Deployment`).

#### Usage

```powershell
. .\invoke-AzureOpenAiCompletion.ps1

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

This example makes an API request to an AZURE OpenAI and outputs the response message.

### Function: `Invoke-AzureOpenAIChatCompletion`

This PowerShell function communicates with the Azure OpenAI API to facilitate the creation of a chatbot. It transmits messages to the API and retrieves responses, enabling dynamic and interactive dialogues with the chatbot.

#### Parameters

- `APIVersion`: Defines the version of the Azure OpenAI API to be utilized.
- `Endpoint`: Specifies the endpoint URL for the Azure OpenAI API.
- `Deployment`: Denotes the name of the OpenAI deployment to be utilized.
- `User`: Identifies the user initiating the API request.
- `Temperature`: Adjusts the temperature parameter for the API request, influencing the unpredictability of the chatbot's responses.
- `N`: Sets the number of messages to be generated for the API request.
- `FrequencyPenalty`: Adjusts the frequency penalty parameter for the API request, influencing the chatbot's preference for less frequently used words.
- `PresencePenalty`: Adjusts the presence penalty parameter for the API request, influencing the chatbot's preference for contextually relevant words.
- `TopP`: Adjusts the top-p parameter for the API request, influencing the diversity of the chatbot's responses.
- `Stop`: Sets the stop parameter for the API request, indicating when the chatbot should cease generating a response.
- `Stream`: Adjusts the stream parameter for the API request, determining whether the chatbot should stream its responses.
- `SystemPromptFileName`: Identifies the file name of the system prompt.
- `SystemPrompt`: Identifies the system prompt.
- `OneTimeUserPrompt`: Identifies a one-time user prompt.
- `logfile`: Identifies the log file.
- `usermessage`: Identifies the user message.
- `usermessagelogfile`: Identifies the user message log file.
- `Precise`: Indicates whether the precise parameter is enabled.
- `Creative`: Indicates whether the creative parameter is enabled.
- `simpleresponse`: Indicates whether the simpleresponse parameter is enabled.

#### Usage

```powershell
. .\Invoke-AzureOpenAIChatCompletion.ps1

Invoke-AzureOpenAIChatCompletion `
    -APIVersion "2023-06-01-preview" `
    -Endpoint "https://example.openai.azure.com" `
    -Deployment "example_model_ada002_1" `
    -Temperature 0.6 `
    -TopP 0.7 `
    -User "BobbyK"
```

### Function: `Invoke-AzureOpenAIEmbedding`

Get a vector representation of a given input that can be easily consumed by machine learning models and other algorithms.

#### Parameters

- `APIVersion`: Version of API.
- `Endpoint`: The endpoint to which the request will be sent.
- `Deployment`: The deployment name.
- `User`: The user to which the request will be sent. Can be empty.

#### Usage

```powershell
. .\Invoke-AzureOpenAIEmbedding.ps1

Invoke-AzureOpenAIEmbedding `
    -APIVersion "2023-06-01-preview" `
    -Endpoint "https://example.openai.azure.com" `
    -Deployment "example_model_ada002_1" `
    -User "BobbyK"
```

### Function: `Invoke-AzureOpenAIDalle3`

This function generates images from a text description using Azure OpenAI's DALL-E 3 model.

#### Parameters

- `serviceName`: The name of the Azure service.
- `apiKey`: The API key for the Azure service.
- `prompt`: The text description to generate the image from.
- `model`: The model to use for image generation. Default is 'dalle3'.
- `SavePath`: The path where the generated image will be saved. Default is the user's Pictures folder.

#### Usage

```powershell
. .\Invoke-AzureOpenAIDalle3.ps1

Invoke-AzureOpenAIDalle3 `
    -serviceName "example_service" `
    -apiKey "your_api_key" `
    -prompt "A futuristic city skyline at sunset." `
    -model "dalle3" `
    -SavePath "C:\Users\BobbyK\Pictures"
```

### Function: `Invoke-APICall`

Helper function for displaying information about request parameters of AZURE OpenAI API version.

#### Syntax

```powershell
.\Invoke-APICall -RawAPIUrl <string>
```

#### Parameters

- `-RawAPIUrl` (Required): Specifies the URL of the API endpoint to make the request to.

#### Example

```powershell
Invoke-APICall -RawAPIUrl 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview/2023-06-01-preview/inference.json'
```

#### Output

The function retrieves the specification REST API for AZURE OpenAI version '2023-06-01-preview' <https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview/2023-06-01-preview>.

Other versions:<https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference>.

