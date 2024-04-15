# Function to generate the body for the API request
function Get-PSAOAIChatBody {
    <#
    .SYNOPSIS
    Constructs the body for the API request.
    
    .DESCRIPTION
    This function builds the body for the API request. It includes parameters such as messages, temperature, frequency_penalty, presence_penalty, top_p, stop, stream, and user.
    
    .PARAMETER messages
    An array of messages to be included in the API request. This parameter is mandatory.
    
    .PARAMETER temperature
    The temperature parameter for the API request, influencing the randomness of the chatbot's responses. This parameter is mandatory.
    
    .PARAMETER n
    The number of messages to generate for the API request. This parameter is mandatory.
    
    .PARAMETER frequency_penalty
    The frequency penalty parameter for the API request, controlling how much the model should avoid using frequent tokens. This parameter is mandatory.
    
    .PARAMETER presence_penalty
    The presence penalty parameter for the API request, controlling how much the model should favor tokens that are already present. This parameter is mandatory.
    
    .PARAMETER top_p
    The top-p parameter for the API request, controlling the nucleus sampling, a method of random sampling in the model. This parameter is mandatory.
    
    .PARAMETER stop
    The stop parameter for the API request, defining any tokens that should signal the end of a text generation.
    
    .PARAMETER stream
    The stream parameter for the API request, indicating whether the API should return intermediate results. This parameter is mandatory.
    
    .PARAMETER user
    The user parameter for the API request, representing the user initiating the request.
    
    .EXAMPLE
    Get-Body -messages $messages -temperature 0.5 -n 1 -frequency_penalty 0 -presence_penalty 0 -top_p 1 -stop null -stream $false -user "JohnDoe"
    
    .OUTPUTS
    Hashtable of parameters for the API request.
    #>    
    param(
        [Parameter(Mandatory = $true)]
        [array]$messages, # An array of messages to be included in the API request
        
        [Parameter(Mandatory = $true)]
        [double]$temperature, # The temperature parameter for the API request
        
        [Parameter(Mandatory = $true)]
        [int]$n, # The number of messages to generate for the API request
        
        [Parameter(Mandatory = $true)]
        [double]$frequency_penalty, # The frequency penalty parameter for the API request
        
        [Parameter(Mandatory = $true)]
        [double]$presence_penalty, # The presence penalty parameter for the API request
        
        [Parameter(Mandatory = $true)]
        [double]$top_p, # The top-p parameter for the API request
        
        [Parameter(Mandatory = $false)]
        [string]$stop, # The stop parameter for the API request
        
        [Parameter(Mandatory = $true)]
        [bool]$stream, # The stream parameter for the API request
        
        [Parameter(Mandatory = $false)]
        [string]$user # The user parameter for the API request
    )

    # Construct and return the body for the API request
    return @{
        'messages'          = $messages
        'temperature'       = $temperature
        'n'                 = $n
        'frequency_penalty' = $frequency_penalty
        'presence_penalty'  = $presence_penalty
        'top_p'             = $top_p
        'stop'              = $stop
        'stream'            = $stream
        'user'              = $user
    }
}
