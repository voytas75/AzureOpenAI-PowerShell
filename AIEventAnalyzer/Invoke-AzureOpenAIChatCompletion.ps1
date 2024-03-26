function Invoke-AzureOpenAIChatCompletion {
    <#
    .SYNOPSIS
    This function facilitates interaction with an Azure OpenAI chatbot by sending an API request and retrieving the chatbot's response.

    .DESCRIPTION
    Invoke-AzureOpenAIChatCompletion is a function that establishes communication with an Azure OpenAI chatbot by sending an API request and receiving the chatbot's response. It provides users with the ability to customize their messages and tweak parameters such as temperature, frequency penalty, and others to shape the chatbot's responses.

    .PARAMETER APIVersion
    Defines the version of the Azure OpenAI API to be utilized.

    .PARAMETER Endpoint
    Specifies the endpoint URL for the Azure OpenAI API.

    .PARAMETER Deployment
    Denotes the name of the OpenAI deployment to be utilized.

    .PARAMETER User
    Identifies the user initiating the API request.

    .PARAMETER Temperature
    Adjusts the temperature parameter for the API request, influencing the unpredictability of the chatbot's responses.

    .PARAMETER N
    Sets the number of messages to be generated for the API request.

    .PARAMETER FrequencyPenalty
    Adjusts the frequency penalty parameter for the API request, influencing the chatbot's preference for less frequently used words.

    .PARAMETER PresencePenalty
    Adjusts the presence penalty parameter for the API request, influencing the chatbot's preference for contextually relevant words.

    .PARAMETER TopP
    Adjusts the top-p parameter for the API request, influencing the diversity of the chatbot's responses.

    .PARAMETER Stop
    Sets the stop parameter for the API request, indicating when the chatbot should cease generating a response.

    .PARAMETER Stream
    Adjusts the stream parameter for the API request, determining whether the chatbot should stream its responses.

    .PARAMETER SystemPromptFileName
    Identifies the file name of the system prompt.

    .PARAMETER SystemPrompt
    Identifies the system prompt.

    .PARAMETER OneTimeUserPrompt
    Identifies a one-time user prompt.

    .PARAMETER logfile
    Identifies the log file.

    .PARAMETER usermessage
    Identifies the user message.

    .PARAMETER usermessagelogfile
    Identifies the user message log file.

    .PARAMETER Precise
    Indicates whether the precise parameter is enabled.

    .PARAMETER Creative
    Indicates whether the creative parameter is enabled.

    .PARAMETER simpleresponse
    Indicates whether the simpleresponse parameter is enabled.

    .EXAMPLE
    PS C:\> Invoke-AzureOpenAIChatCompletion -APIVersion "2023-06-01-preview" -Endpoint "https://example.openai.azure.com" -Deployment "example_model_gpt35_!" -User "BobbyK" -Temperature 0.6 -N 1 -FrequencyPenalty 0 -PresencePenalty 0 -TopP 0 -Stop $null -Stream $false

    This example illustrates how to send an API request to an Azure OpenAI chatbot and receive the response message.

    .NOTES
    Author: Wojciech Napierala
    Date:   2023-06-27
    #>
    [CmdletBinding(DefaultParameterSetName)]
    param(
        [Parameter(Mandatory = $false)]
        [string]$APIVersion,
        [Parameter(Mandatory = $false)]
        [string]$Endpoint,
        [Parameter(Mandatory = $false)]
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
        [Parameter(Mandatory = $false)]
        [string]$SystemPromptFileName,
        [Parameter(Mandatory = $false)]
        [string]$SystemPrompt,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OneTimeUserPrompt,
        [Parameter(Mandatory = $false)]
        [string]$logfile,
        [Parameter(ParameterSetName = 'UserMessage')]
        [string]$usermessage,
        [Parameter(ParameterSetName = 'UserMessageLogfile')]
        [string]$usermessagelogfile,
        [Parameter(ParameterSetName = 'Precise')]
        [switch]$Precise,
        [Parameter(ParameterSetName = 'Creative')]
        [switch]$Creative,
        [switch]$simpleresponse
    )

    # Function to generate the headers for the API request.
    function Get-Headers {
        <#
        .SYNOPSIS
        Generates the necessary headers for an API request to Azure OpenAI.
        
        .DESCRIPTION
        This function constructs the headers required for an API request to Azure OpenAI. It retrieves the API key from the specified environment variable and uses it for request authentication.
        
        .PARAMETER ApiKeyVariable
        Specifies the name of the environment variable that stores the API key. This parameter is mandatory.
        
        .EXAMPLE
        Get-Headers -ApiKeyVariable "OPENAI_API_KEY"
        
        .OUTPUTS
        Returns a hashtable of headers for the API request. The headers include "Content-Type" set to "application/json" and "api-key" set to the value of the API key retrieved from the environment variable.
        
        .NOTES
        It's crucial to store the API key securely in an environment variable. The function will throw an error if it can't find the API key in the specified environment variable.        
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$ApiKeyVariable
        )

        # Initialize API key variable
        $ApiKey = $null

        try {
            # Check if the API key exists in the user's environment variables
            if (Test-UserEnvironmentVariable -VariableName $ApiKeyVariable) {
                # Retrieve the API key from the environment variable
                $ApiKey = [System.Environment]::GetEnvironmentVariable($ApiKeyVariable, "user")
            }
        }
        catch {
            # Throw an error if the API key is not found
            Write-Error "API key '$ApiKeyVariable' not found in environment variables. Please set the environment variable before running this script."
            return $null
        }

        # Return the headers for the API request
        return @{
            "Content-Type" = "application/json"
            "api-key"      = $ApiKey
        }
               
    }

    # Function to assemble system and user messages
    function Get-Messages {
        <#
        .SYNOPSIS
        Assembles system and user messages into a structured array.
        
        .DESCRIPTION
        This function accepts a system message and a user message as parameters. It then structures these messages into an array, with each message represented as a hashtable with 'role' and 'content' keys.
        
        .PARAMETER system_message
        The system message to be included in the chat. This parameter is mandatory.
        
        .PARAMETER UserMessage
        The user message to be included in the chat. This parameter is mandatory.
        
        .EXAMPLE
        Get-Messages -system_message "Hello, how can I assist you today?" -UserMessage "I need help with my code."
        
        .OUTPUTS
        Array of hashtables, each representing a system or user message.
        #>    
        param(
            [Parameter(Mandatory = $true)]
            [string]$system_message,
            [Parameter(Mandatory = $true)]
            [string]$UserMessage
        )

        # Log the system and user messages for debugging purposes
        Write-Verbose "System message in Get-Messages: $system_message"
        Write-Verbose "User message in Get-Messages: $UserMessage"
            
        # Return an array of hashtables representing the system and user messages
        return @(
            @{
                "role"    = "system"
                "content" = $system_message
            },
            @{
                "role"    = "user"
                "content" = $UserMessage
            }
        )
    }

    # Function to generate the body for the API request
    function Get-Body {
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
    # Function to generate the URL for the API request
    function Get-Url {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Endpoint,
            [Parameter(Mandatory = $true)]
            [string]$Deployment,
            [Parameter(Mandatory = $true)]
            [string]$APIVersion
        )
        <#
        .SYNOPSIS
        Generates the URL for the Azure OpenAI API request.
        
        .DESCRIPTION
        This function constructs the URL used for the Azure OpenAI API request using the provided endpoint, deployment, and API version.
        
        .PARAMETER Endpoint
        The endpoint URL for the Azure OpenAI API. This parameter is mandatory.
        
        .PARAMETER Deployment
        The name of the OpenAI deployment to be used. This parameter is mandatory.
        
        .PARAMETER APIVersion
        The version of the Azure OpenAI API to be used. This parameter is mandatory.
        
        .EXAMPLE
        Get-Url -Endpoint "https://api.openai.com" -Deployment "myDeployment" -APIVersion "v1"
        
        .OUTPUTS
        String of the URL for the Azure OpenAI API request.
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
                Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $bodyJSON -TimeoutSec 240 -ErrorAction Stop
            } -ArgumentList $url, $headers, $bodyJSON
            
            Write-Verbose ("Job: $($response | ConvertTo-Json)" )

            while (($response.JobStateInfo.State -eq 'Running') -or ($response.JobStateInfo.State -eq 'NotStarted')) {
                Write-Host "." -NoNewline -ForegroundColor Blue
                Start-Sleep -Milliseconds 1000
            }
            Write-Host ""    

            if ($response.JobStateInfo.State -eq 'Failed') {
                #Write-Output $($response.ChildJobs[0].JobStateInfo.Reason.message
                
            }


            $response = Receive-Job -Id $response.Id -Wait -ErrorAction Stop

            Write-Verbose ($response | Out-String)

            return $response
        }
        catch {
            Write-Warning ($_.Exception.Message)
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
            [string]$stream,
            [switch]$simpleresponse
        )
    
        #Write-Host ""
        #Write-Host "Response assistant ($stream):"
        #Write-Host $content
        if (-not $simpleresponse) {
            return ("Response assistant ($stream):`n${content}")
        }
        else {
            return $content
        }
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
        Write-Output "(Finish reason: $finishReason)"
    }
    
    function Show-PromptFilterResults {
        <#
        .SYNOPSIS
        Outputs the prompt filter results.
        
        .DESCRIPTION
        This function prints the prompt filter results to the console.
        
        .PARAMETER response
        The prompt filter results to be displayed. This parameter is mandatory.
        
        .EXAMPLE
        Show-PromptFilterResults -prompt_filter_results "Filtered results"
        
        .OUTPUTS
        None. This function outputs the prompt filter results to the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$response
        )
    
        Write-Host ""
        Write-Host "Prompt Filter Results:"
        #Write-Output $response.prompt_filter_results

        # Iterate through each item in prompt_filter_results
        foreach ($result in $response.prompt_filter_results) {
            # Extract the content_filter_results
            $contentFilterResults = $result.content_filter_results

            # Convert content_filter_results to PowerShell object
            $contentFilterObject = $contentFilterResults | Out-String

            # Display the content_filter_results for each prompt_index
            Write-Host "Results for prompt_index $($result.prompt_index):"
            $contentFilterObject
        }
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
            #[System.Management.Automation.PSCustomObject]
            [System.Object]$usage
        )
        #$_message = @()
        #if ($usage.Count -gt 0) {
        #    [void]($usage.keys | ForEach-Object { $_message += '{0}: {1}' -f $_, $usage[$_] })
        #}
        #else {
        #    Write-Host "No usage information provided."
        #    return
        #}
        #Write-Information ($($usage | gm) | Out-String) -InformationAction Continue
        Write-Verbose ($usage | Out-String)
        Write-Verbose (($usage | gm) | Out-String)
        #$usageData = $usage.keys | ForEach-Object { "$($_): $($usage[$_])" }
        #$usageData = $usage | Get-Member | Where-Object {$_.MemberType -eq "Property"} | Format-Table Name, Value
        $usageData = $usage
        return "Usage:`n$usageData"
        #return "Usage:`n$_message"

    }
    
    # Here's an example of how the Adjust-ParametersForSwitches function might look:
    function Set-ParametersForSwitches3 {
        param(
            [bool]$Creative,
            [bool]$Precise
        )
        if ($Creative) {
            $script:Temperature = 0.7
            $script:TopP = 0.95
        }
        if ($Precise) {
            $script:Temperature = 0.3
            $script:TopP = 0.8
        }
    }

    function Set-ParametersForSwitches2 {
        param([bool]$Creative, [bool]$Precise)
        if ($Creative) {
            $Temperature = 0.7
            $TopP = 0.95
        }
        elseif ($Precise) {
            $Temperature = 0.3
            $TopP = 0.8
        }
        return @{ 'Temperature' = $Temperature; 'TopP' = $TopP }
    }
    
    function Set-ParametersForSwitches {
        <#
        .SYNOPSIS
        Adjusts temperature and top_p parameters based on the provided switches.

        .DESCRIPTION
        Sets the temperature and top_p parameters to predefined values based on whether the Creative or Precise switch is used.

        .PARAMETER Creative
        A switch to set parameters for creative output.

        .PARAMETER Precise
        A switch to set parameters for precise output.

        .OUTPUTS
        Hashtable of adjusted parameters.
        #>
        param(
            [switch]$Creative,
            [switch]$Precise
        )
        $parameters = @{
            'Temperature' = 1.0
            'TopP'        = 1.0
        }
    
        if ($Creative) {
            $parameters['Temperature'] = 0.7
            $parameters['TopP'] = 0.95
        }
        elseif ($Precise) {
            $parameters['Temperature'] = 0.3
            $parameters['TopP'] = 0.8
        }
    
        return $parameters
    }

    function Write-LogMessage {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            [Parameter(Mandatory = $true)]
            [string]$LogFile,
            [Parameter(Mandatory = $false)]
            [string]$Level = "INFO"
        )
        # Usage:
        #Write-LogMessage -Message "System prompt:`n$system_message" -LogFile $logfile -Level "VERBOSE"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp [$Level]] $Message"
        Add-Content -Path $LogFile -Value $logEntry -Force
    }
   
    function Format-Error {
        param(
            [System.Management.Automation.ErrorRecord]$ErrorVar
        )
        Write-Output $ErrorVar
    }

    function Format-Message {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message
        )
        # Usage:
        #$userMessage = Format-Message -Message $OneTimeUserPrompt
        return [System.Text.RegularExpressions.Regex]::Replace($Message, "[^\x00-\x7F]", "")
    }

    
    ##### Main program 
    $API_AZURE_OPENAI_APIVERSION = "API_AZURE_OPENAI_APIVERSION"
    $API_AZURE_OPENAI_ENDPOINT = "API_AZURE_OPENAI_ENDPOINT"
    $API_AZURE_OPENAI_DEPLOYMENT = "API_AZURE_OPENAI_DEPLOYMENT"
    $API_AZURE_OPENAI_KEY = "API_AZURE_OPENAI_KEY"
    
    $APIVersion = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_APIVERSION -PromptMessage "Please enter the API version"
    $Endpoint = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_ENDPOINT -PromptMessage "Please enter the endpoint"
    $Deployment = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_DEPLOYMENT -PromptMessage "Please enter the deployment"
    $ApiKey = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API key"
    
    try {
        # Check if usermessage is not set and usermessagelogfile is set
        if (-not $usermessage -and $usermessagelogfile) {
            # If so, read the content of usermessagelogfile and assign it to usermessage
            $usermessage = (get-content $usermessagelogfile | out-string)
        }

        if (-not $logfile) {
            if (-not $usermessagelogfile -and $usermessage -and $SystemPromptFileName) {
                $logfileBaseName = "usermessage-" + [System.IO.Path]::GetFileNameWithoutExtension($SystemPromptFileName) + "-"
                $logfileExtension = ".txt"
                $logfileDirectory = [Environment]::GetFolderPath("MyDocuments")
            }
            elseif ($OneTimeUserPrompt -and $SystemPromptFileName) {
                $logfileBaseName = "usermessage_OneTimeUserPrompt-" + [System.IO.Path]::GetFileNameWithoutExtension($SystemPromptFileName) + "-"
                $logfileExtension = ".txt"
                $logfileDirectory = [Environment]::GetFolderPath("MyDocuments")
            }
            elseif ($SystemPrompt) {
                $logfileBaseName = "SystemPrompt"
                $logfileExtension = ".txt"
                $logfileDirectory = [Environment]::GetFolderPath("MyDocuments")
                <# Action when this condition is true #>
            }
            else {
                $logfileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($usermessagelogfile)
                $logfileExtension = [System.IO.Path]::GetExtension($usermessagelogfile)
                $logfileDirectory = [System.IO.Path]::GetDirectoryName($usermessagelogfile)
                $logfileBaseName += "-" + [System.IO.Path]::GetFileNameWithoutExtension($SystemPromptFileName) + "-"
            }
            $logfileNumber = 1
            while (Test-Path -Path (Join-Path $logfileDirectory ($logfileBaseName + $logfileNumber + $logfileExtension))) {
                $logfileNumber++
            }
            $logfile = Join-Path $logfileDirectory ($logfileBaseName + $logfileNumber + $logfileExtension)
        }
        # Call functions to execute API request and output results
        $headers = Get-Headers -ApiKeyVariable "API_AZURE_OPENAI_KEY"

        # system prompt
        if ($SystemPromptFileName) {
            $system_message = get-content -path (Join-Path $PSScriptRoot "prompts\$SystemPromptFileName") -Encoding UTF8 -Raw 
        }
        else {
            $system_message = $SystemPrompt
        }
        
        # cleaning system prompt
        $system_message = [System.Text.RegularExpressions.Regex]::Replace($system_message, "[^\x00-\x7F]", "")        

        if ($VerbosePreference -eq "Continue") {
            Write-verbose (Show-ResponseMessage -content $system_message -stream "system" | Out-String)
        }

        # user prompt message
        if ($OneTimeUserPrompt) {
            # cleaning user message
            #$userMessage = [System.Text.RegularExpressions.Regex]::Replace($OneTimeUserPrompt, "[^\x00-\x7F]", "") | Out-String # must be string not array of strings
            $userMessage = Format-Message -Message $OneTimeUserPrompt
            Write-Verbose "OneTimeUserPrompt: $userMessage"
        }
        else {
            Write-Verbose "NO OneTimeUserPrompt: $userMessage"
            if (-not $userMessage) {
                $userMessage = Read-Host "Enter chat message (user)"
            }
            #$userMessage = [System.Text.RegularExpressions.Regex]::Replace($usermessage, "[^\x00-\x7F]", "") | Out-String # must be string not array of strings
            $userMessage = Format-Message -Message $userMessage
            Write-Verbose $userMessage
        }

        # Adjust parameters based on switches.
        if ($Creative -or $Precise) {
            $parameters = Set-ParametersForSwitches -Creative:$Creative -Precise:$Precise
        }
        else {
            $parameters = @{
                'Temperature' = $Temperature
                'TopP'        = $TopP
            }
        }
        
        $messages = Get-Messages -system_message $system_message -UserMessage $userMessage
        Write-Verbose "Messages: $($messages | out-string)"

        $urlChat = Get-Url -Endpoint $Endpoint -Deployment $Deployment -APIVersion $APIVersion
        Write-Verbose "urtChat: $urlChat"

        Write-LogMessage -Message "System promp:`n$system_message" -LogFile $logfile
        Write-LogMessage -Message "User message:`n$userMessage" -LogFile $logfile

        do {
            $body = Get-Body -messages $messages -temperature $parameters['Temperature'] -top_p $parameters['TopP'] -frequency_penalty $FrequencyPenalty -presence_penalty $PresencePenalty -user $User -n $N -stop $Stop -stream $Stream

            $bodyJSON = ($body | ConvertTo-Json)
            
            if (-not $simpleresponse) {
                Write-Host "[Chat completion]" -ForegroundColor Green
                if ($logfile) {
                    Write-Host "{Logfile:'${logfile}'} " -ForegroundColor Magenta
                }
                if ($SystemPromptFileName) {
                    Write-Host "{SysPFile:'${SystemPromptFileName}', temp:'$($parameters['Temperature'])', top_p:'$($parameters['TopP'])', fp:'${FrequencyPenalty}', pp:'${PresencePenalty}', user:'${User}', n:'${N}', stop:'${Stop}', stream:'${Stream}'} " -NoNewline -ForegroundColor Magenta
                }
                else {
                    Write-Host "{SysPrompt, temp:'$($parameters['Temperature'])', top_p:'$($parameters['TopP'])', fp:'${FrequencyPenalty}', pp:'${PresencePenalty}', user:'${User}', n:'${N}', stop:'${Stop}', stream:'${Stream}'} " -NoNewline -ForegroundColor Magenta
                }
            }
            $response = Invoke-ApiRequest -url $urlChat -headers $headers -bodyJSON $bodyJSON
            
            if ($null -eq $response) {
                Write-Verbose "Response is empty"
                break
            }

            Write-Verbose ("Receive job:`n$($response | ConvertTo-Json)" | Out-String)

            $assistant_response = $response.choices[0].message.content

            $messages += @{"role" = "assistant"; "content" = $assistant_response }


            if ($OneTimeUserPrompt) {
                Write-Verbose "OneTimeUserPrompt output with return"
                if (-not $simpleresponse) {
                    Write-Verbose "Show-FinishReason"
                    Write-Information -MessageData (Show-FinishReason -finishReason $response.choices.finish_reason | Out-String) -InformationAction Continue
                    Write-Verbose "Show-PromptFilterResults"
                    Write-Information -MessageData (Show-PromptFilterResults -response $response | Out-String) -InformationAction Continue
                    Write-Verbose "Show-Usage"
                    Write-Information -MessageData (Show-Usage -usage $response.usage | Out-String) -InformationAction Continue
                }
                Write-Verbose "Show-ResponseMessage - return"

                $responseText = (Show-ResponseMessage -content $assistant_response -stream "assistant" -simpleresponse:$simpleresponse | Out-String)

                Write-LogMessage -Message "OneTimeUserPrompt:`n$OneTimeUserPrompt" -LogFile $logfile
                Write-LogMessage -Message "ResponseText:`n$responseText" -LogFile $logfile

                return $responseText
            }
            else {
                Write-Verbose "NO OneTimeUserPrompt"

                Show-ResponseMessage -content $assistant_response -stream "assistant" -simpleresponse:$simpleresponse
            
                Write-LogMessage -Message "Assistant reposnse:`n$assistant_response" -LogFile $logfile

                #                Write-Information -MessageData (Show-FinishReason -finishReason $response.choices.finish_reason | Out-String) -InformationAction Continue
                
                #$usage = $response.usage
                #$usage
                #                $usage.keys
                #                $usageData = $usage.keys | ForEach-Object {"$($_): $($usage[$_])"}
                #                $usageData
                #                Write-Information -MessageData (Show-Usage -usage $response.usage | Out-String) -InformationAction Continue

                $user_message = Read-Host "Enter chat message (user)" 
                $messages += @{"role" = "user"; "content" = $user_message }

                Write-LogMessage -Message "User response:`n$user_message" -LogFile $logfile
            }
            
        } while ($true)
    }
    catch {
        Format-Error -ErrorVar $_
    }

}

