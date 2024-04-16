<#
.SYNOPSIS
This function is used to construct the body for the API Completion request.

.DESCRIPTION
The Get-PSAOAICompletionBody function takes various parameters related to the API Completion request and constructs the body of the request.

.PARAMETER prompt
This is a mandatory parameter that represents the input text.

.PARAMETER MaxTokens
This is an optional parameter that represents the maximum number of tokens in the output.

.PARAMETER temperature
This is an optional parameter that controls the randomness in the output.

.PARAMETER top_p
This is an optional parameter that controls the nucleus sampling strategy.

.PARAMETER frequency_penalty
This is an optional parameter that controls the penalty for frequent tokens.

.PARAMETER presence_penalty
This is an optional parameter that controls the penalty for new tokens.

.PARAMETER n
This is an optional parameter that controls the number of completions to generate.

.PARAMETER best_of
This is an optional parameter that controls the number of times the model will be run.

.PARAMETER Stream
This is an optional parameter that controls whether the output should be streamed.

.PARAMETER logit_bias
This is an optional parameter that controls the bias for specific tokens.

.PARAMETER logprobs
This is an optional parameter that controls the number of most probable tokens to return.

.PARAMETER suffix
This is an optional parameter that controls the text to append to the prompt.

.PARAMETER echo
This is an optional parameter that controls whether the prompt should be included in the output.

.PARAMETER completion_config
This is an optional parameter that controls the configuration for the completion.

.PARAMETER User
This is an optional parameter that represents the user.

.PARAMETER stop
This is an optional parameter that controls the tokens at which the output should stop.

.PARAMETER model
This is an optional parameter that represents the model to use for the completion.

.NOTES
    Author: Wojciech Napierala
    Date: 2024-04

#>
function Get-PSAOAICompletionBody {
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
    # The body of the request is defined using the parameters
    # The body of the request is returned
    return @{
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
}
