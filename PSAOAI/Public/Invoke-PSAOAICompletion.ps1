function Invoke-PSAOAICompletion {
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
    [CmdletBinding(DefaultParameterSetName = 'Mode')]
    param(
        [Parameter(Position = 0, ValueFromPipeline)]
        [string]$usermessage,
        [Parameter(Position = 1, Mandatory = $false)]
        [int]$MaxTokens = "800",
        [Parameter(ParameterSetName = 'SamplingParameters', Mandatory = $false, HelpMessage = "What sampling temperature to use, between 0 and 2. Higher values means the model will take more risks. Try 0.9 for more creative applications, and 0 (argmax sampling) for ones with a well-defined answer. We generally recommend altering this or top_p but not both.")]
        [double]$Temperature = 1,
        [Parameter(ParameterSetName = 'SamplingParameters', Mandatory = $false, HelpMessage = 'An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. We generally recommend altering this or temperature but not both.')]
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
        [Parameter(Position = 3, Mandatory = $false)]
        [string]$User = "",
        [Parameter(Mandatory = $false)]
        [string]$model,
        [Parameter(Position = 2, ParameterSetName = 'Mode', Mandatory = $false)]
        [ValidateSet("UltraPrecise", "Precise", "Focused", "Balanced", "Informative", "Creative", "Surreal")]
        [string]$Mode,
        [Parameter(Position = 5, Mandatory = $false)]
        [switch]$simpleresponse,
        [Parameter(Mandatory = $false)]
        [string]$LogFolder,
        [Parameter(Mandatory = $false)]
        [string]$APIVersion = (Get-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_APIVERSION),
        [Parameter(Mandatory = $false)]
        [string]$Endpoint = (Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_ENDPOINT -PromptMessage "Please enter the endpoint"),
        [Parameter(Position = 4, Mandatory = $false)]
        [string]$Deployment = (Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_C_DEPLOYMENT -PromptMessage "Please enter the deployment")
    )
    
    # Define system and user messages
    function Get-Prompt {

        $prompt = Read-Host "Send a message (prompt)"

        return $prompt
    }
    
    # Output response message
    function Show-ResponseMessage {
        <#
        .SYNOPSIS
        This function outputs the response message to the console.
        
        .DESCRIPTION
        Show-ResponseMessage is a function that takes in a content and a stream type and outputs the response message. 
        The output format can be simplified by using the -simpleresponse switch.
        
        .PARAMETER content
        The content to be displayed. This parameter is mandatory.
        
        .PARAMETER stream
        The stream type of the content. This parameter is mandatory.
        
        .PARAMETER simpleresponse
        A switch parameter. If used, the function will return only the content, without the stream type.
        
        .EXAMPLE
        Show-ResponseMessage -content "Hello, how can I assist you today?" -stream "system"
        
        .EXAMPLE
        Show-ResponseMessage -content "Hello, how can I assist you today?" -stream "system" -simpleresponse
        
        .OUTPUTS
        String. This function outputs the response message to the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [string]$content, # The content to be displayed

            [Parameter(Mandatory = $true)]
            [string]$stream, # The stream type of the content

            [switch]$simpleresponse # A switch to simplify the response output
        )
    
        # Check if the simpleresponse switch is used
        if (-not $simpleresponse) {
            # Return the response message with the stream type
            return ("Response assistant ($stream):`n$content")
        }
        else {
            # Return only the content
            return $content
        }
    }

    $logfileDirectory = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath $script:modulename
    if ($LogFolder) {
        $logfileDirectory = $LogFolder
    }

    if (!(Test-Path -Path $logfileDirectory)) {
        # Create the directory if it does not exist
        New-Item -ItemType Directory -Path $logfileDirectory -Force | Out-Null
    }

    while (-not $APIVersion) {
        $APIVersion = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_APIVERSION -PromptMessage "Please enter the API Version"
    }

    while (-not $Endpoint) {
        # Get the endpoint from the environment variable
        $Endpoint = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_ENDPOINT -PromptMessage "Please enter the Endpoint"
    }

    while (-not $Deployment) {
        # Get the deployment from the environment variable
        $Deployment = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_C_DEPLOYMENT -PromptMessage "Please enter the Deployment"
    }

    while ([string]::IsNullOrEmpty($ApiKey)) {
        if (-not ($ApiKey = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API Key" -Secure)) {
            Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -VariableValue $null
            $ApiKey = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API Key" -Secure
        }
    }

    try {
        # Adjust parameters based on switches.
        switch ($Mode) {
            "Precise" {
                $UltraPrecise = $false
                $Precise = $true
                $Focused = $false
                $Balanced = $false
                $Informative = $false
                $Creative = $false
                $Surreal = $false                
            }
            "Creative" {
                $UltraPrecise = $false
                $Precise = $false
                $Focused = $false
                $Balanced = $false
                $Informative = $false
                $Creative = $true
                $Surreal = $false                
            }
            "UltraPrecise" {
                $UltraPrecise = $true
                $Precise = $false
                $Focused = $false
                $Balanced = $false
                $Informative = $false
                $Creative = $false
                $Surreal = $false                
            }
            "Focused" {
                $UltraPrecise = $false
                $Precise = $false
                $Focused = $true
                $Balanced = $false
                $Informative = $false
                $Creative = $false
                $Surreal = $false                
            }
            "Balanced" {
                $UltraPrecise = $false
                $Precise = $false
                $Focused = $false
                $Balanced = $true
                $Informative = $false
                $Creative = $false
                $Surreal = $false                
            }
            "Informative" {
                $UltraPrecise = $false
                $Precise = $false
                $Focused = $false
                $Balanced = $false
                $Informative = $true
                $Creative = $false
                $Surreal = $false                
            }
            "Surreal" {
                $UltraPrecise = $false
                $Precise = $false
                $Focused = $false
                $Balanced = $false
                $Informative = $false
                $Creative = $false
                $Surreal = $true                
            }

            default {
                # Focused
                [double]$Temperature = $Temperature
                [double]$TopP = $TopP
            }
        }

        # Adjust parameters based on switches.
        if ($UltraPrecise -or $Precise -or $Focused -or $Balanced -or $Informative -or $Creative -or $Surreal) {
            $parameters = Set-ParametersForSwitches -Creative:$Creative -Precise:$Precise -UltraPrecise:$UltraPrecise -Focused:$Focused -Balanced:$Balanced -Informative:$Informative -Surreal:$Surreal
            $Temperature = $parameters['Temperature']
            $TopP = $parameters['TopP']
        }

        # Call functions to execute API request and output results
        $headers = Get-Headers -ApiKey $script:API_AZURE_OPENAI_KEY -Secure

        #$headers | ConvertTo-Json

        if ($usermessage) {
            $prompt = Format-Message -Message $usermessage
        }
        else {
            $prompt = Get-Prompt
        }

        $userMessageHash = Get-Hash -InputString $prompt -HashType MD5
   
        $logFullNamePath = Join-Path -Path $logfileDirectory -ChildPath "$($script:modulename)Completion-${userMessageHash}.txt"
    
        Write-LogMessage -Message "User message:`n$prompt" -LogFile $logFullNamePath

        #$prompt 
        #($prompt | Measure-Object -Word -Line -Character) | out-string
        
        Write-Verbose "Parameters:"
        Write-Verbose "Prompt: $prompt"
        Write-Verbose "Temperature: $Temperature"
        Write-Verbose "Frequency Penalty: $FrequencyPenalty"
        Write-Verbose "Presence Penalty: $PresencePenalty"
        Write-Verbose "Mode: $Mode"
        Write-Verbose "TopP: $TopP"
        Write-Verbose "Stop: $Stop"
        Write-Verbose "Stream: $Stream"
        Write-Verbose "User: $User"
        Write-Verbose "Max Tokens: $MaxTokens"
        Write-Verbose "N: $n"
        Write-Verbose "Best of: $best_of"
        Write-Verbose "Logit Bias: $logit_bias"
        Write-Verbose "Logprobs: $logprobs"
        Write-Verbose "Suffix: $suffix"
        Write-Verbose "Echo: $echo"
        Write-Verbose "Completion Config: $completion_config"
        Write-Verbose "Model: $Deployment"
        Write-Verbose "LogFolder: $LogFolder"

        
        $bodyJSON = Get-PSAOAICompletionBody -prompt $prompt `
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
            -model $Deployment | ConvertTo-Json
        
        Write-Verbose ($bodyJSON | Out-String)
        
        # Get the URL for the chat
        $urlChat = Get-PSAOAIUrl -Endpoint $Endpoint -Deployment $Deployment -APIVersion $APIVersion -Mode Completion

        # If not a simple response, display chat completion and other details
        if (-not $simpleresponse) {
            Write-Host "[Completion]" -ForegroundColor Green
            if ($LogFolder) {
                Write-Host "{Logfolder:'${LogFolder}'} " -ForegroundColor Magenta
            }
            Write-Host "{MaxTokens:'$MaxTokens', temp:'$Temperature', top_p:'$TopP', fp:'$FrequencyPenalty', pp:'$PresencePenalty', user:'$User', n:'$N', stop:'$Stop', stream:'$Stream'} " -ForegroundColor Magenta
        }
        #write-host $bodyJSON -BackgroundColor Blue
        $response = Invoke-PSAOAIApiRequest -url $urlChat -headers $headers -bodyJSON $bodyJSON -timeout 240
        if (-not $($response.choices[0].text)) {
            Write-Warning "Response is empty"
            return
        }
        $responseText = (Show-ResponseMessage -content $response.choices[0].text -stream "console" -simpleresponse:$simpleresponse | out-String)
        
        if (-not $simpleresponse) {
            Show-FinishReason -finishReason $response.choices.finish_reason
            Show-Usage -usage $response.usage
        }
        Write-LogMessage -Message "Text completion:`n$($responseText.trim())" -LogFile $logFullNamePath

        return $responseText
    }
    catch {
        Format-Error -ErrorVar $_
    }
}

<#
# Define constants for environment variable names
$API_AZURE_OPENAI_APIVERSION = "API_AZURE_OPENAI_APIVERSION"
$API_AZURE_OPENAI_ENDPOINT = "API_AZURE_OPENAI_ENDPOINT"
$API_AZURE_OPENAI_DEPLOYMENT = "API_AZURE_OPENAI_DEPLOYMENT"
$API_AZURE_OPENAI_KEY = "API_AZURE_OPENAI_KEY"
    
# Get the API version from the environment variable
$APIVersion = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_APIVERSION -PromptMessage "Please enter the API version"
# Get the endpoint from the environment variable
$Endpoint = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_ENDPOINT -PromptMessage "Please enter the endpoint"
# Get the deployment from the environment variable
$Deployment = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_DEPLOYMENT -PromptMessage "Please enter the deployment"
# Get the API key from the environment variable
$ApiKey = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API key"




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