# This function is used to define the body for the API Completion request
function Get-PSAOAICompletionBody {
    param(
        # The prompt is a mandatory parameter that represents the input text
        [Parameter(Mandatory = $true)]
        [string]$prompt,
        
        # MaxTokens is an optional parameter that represents the maximum number of tokens in the output
        [Parameter(Mandatory = $false)]
        [int]$MaxTokens,
        
        # Temperature is an optional parameter that controls randomness in the output
        [Parameter(Mandatory = $false)]
        [double]$temperature,
        
        # Top_p is an optional parameter that controls the nucleus sampling strategy
        [Parameter(Mandatory = $false)]
        [double]$top_p,
        
        # Frequency_penalty is an optional parameter that controls the penalty for frequent tokens
        [Parameter(Mandatory = $false)]
        [double]$frequency_penalty,
        
        # Presence_penalty is an optional parameter that controls the penalty for new tokens
        [Parameter(Mandatory = $false)]
        [double]$presence_penalty,
        
        # n is an optional parameter that controls the number of completions to generate
        [Parameter(Mandatory = $false)]
        [int]$n,
        
        # best_of is an optional parameter that controls the number of times the model will be run
        [Parameter(Mandatory = $false)]
        [int]$best_of,
        
        # Stream is an optional parameter that controls whether the output should be streamed
        [Parameter(Mandatory = $false)]
        [bool]$Stream,
        
        # Logit_bias is an optional parameter that controls the bias for specific tokens
        [Parameter(Mandatory = $false)]
        $logit_bias,
        
        # Logprobs is an optional parameter that controls the number of most probable tokens to return
        [Parameter(Mandatory = $false)]
        [int]$logprobs,
        
        # Suffix is an optional parameter that controls the text to append to the prompt
        [Parameter(Mandatory = $false)]
        [string]$suffix = $null,
        
        # Echo is an optional parameter that controls whether the prompt should be included in the output
        [Parameter(Mandatory = $false)]
        [bool]$echo,
        
        # Completion_config is an optional parameter that controls the configuration for the completion
        [Parameter(Mandatory = $false)]
        [string]$completion_config,        
        
        # User is an optional parameter that represents the user
        [Parameter(Mandatory = $false)]
        [string]$User,
        
        # Stop is an optional parameter that controls the tokens at which the output should stop
        [Parameter(Mandatory = $false)]
        $stop,
        
        # Model is an optional parameter that represents the model to use for the completion
        [Parameter(Mandatory = $false)]
        [string]$model
    )
    # Define the body of the request using the parameters
    # Return the body of the request
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
