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
    PS C:\> Invoke-OpenAIChatbot -APIVersion "2023-06-01-preview" -Endpoint "https://example.openai.azure.com" -Deployment "example_model_gpt35_!" -User "BobbyK" -Temperature 0.6 -N 1 -FrequencyPenalty 0 -PresencePenalty 0 -TopP 0 -Stop $null -Stream $false
    
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
        [bool]$Stream = $false
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
    function Get-Messages {
        param(
            [Parameter(Mandatory)]
            [string]$system_message
        )
        $systemMessage = $system_message
    
        $userMessage = Read-Host "Enter chat message (user)"
    
        $messages = @(
            @{
                "role"    = "system"
                "content" = $systemMessage
            },
            @{
                "role"    = "user"
                "content" = $userMessage
            }
        )
        return $messages
    }
    
    # Define body for API request
    function Get-Body {
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
    
        $body = @{
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
        return $body
    }
    
    # Define URL for API request
    function Get-Url {
        $urlChat = "${Endpoint}/openai/deployments/${Deployment}/chat/completions?api-version=${APIVersion}"
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
            $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $bodyJSON -TimeoutSec 30 -ErrorAction Stop
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
        Write-Output "Response assistant ($stream):"
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
        param (
            [Parameter(Mandatory = $true)]
            [string]$VariableName
        )
    
        $envVariables = Get-ChildItem -Path "Env:" | Select-Object -ExpandProperty Name
        $envVariable = [Environment]::GetEnvironmentVariable("API_AZURE_OPENAI", "User")
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
        $headers = Get-Headers -ApiKey "API_AZURE_OPENAI"
        $system_message = "You are now a PowerShell assistant to help with improve code."
        Show-ResponseMessage -content $system_message -stream "system"
        $messages = Get-Messages -system_message $system_message
        $urlChat = Get-Url
        while ($true) {

            $body = Get-Body `
                -messages $messages `
                -temperature $Temperature `
                -top_p $TopP `
                -frequency_penalty $FrequencyPenalty `
                -presence_penalty $PresencePenalty `
                -user $User `
                -n $N `
                -stop $Stop `
                -stream $Stream

            $bodyJSON = ($body | ConvertTo-Json)
            write-verbose ($messages | Out-String)
            $response = Invoke-ApiRequest -url $urlChat -headers $headers -bodyJSON $bodyJSON
            if ($null -ne $response) {
                $assistant_response = $response.choices[0].message.content

                $messages += @{"role" = "assistant"; "content" = $assistant_response }

                Show-ResponseMessage -content $assistant_response -stream "assistant"
                Show-FinishReason -finishReason $response.choices.finish_reason
                Show-Usage -usage $response.usage

                $user_message = Read-Host "Enter chat message (user)" 
                $messages += @{"role" = "user"; "content" = $user_message }
            }
            else {
                break;
            }
    
        }
    
    }
    catch {
        Show-Error -ErrorMessage $_.Exception.Message
    }

}

    