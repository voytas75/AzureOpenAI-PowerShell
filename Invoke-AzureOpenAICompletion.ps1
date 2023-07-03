function Invoke-AzureOpenAICompletion {
    <#
    .SYNOPSIS
    This script makes an API request to an OpenAI chatbot and outputs the response message.
    
    .DESCRIPTION
    This script defines functions to make an API request to an OpenAI chatbot and output the response message. The user can input their own messages and specify various parameters such as temperature and frequency penalty.
    
    .PARAMETER APIVersion
    Version of API.

    .PARAMETER Endpoint
    The endpoint to which the request will be sent.

    .PARAMETER Deployment
    The deployment name.

    .PARAMETER MaxTokens
    The maximum number of tokens to generate in the completion.

    .PARAMETER Temperature
    What sampling temperature to use, between 0 and 2. Higher values means the model will take more risks. Try 0.9 for more creative applications, and 0 (argmax sampling) for ones with a well-defined answer. We generally recommend altering this or top_p but not both.

    .PARAMETER TopP
    An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or temperature but not both.

    .PARAMETER FrequencyPenalty
    Number between 0 and 2 that penalizes new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.

    .PARAMETER PresencePenalty
    Number between 0 and 2 that penalizes new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.

    .PARAMETER n
    How many completions to generate for each prompt.

    .PARAMETER best_of
    Generates best_of completions server-side and returns the "best" (the one with the highest log probability per token). Results cannot be streamed.

    .PARAMETER Stop
    Up to 4 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence.

    .PARAMETER Stream
    Whether to stream back partial progress. If set, tokens will be sent as they are generated. Recommended for applications with low latency requirements or to get results quickly as they become available. When combined with n, the API will return n stream objects.

    .PARAMETER logit_bias
    Controls sampling by adding a bias term to the logits. Positive values means the model will be more likely to generate that token, and negative values means the model will be less likely to generate that token.

    .PARAMETER logprobs
    Include the log probabilities on the logprobs most likely tokens, which can be used to derive a  lower bound on the likelihood of the response.

    .PARAMETER suffix
    Attaches a suffix to all prompt texts to help model differentiate prompt from other text encountered during training.

    .PARAMETER echo
    If true, the returned result will include the provided prompt.

    .PARAMETER completion_config
    Configuration object for the completions. Check OpenAI API documentation for more information.

    .PARAMETER User
    The user to which the request will be sent. If empty, the API will select a user automatically.

    .LINK
    Azure OpenAI Service Documentation: https://learn.microsoft.com/en-us/azure/cognitive-services/openai/
    Azure OpenAI Service REST API reference: https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference

    .EXAMPLE
    Invoke-AzureOpenAICompletion `
    -APIVersion "2023-06-01-preview" `
    -Endpoint "https://example.openai.azure.com" `
    -Deployment "example_model_gpt35_1" `
    -MaxTokens 500 `
    -Temperature 0.7 `
    -TopP 0.8 `
    -User "BobbyK"
    
    This example makes an API request to an AZURE OpenAI chatbot and outputs the response message.
    
    .NOTES
    Author: Wojciech Napierała
    Date:   2023-06-27
    Repo: https://github.com/voytas75/AzureOpenAI-PowerShell
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$APIVersion,
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [Parameter(Mandatory = $true)]
        [string]$Deployment,
        [Parameter(Mandatory = $true)]
        [int]$MaxTokens,
        [Parameter(Mandatory = $false, HelpMessage = "What sampling temperature to use, between 0 and 2. Higher values means the model will take more risks. Try 0.9 for more creative applications, and 0 (argmax sampling) for ones with a well-defined answer. We generally recommend altering this or top_p but not both.")]
        [double]$Temperature = 1,
        [Parameter(Mandatory = $false, HelpMessage = 'An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or temperature but not both.')]
        [double]$TopP = 1,
        [Parameter(Mandatory = $false)]
        [double]$FrequencyPenalty = 0,
        [Parameter(Mandatory = $false, HelpMessage = "Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.")]
        [double]$PresencePenalty = 0,
        [Parameter(Mandatory = $false, HelpMessage = "Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.")]
        [int]$n = 1,
        [Parameter(Mandatory = $false)]
        [int]$best_of = 1,
        [Parameter(Mandatory = $false)]
        [string[]]$Stop = $null,
        [Parameter(Mandatory = $false)]
        [bool]$Stream = $false,
        [Parameter(Mandatory = $false)]
        $logit_bias = @{},
        [Parameter(Mandatory = $false)]
        [int]$logprobs = $null,
        [Parameter(Mandatory = $false)]
        [string]$suffix = $null,
        [Parameter(Mandatory = $false)]
        [bool]$echo = $false,
        [Parameter(Mandatory = $false)]
        [string]$completion_config = $null,        
        [Parameter(Mandatory = $false)]
        [string]$User = $null,
        [Parameter(Mandatory = $false)]
        [string]$model = "gpt-35-turbo"

    )
    
    # Define headers for API request
    # GetHeaders: Retrieve headers for API request.
    #
    # EXAMPLE
    # GetHeaders -ApiKey "0123456789abcdef"
    #
    # INPUTS
    # -ApiKey <String>
    #   The API key used to authenticate the request. This parameter is mandatory.
    #
    # OUTPUTS
    # Hashtable of headers to use in API request.
    #
    # NOTES
    # The function retrieves the headers required to make an API request to Azure OpenAI Text Analytics API.
    #
    function Get-Headers {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$ApiKeyVariable
        )

        # Check if API key is valid
        try {
            if (Test-UserEnvironmentVariable -VariableName $ApiKeyVariable) {
                $ApiKey = [System.Environment]::GetEnvironmentVariable($ApiKeyVariable, "user")
            } 
        }
        catch {
            Write-Error "API key '$ApiKeyVariable' not found in environment variables. Please set the environment variable before running this script."
            return $null
        }

        # Construct headers
        $headers = @{
            "Content-Type" = "application/json"
            "api-key"      = $ApiKey
        }

        return $headers
    }
    # Define system and user messages
    function Get-Prompt {

        $prompt =  Read-Host "Send a message (prompt)"

        return $prompt
    }
    
    # Define body for API request
    function Get-Body {
        param(
            [Parameter(Mandatory = $true)]
            [string]$prompt,
            [Parameter(Mandatory = $false)]
            [int]$MaxTokens,
            [Parameter(Mandatory = $false)]
            [double]$temperature,
            [Parameter(Mandatory = $false)]
            [double]$top_p,
            [Parameter(Mandatory = $false)]
            [double]$frequency_penalty,
            [Parameter(Mandatory = $false)]
            [double]$presence_penalty,
            [Parameter(Mandatory = $false)]
            [int]$n,
            [Parameter(Mandatory = $false)]
            [int]$best_of,
            [Parameter(Mandatory = $false)]
            [bool]$Stream,
            [Parameter(Mandatory = $false)]
            $logit_bias,
            [Parameter(Mandatory = $false)]
            [int]$logprobs,
            [Parameter(Mandatory = $false)]
            [string]$suffix = $null,
            [Parameter(Mandatory = $false)]
            [bool]$echo,
            [Parameter(Mandatory = $false)]
            [string]$completion_config,        
            [Parameter(Mandatory = $false)]
            [string]$User,
            [Parameter(Mandatory = $false)]
            $stop,
            [Parameter(Mandatory = $false)]
            [string]$model
        )
        if ($model -eq 'gpt-35-turbo') {
            $body = @{
                'prompt'            = $prompt
                'max_tokens'        = $MaxTokens
                'temperature'       = $temperature
                'frequency_penalty' = $frequency_penalty
                'presence_penalty'  = $presence_penalty
                'top_p'             = $top_p
                'stop'              = $stop
                'stream'            = $stream
                'n'                 = $n
                'user'              = $user
                'logit_bias'        = $logit_bias
            }
            <# 
            'echo'              = $echo
            'completion_config' = $completion_config
            'best_of'           = $best_of
'suffix'            = $null

#>
        }
        else {
            $body = @{
                'prompt'            = $prompt
                'max_tokens'        = $MaxTokens
                'temperature'       = $temperature
                'frequency_penalty' = $frequency_penalty
                'presence_penalty'  = $presence_penalty
                'top_p'             = $top_p
                'stop'              = $stop
                'stream'            = $stream
                'n'                 = $n
                'user'              = $user
                'echo'              = $echo
                'logit_bias'        = $logit_bias
                'completion_config' = $completion_config
                'suffix'            = $suffix
                'best_of'           = $best_of
            }
        }    

        return $body
    }
    
    # Define URL for API request
    function Get-Url {
        $urlChat = "${Endpoint}/openai/deployments/${Deployment}/completions?api-version=${APIVersion}"

        return $urlChat
    }
    
    # Make API request and store response
    function Invoke-ApiRequest {
        param(
            [Parameter(Mandatory = $true)]
            [string]$url,
            [Parameter(Mandatory = $true)]
            [hashtable]$headers,
            [Parameter(Mandatory = $true)]
            [string]$bodyJSON
        )
    
        try {
            $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $bodyJSON -TimeoutSec 240 -ErrorAction Stop
            return $response
        }
        catch {
            Show-Error -ErrorMessage $_.Exception.Message
        }
    }
    
    # Output response message
    function Show-ResponseMessage {
        param(
            [Parameter(Mandatory = $true)]
            [string]$content,
            [Parameter(Mandatory = $true)]
            [string]$stream
        )
    
        Write-Output ""
        Write-Output "Response message ($stream):"
        Write-Output $content
    }
    
    # Output finish reason
    function Show-FinishReason {
        param(
            [Parameter(Mandatory = $true)]
            [string]$finishReason
        )
    
        Write-Output ""
        Write-Output "Finish reason: $($finishReason)"
    }
    
    # Output usage
    function Show-Usage {
        param(
            [Parameter(Mandatory = $true)]
            [string]$usage
        )
    
        Write-Output ""
        Write-Output "Usage:"
        Write-Output $usage
    }
    
    # Define function to handle errors
    function Show-Error {
        param(
            [Parameter(Mandatory = $true)]
            [string]$ErrorMessage
        )
    
        Write-Error $ErrorMessage
        # Log error to file or other logging mechanism
    }

    function Test-UserEnvironmentVariable {
        <#
        .SYNOPSIS
        Checks if a user environment variable is set.
        
        .DESCRIPTION
        This function checks if a user environment variable with the specified name is set. It searches both the environment variables under 'Env:' PSDrive and a specific environment variable named 'API_AZURE_OPENAI' for the user.
        
        .PARAMETER VariableName
        The name of the environment variable to check.
        
        .EXAMPLE
        PS C:\> Test-UserEnvironmentVariable -VariableName "MY_VARIABLE"
        
        This command checks if the user environment variable named 'MY_VARIABLE' is set.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$VariableName
        )
    
        # Get all environment variable names under 'Env:' PSDrive
        $envVariables = Get-ChildItem -Path "Env:" | Select-Object -ExpandProperty Name
    
        # Get the value of a specific user environment variable
        $envVariable = [Environment]::GetEnvironmentVariable($VariableName, "User")
    
        if ($envVariables -contains $VariableName -or $envVariable) {
            # Variable is set
            Write-Verbose "The user environment variable '$VariableName' is set."
            return $true
        }
        else {
            # Variable is not set
            Write-Verbose "The user environment variable '$VariableName' is not set."
            return $false
        }
    }

    try {

        <#         if (-not (Test-UserEnvironmentVariable -VariableName "API_AZURE_OPENAI")) {
            Write-Host "The AZURE OPENAI API key is not set."
            $variableValue = Read-Host "Please provide the AZURE OPENAI API"
            [Environment]::SetEnvironmentVariable("API_AZURE_OPENAI", $variableValue, "User")
    
        }
 #>
        # Call functions to execute API request and output results
        $headers = Get-Headers -ApiKey "API_AZURE_OPENAI"
        $prompt = Get-Prompt
        $body = Get-Body -prompt $prompt `
            -temperature $Temperature `
            -frequency_penalty $FrequencyPenalty `
            -presence_penalty $PresencePenalty `
            -top_p $TopP `
            -stop $Stop `
            -stream $Stream `
            -user $User `
            -MaxTokens $MaxTokens `
            -n $n `
            -best_of $best_of `
            -logit_bias $logit_bias `
            -logprobs $logprobs `
            -suffix $suffix `
            -echo $echo `
            -completion_config $completion_config `
            -model $model
        $bodyJSON = ($body | ConvertTo-Json)
        Write-Verbose ($bodyJSON | Out-String)
        $urlChat = Get-Url
        $response = Invoke-ApiRequest -url $urlChat -headers $headers -bodyJSON $bodyJSON
        Show-ResponseMessage -content $response.choices[0].text -stream "console"
        Show-FinishReason -finishReason $response.choices.finish_reason
        Show-Usage -usage $response.usage
    }
    catch {
        Show-Error -ErrorMessage $_.Exception.Message
    }
}

<# 
top_p:
In the context of the GPT model, the parameter top_p refers to the "top-p" or "nucleus" sampling technique. It is also known as "probability thresholding" or "penalized sampling." The top_p parameter is used during text generation to control the diversity and randomness of the generated output.

Here's how the top_p parameter works:

The model generates a probability distribution for the next word in the sequence based on the context.
The top_p parameter defines a cumulative probability threshold. Only the most likely tokens whose cumulative probability exceeds this threshold are considered for sampling.
The model ranks the tokens by their probabilities in descending order and starts calculating their cumulative probabilities.
Sampling stops once the cumulative probability exceeds the top_p threshold.
The model randomly selects one of the tokens that have surpassed the threshold, taking into account their original probabilities.
The purpose of using the top_p parameter is to control the length of the generated output and prevent it from becoming overly repetitive or nonsensical. By setting a lower top_p value, you allow more diverse and creative output, as the model considers a wider range of options beyond just the most likely tokens. Conversely, a higher top_p value makes the output more focused and deterministic.

It's important to note that top_p sampling is just one of the techniques used to control the output of text generation models. Other techniques include temperature-based sampling and beam search.

When working with the GPT model, you can experiment with different top_p values to achieve the desired balance between creativity and coherence in the generated text.


temperature:
In the context of text generation models like GPT, the "temperature" parameter is used to control the randomness and diversity of the generated output. It affects the probability distribution of the next word in the sequence.

Here's how the temperature parameter works:

The model generates a probability distribution over the vocabulary for the next word in the sequence, based on the context.
The temperature parameter is applied to this distribution.
A higher temperature value (> 1) increases randomness and diversity in the generated output. It flattens the distribution, making less likely words more probable. This can result in more unexpected or creative output.
A lower temperature value (< 1) reduces randomness and makes the output more focused and deterministic. It sharpens the distribution, giving higher probabilities to more likely words. This tends to result in more conservative and predictable output.
To illustrate the effect of temperature, let's consider an example:

Suppose the model generates a probability distribution over a vocabulary containing four words: A, B, C, and D. The distribution is as follows:

Word A: Probability = 0.6

Word B: Probability = 0.3

Word C: Probability = 0.08

Word D: Probability = 0.02

With a high temperature (e.g., 1.0), the distribution is relatively flattened, and all words have a chance of being selected, though with varying probabilities. The output may be more diverse and creative, as less likely words are given more opportunity to be chosen.

With a low temperature (e.g., 0.5), the distribution is sharpened, and the most probable word (A) is given a higher probability. The output becomes more deterministic and conservative, as the most likely words dominate the selection.

By adjusting the temperature parameter, you can control the balance between generating output that adheres closely to the training data and producing more novel or imaginative output.

It's important to note that temperature is just one of the techniques used to control the randomness in text generation models. top_p (nucleus) sampling and beam search are other commonly used techniques.

When working with the GPT model, you can experiment with different temperature values to achieve the desired balance between creativity and coherence in the generated text.

#>