function Get-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VariableName,
        [Parameter(Mandatory = $true)]
        [string]$PromptMessage
    )
    $VariableValue = [System.Environment]::GetEnvironmentVariable($VariableName, "User")
    if ([string]::IsNullOrEmpty($VariableValue)) {
        $VariableValue = Read-Host -Prompt $PromptMessage
        try {
            [System.Environment]::SetEnvironmentVariable($VariableName, $VariableValue, "User")
            if ([System.Environment]::GetEnvironmentVariable($VariableName, "User") -eq $VariableValue) {
                Write-Host "Environment variable $VariableName was set successfully."
            }
        }
        catch {
            Write-Host "Failed to set environment variable $VariableName."
        }
    }
    return $VariableValue
}

function Clear-AzureOpenAIAPIEnv {
    param()
    try {
        [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_APIVERSION", "", "User")
        [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_DEPLOYMENT", "", "User")
        [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_KEY", "", "User")
        [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_Endpoint", "", "User")
        Write-Host "Environment variables for Azure API have been deleted successfully."
    }
    catch {
        Write-Host "An error occurred while trying to delete Azure API environment variables. Please check your permissions and try again."
    }
}


$API_AZURE_OPENAI_APIVERSION = "API_AZURE_OPENAI_APIVERSION"
$API_AZURE_OPENAI_ENDPOINT = "API_AZURE_OPENAI_ENDPOINT"
$API_AZURE_OPENAI_DEPLOYMENT = "API_AZURE_OPENAI_DEPLOYMENT"
$API_AZURE_OPENAI_KEY = "API_AZURE_OPENAI_KEY"

$APIVersion = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_APIVERSION -PromptMessage "Please enter the API version"
$Endpoint = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_ENDPOINT -PromptMessage "Please enter the endpoint"
$Deployment = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_DEPLOYMENT -PromptMessage "Please enter the deployment"
$ApiKey = Get-EnvironmentVariable -VariableName $API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API key"
