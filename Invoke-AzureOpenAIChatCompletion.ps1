function Invoke-AzureOpenAIChatCompletion {
    <#
    .SYNOPSIS
    This script makes an API request to an OpenAI chatbot and outputs the response message.
    
    .DESCRIPTION
    This script defines functions to make an API request to an OpenAI chatbot and output the response message. The user can input their own messages and specify various parameters such as temperature and frequency penalty.
    
    .PARAMETER APIVersion
    The version of the OpenAI API to use.
    
    .PARAMETER Endpoint
    The endpoint URL for the OpenAI API.
    
    .PARAMETER Deployment
    The name of the OpenAI deployment to use.
    
    .PARAMETER User
    The name of the user making the API request.
    
    .PARAMETER Temperature
    The temperature parameter for the API request.
    
    .PARAMETER N
    The number of messages to generate for the API request.
    
    .PARAMETER FrequencyPenalty
    The frequency penalty parameter for the API request.
    
    .PARAMETER PresencePenalty
    The presence penalty parameter for the API request.
    
    .PARAMETER TopP
    The top-p parameter for the API request.
    
    .PARAMETER Stop
    The stop parameter for the API request.
    
    .PARAMETER Stream
    The stream parameter for the API request.
    
    .EXAMPLE
    PS C:\> Invoke-AzureOpenAIChatCompletion -APIVersion "2023-06-01-preview" -Endpoint "https://example.openai.azure.com" -Deployment "example_model_gpt35_!" -User "BobbyK" -Temperature 0.6 -N 1 -FrequencyPenalty 0 -PresencePenalty 0 -TopP 0 -Stop $null -Stream $false
    
    This example makes an API request to an OpenAI chatbot and outputs the response message.
    
    .NOTES
    Author: Wojciech Napierała
    Date:   2023-06-27
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$APIVersion,
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [Parameter(Mandatory = $true)]
        [string]$Deployment,
        [Parameter(Mandatory = $false)]
        [string]$User = "",
        [Parameter(Mandatory = $false)]
        [double]$Temperature = 1,
        [Parameter(Mandatory = $false)]
        [double]$TopP = 1,
        [Parameter(Mandatory = $false)]
        [int]$N = 1,
        [Parameter(Mandatory = $false)]
        [double]$FrequencyPenalty = 0,
        [Parameter(Mandatory = $false)]
        [double]$PresencePenalty = 0,
        [Parameter(Mandatory = $false)]
        [string]$Stop = $null,
        [Parameter(Mandatory = $false)]
        [bool]$Stream = $false,
        [Parameter(Mandatory = $true)]
        [string]$SystemPromptFileName,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OneTimeUserPrompt
    )
    
    # Function to generate the headers for the API request.
    function Get-Headers {
        <#
        .SYNOPSIS
        Retrieves headers for API request.
        
        .DESCRIPTION
        The function retrieves the headers required to make an API request to Azure OpenAI Text Analytics API.
        
        .PARAMETER ApiKeyVariable
        The API key used to authenticate the request. This parameter is mandatory.
        
        .EXAMPLE
        GetHeaders -ApiKey "0123456789abcdef"
        
        .OUTPUTS
        Hashtable of headers to use in API request.
        
        .NOTES
        Ensure API key is stored and retrieved securely.        
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$ApiKeyVariable
        )

        $ApiKey = $null

        try {
            if (Test-UserEnvironmentVariable -VariableName $ApiKeyVariable) {
                $ApiKey = [System.Environment]::GetEnvironmentVariable($ApiKeyVariable, "user")
            }
        }
        catch {
            Write-Error "API key '$ApiKeyVariable' not found in environment variables. Please set the environment variable before running this script."
            return $null
        }

        return @{
            "Content-Type" = "application/json"
            "api-key"      = $ApiKey
        }
               
    }
    
    # Function to get the system and user messages
    function Get-Messages {
        <#
        .SYNOPSIS
        Retrieves the system and user messages.
        
        .DESCRIPTION
        This function prompts the user for a chat message and returns an array that contains the system and user messages.
        
        .PARAMETER system_message
        The system message to be used for the chat. This parameter is mandatory.
        
        .EXAMPLE
        Get-Messages -system_message "Hello, how can I assist you today?"
        
        .OUTPUTS
        Array of system and user messages.
        #>    
        param(
            [Parameter(Mandatory = $true)]
            [string]$system_message,
            [Parameter(Mandatory = $true)]
            [string]$UserMessage

        )
        Write-Verbose "inside Get-Messages: $system_message"
        Write-Verbose "inside Get-Messages: $UserMessage"
            
        return @(
            @{
                "role"    = "system"
                "content" = $system_message
            },
            @{
                "role"    = "user"
                "content" = $userMessage
            }
        )
    }
    
    # Function to generate the body for the API request
    function Get-Body {
        <#
        .SYNOPSIS
        Generates the body for the API request.
        
        .DESCRIPTION
        This function creates the request body for the API request. It includes parameters like messages, temperature, frequency_penalty, presence_penalty, top_p, stop, stream, and user.
        
        .PARAMETER messages
        The array of messages to be used in the API request. This parameter is mandatory.
        
        .PARAMETER temperature
        The temperature parameter for the API request. This parameter is mandatory.
        
        .PARAMETER n
        The number of messages to generate for the API request. This parameter is mandatory.
        
        .PARAMETER frequency_penalty
        The frequency penalty parameter for the API request. This parameter is mandatory.
        
        .PARAMETER presence_penalty
        The presence penalty parameter for the API request. This parameter is mandatory.
        
        .PARAMETER top_p
        The top-p parameter for the API request. This parameter is mandatory.
        
        .PARAMETER stop
        The stop parameter for the API request.
        
        .PARAMETER stream
        The stream parameter for the API request. This parameter is mandatory.
        
        .PARAMETER user
        The user parameter for the API request. This parameter is mandatory.
        
        .EXAMPLE
        Get-Body -messages $messages -temperature 0.5 -n 1 -frequency_penalty 0 -presence_penalty 0 -top_p 1 -stop null -stream $false -user "JohnDoe"
        
        .OUTPUTS
        Hashtable of parameters for the API request.
        #>    
        param(
            [Parameter(Mandatory = $true)]
            [array]$messages,
            [Parameter(Mandatory = $true)]
            [double]$temperature,
            [Parameter(Mandatory = $true)]
            [int]$n,
            [Parameter(Mandatory = $true)]
            [double]$frequency_penalty,
            [Parameter(Mandatory = $true)]
            [double]$presence_penalty,
            [Parameter(Mandatory = $true)]
            [double]$top_p,
            [Parameter(Mandatory = $false)]
            [string]$stop,
            [Parameter(Mandatory = $true)]
            [bool]$stream,
            [Parameter(Mandatory = $true)]
            [string]$user
        )
    
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
    
    # Function to generate the URL for the API request
    function Get-Url {
        param (
            $Endpoint,
            $Deployment,
            $APIVersion
        )
        <#
        .SYNOPSIS
        Generates the URL for the API request.
        
        .DESCRIPTION
        This function constructs the URL used for the API request.
        
        .EXAMPLE
        Get-Url
        
        .OUTPUTS
        String of the URL for the API request.
        #> 
        return "${Endpoint}/openai/deployments/${Deployment}/chat/completions?api-version=${APIVersion}"
    }
    
    # Function to make the API request and store the response
    function Invoke-ApiRequest {
        <#
        .SYNOPSIS
        Makes the API request and stores the response.
        
        .DESCRIPTION
        This function sends a POST request to the API and returns the response. It also handles any errors during the API request.
        
        .PARAMETER url
        The URL for the API request. This parameter is mandatory.
        
        .PARAMETER headers
        The headers for the API request. This parameter is mandatory.
        
        .PARAMETER bodyJSON
        The body for the API request. This parameter is mandatory.
        
        .EXAMPLE
        Invoke-ApiRequest -url $url -headers $headers -bodyJSON $bodyJSON
        
        .OUTPUTS
        The response from the API request or null if an error occurs.
        #>    
        param(
            [Parameter(Mandatory = $true)]
            [string]$url,
            [Parameter(Mandatory = $true)]
            [hashtable]$headers,
            [Parameter(Mandatory = $true)]
            [string]$bodyJSON
        )
    
        try {
            $response = Start-Job -ScriptBlock {
                param($url, $headers, $bodyJSON)
                Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $bodyJSON -TimeoutSec 30 -ErrorAction Stop
            } -ArgumentList $url, $headers, $bodyJSON
            
            Write-Verbose ("Job: $($response | ConvertTo-Json)" )

            while (($response.JobStateInfo.State -eq 'Running') -or ($response.JobStateInfo.State -eq 'NotStarted')) {
                Write-Host "." -NoNewline -ForegroundColor Blue
                Start-Sleep -Milliseconds 1000
            }
            Write-Host ""    

            $response = Receive-Job -Id $response.Id -Wait -ErrorAction Stop

            return $response
        }
        catch {
            Write-Output $_.Error
        }
    }
    
    # Function to output the response message
    function Show-ResponseMessage {
        <#
        .SYNOPSIS
        Outputs the response message.
        
        .DESCRIPTION
        This function prints the response message to the console.
        
        .PARAMETER content
        The content to be displayed. This parameter is mandatory.
        
        .PARAMETER stream
        The stream type of the content. This parameter is mandatory.
        
        .EXAMPLE
        Show-ResponseMessage -content "Hello, how can I assist you today?" -stream "system"
        
        .OUTPUTS
        None. This function outputs the response message to the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [string]$content,
            [Parameter(Mandatory = $true)]
            [string]$stream
        )
    
        Write-Output ""
        Write-Output "Response assistant ($stream):"
        Write-Output $content
    }
    
    # Function to output the finish reason
    function Show-FinishReason {
        <#
        .SYNOPSIS
        Outputs the finish reason.
        
        .DESCRIPTION
        This function prints the finish reason to the console.
        
        .PARAMETER finishReason
        The finish reason to be displayed. This parameter is mandatory.
        
        .EXAMPLE
        Show-FinishReason -finishReason "End of conversation"
        
        .OUTPUTS
        None. This function outputs the finish reason to the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [string]$finishReason
        )
    
        Write-Output ""
        Write-Output "Finish reason: $($finishReason)"
    }
    
    # Function to output the usage
    function Show-Usage {
        <#
        .SYNOPSIS
        Outputs the usage.
        
        .DESCRIPTION
        This function prints the usage to the console.
        
        .PARAMETER usage
        The usage to be displayed. This parameter is mandatory.
        
        .EXAMPLE
        Show-Usage -usage "1"
        
        .OUTPUTS
        None. This function outputs the usage to the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [string]$usage
        )
    
        Write-Output ""
        Write-Output "Usage:"
        Write-Output $usage
    }
    
    # Function to handle errors
    function Show-Error {
        <#
        .SYNOPSIS
        Handles errors.
        
        .DESCRIPTION
        This function handles any errors during the execution of the script. It also prints the error details to the console.
        
        .PARAMETER ErrorVar
        The error variable that contains the error details. This parameter is mandatory.
        
        .EXAMPLE
        Show-Error -ErrorVar $errorVar
        
        .OUTPUTS
        None. This function handles the errors and prints the error details to the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [string]$ErrorVar
        )
    
        # If any error occurs during the process, the error details (file, line, character, and message) are printed to the console.
        Write-Host "[e] Error in file: $($ErrorVar.InvocationInfo.ScriptName)" -ForegroundColor DarkRed
        Write-Host "[e] Error in line: $($ErrorVar.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkRed
        Write-Host "[e] Error at char: $($ErrorVar.InvocationInfo.OffsetInLine)" -ForegroundColor DarkRed
        Write-Host "[e] An error occurred:" -NoNewline
        Write-Host " $($ErrorVar.Exception.Message)" -ForegroundColor DarkRed
        
        # Handle specific types of exceptions for more detailed error messages
        if ($ErrorVar.Exception -is [System.Net.WebException]) {
            Write-Host "[e] WebException: $($ErrorVar.Exception.Response.StatusCode)" -ForegroundColor DarkRed
        }
        elseif ($ErrorVar.Exception -is [System.IO.IOException]) {
            Write-Host "[e] IOException: $($ErrorVar.Exception.IOError)" -ForegroundColor DarkRed
        }
        elseif ($ErrorVar.Exception -is [System.ArgumentException]) {
            Write-Host "[e] ArgumentException: $($ErrorVar.Exception.ParamName)" -ForegroundColor DarkRed
        }
        else {
            Write-Host "[e] Unknown error type: $($ErrorVar.Exception.GetType().FullName)" -ForegroundColor DarkRed
        }
        Write-Host ""
    }
    
    # Function to test if a user environment variable exists
    function Test-UserEnvironmentVariable {
        <#
        .SYNOPSIS
        Tests if a user environment variable exists.
        
        .DESCRIPTION
        This function checks if a specific user environment variable is set.
        
        .PARAMETER VariableName
        The name of the environment variable to test. This parameter is mandatory.
        
        .EXAMPLE
        Test-UserEnvironmentVariable -VariableName "API_AZURE_OPENAI"
        
        .OUTPUTS
        Boolean value indicating whether the environment variable exists or not.
        #> 
        param (
            [Parameter(Mandatory = $true)]
            [string]$VariableName
        )
    
        $envVariables = Get-ChildItem -Path "Env:$VariableName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
        $envVariable = [Environment]::GetEnvironmentVariable($VariableName, "User")
        if ($envVariables -contains $VariableName -or $envVariable) {
            Write-Verbose "The user environment variable '$VariableName' is set."
            return $true
        }
        else {
            Write-Verbose "The user environment variable '$VariableName' is not set."
            return $false
        }
    }
    
    try {

        # Call functions to execute API request and output results
        $headers = Get-Headers -ApiKeyVariable "API_AZURE_OPENAI"

        # system prompt
        $system_message = get-content -Raw -path (Join-Path $PSScriptRoot "prompts\$SystemPromptFileName") -Encoding UTF8
        
        # cleaning system prompt
        $system_message = [System.Text.RegularExpressions.Regex]::Replace($system_message, "[^\x00-\x7F]", "")

        if ($VerbosePreference -eq "Continue") {
            Write-verbose (Show-ResponseMessage -content $system_message -stream "system" | Out-String)
        }

        # user prompt message
        if ($OneTimeUserPrompt) {
            $userMessage = $OneTimeUserPrompt
            Write-Verbose "OneTimeUserPrompt: $userMessage"
        }
        else {
            Write-Verbose "NO OneTimeUserPrompt: $userMessage"
            $userMessage = Read-Host "Enter chat message (user)"
            Write-Verbose $userMessage
        }

        Write-Verbose "after OneTimeUserPrompt: $usermessage"
        
        $messages = Get-Messages -system_message $system_message -UserMessage $userMessage
        Write-Verbose "Messages: $($messages | out-string)"

        $urlChat = Get-Url -Endpoint $Endpoint -Deployment $Deployment -APIVersion $APIVersion
        Write-Verbose "urtChat: $urlChat"

        do {
            $body = Get-Body -messages $messages -temperature $Temperature -top_p $TopP -frequency_penalty $FrequencyPenalty -presence_penalty $PresencePenalty -user $User -n $N -stop $Stop -stream $Stream

            $bodyJSON = ($body | ConvertTo-Json)
            
            Write-Host "[Chat completion]" -ForegroundColor Green
            Write-Host "{SysPFile:'${SystemPromptFileName}', temp:'${Temperature}', top_p:'${TopP}', fp:'${FrequencyPenalty}', pp:'${PresencePenalty}', user:'${User}', n:'${N}', stop:'${Stop}', stream:'${Stream}'} " -NoNewline -ForegroundColor Magenta

            $response = Invoke-ApiRequest -url $urlChat -headers $headers -bodyJSON $bodyJSON

            
            if ($null -eq $response) {
                Write-Verbose "Response is empty"
                break
            }

            Write-Verbose ("Receive job: $($response | ConvertTo-Json)" | Out-String)

            $assistant_response = $response.choices[0].message.content

            $messages += @{"role" = "assistant"; "content" = $assistant_response }

            
            if ($OneTimeUserPrompt) {
                Write-Verbose "OneTimeUserPrompt Break"
                return (Show-ResponseMessage -content $assistant_response -stream "assistant" | Out-String)
                break
            }
            else {
                Show-ResponseMessage -content $assistant_response -stream "assistant"
                Write-Verbose "NO OneTimeUserPrompt"
            
                Write-Information -MessageData (Show-FinishReason -finishReason $response.choices.finish_reason | Out-String) -InformationAction Continue
                Write-Information -MessageData (Show-Usage -usage $response.usage | Out-String) -InformationAction Continue
    
                $user_message = Read-Host "Enter chat message (user)" 
                $messages += @{"role" = "user"; "content" = $user_message }
            }
            
        } while ($true)
    }
    catch {
        #Show-Error -ErrorVar $_.Error
        Write-Output $_.Error
    }

}

    