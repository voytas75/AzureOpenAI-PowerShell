function Invoke-PSAOAIChatCompletion {
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

    .PARAMETER SystemPromptFilePath
    Specifies the path of the file containing the system prompt.
    
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
    
    .LINK
    https://learn.microsoft.com/en-us/azure/ai-services/openai/
    #>
    [CmdletBinding(DefaultParameterSetName = 'SystemPrompt_Mode')]
    param(
        [Parameter(ParameterSetName = 'SystemPrompt_Mode', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SystemPrompt_TempTop', Mandatory = $true)]
        [string]$SystemPrompt,
        [Parameter(ParameterSetName = 'SystemPromptFileName_Mode', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SystemPromptFileName_TempTop', Mandatory = $true)]
        [string]$SystemPromptFileName,
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$usermessage,
        [Parameter(Mandatory = $false)]
        [switch]$OneTimeUserPrompt,
        [Parameter(ParameterSetName = 'SystemPrompt_Mode', Mandatory = $true)]
        [Parameter(ParameterSetName = 'SystemPromptFileName_Mode', Mandatory = $true)]
        [ValidateSet("Precise", "Creative")]
        [string]$Mode,
        [Parameter(ParameterSetName = 'SystemPrompt_TempTop', Mandatory = $false)]
        [Parameter(ParameterSetName = 'SystemPromptFileName_TempTop', Mandatory = $false)]
        [Parameter(ParameterSetName = 'temptop')]
        [double]$Temperature = 1,
        [Parameter(ParameterSetName = 'SystemPrompt_TempTop', Mandatory = $false)]
        [Parameter(ParameterSetName = 'SystemPromptFileName_TempTop', Mandatory = $false)]
        [Parameter(ParameterSetName = 'temptop')]
        [double]$TopP = 1,
        [Parameter(Mandatory = $false)]
        [string]$logfile,
        [Parameter(Mandatory = $false)]
        [string]$usermessagelogfile,
        [Parameter(Mandatory = $false)]
        [switch]$simpleresponse,
        [Parameter(Mandatory = $false)]
        [string]$APIVersion = (get-apiversion -preview | select-object -first 1),
        [Parameter(Mandatory = $false)]
        [string]$Endpoint,
        [Parameter(Mandatory = $false)]
        [string]$Deployment,
        [Parameter(Mandatory = $false)]
        [string]$User = "",
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

    # This function makes an API request and stores the response
    function Invoke-ApiRequest {
        <#
        .SYNOPSIS
        Sends a POST request to the specified API and stores the response.

        .DESCRIPTION
        The Invoke-ApiRequest function sends a POST request to the API specified by the url parameter. It uses the provided headers and bodyJSON for the request. 
        If the request is successful, it returns the response. If an error occurs during the request, it handles the error and returns null.

        .PARAMETER url
        Specifies the URL for the API request. This parameter is mandatory.

        .PARAMETER headers
        Specifies the headers for the API request. This parameter is mandatory.

        .PARAMETER bodyJSON
        Specifies the body for the API request. This parameter is mandatory.

        .EXAMPLE
        Invoke-ApiRequest -url $url -headers $headers -bodyJSON $bodyJSON

        .OUTPUTS
        If successful, it outputs the response from the API request. If an error occurs, it outputs null.
        #>    
        param(
            [Parameter(Mandatory = $true)]
            [string]$url, # The URL for the API request

            [Parameter(Mandatory = $true)]
            [hashtable]$headers, # The headers for the API request

            [Parameter(Mandatory = $true)]
            [string]$bodyJSON # The body for the API request
        )
    
        # Try to send the API request and handle any errors
        try {
            # Start a new job to send the API request
            $response = Start-Job -ScriptBlock {
                param($url, $headers, $bodyJSON)
                # Send the API request
                Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $bodyJSON -TimeoutSec 240 -ErrorAction Stop
            } -ArgumentList $url, $headers, $bodyJSON
            
            # Write verbose output for the job
            Write-Verbose ("Job: $($response | ConvertTo-Json)" )

            # Wait for the job to finish
            while (($response.JobStateInfo.State -eq 'Running') -or ($response.JobStateInfo.State -eq 'NotStarted')) {
                Write-Host "." -NoNewline -ForegroundColor Blue
                Start-Sleep -Milliseconds 1000
            }
            Write-Host ""    

            # If the job failed, write the error message
            if ($response.JobStateInfo.State -eq 'Failed') {
                #Write-Output $($response.ChildJobs[0].JobStateInfo.Reason.message
            }

            # Receive the job result
            $response = Receive-Job -Id $response.Id -Wait -ErrorAction Stop

            # Write verbose output for the response
            Write-Verbose ($response | Out-String)

            # Return the response
            return $response
        }
        # Catch any errors and write a warning
        catch {
            Write-Warning ($_.Exception.Message)
        }
    }
    
    # Function to output the response message
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
            return ("Response assistant ($stream):`n${content}")
        }
        else {
            # Return only the content
            return $content
        }
    }
    
    function Show-PromptFilterResults {
        <#
        .SYNOPSIS
        Displays the results of the prompt filter.

        .DESCRIPTION
        This function takes a response object as input and iterates through the 'prompt_filter_results' property of the object. 
        For each item in 'prompt_filter_results', it extracts the 'content_filter_results' and converts it to a string. 
        The function then outputs the 'content_filter_results' for each 'prompt_index'.

        .PARAMETER response
        A PSCustomObject that contains the prompt filter results to be displayed. This parameter is mandatory.

        .EXAMPLE
        Show-PromptFilterResults -response $response

        .OUTPUTS
        String. Outputs the 'content_filter_results' for each 'prompt_index' in the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$response # The response object containing the prompt filter results
        )
    
        # Print an empty line for better readability
        Write-Host ""
        # Print the title for the output
        Write-Host "Prompt Filter Results:"

        # Iterate through each item in the 'prompt_filter_results' property of the response object
        foreach ($result in $response.prompt_filter_results) {
            # Extract the 'content_filter_results' property from the current item
            $contentFilterResults = $result.content_filter_results

            # Convert the 'content_filter_results' to a string
            $contentFilterObject = $contentFilterResults | Out-String

            # Print the 'content_filter_results' for the current 'prompt_index'
            Write-Host "Results for prompt_index $($result.prompt_index):"
            return $contentFilterObject
        }
    }
        
    function Write-LogMessage {
        <#
    .SYNOPSIS
    This function writes a log message to a specified log file.

    .DESCRIPTION
    The Write-LogMessage function takes in a message, a log file path, and an optional log level (default is "INFO"). 
    It then writes the message to the log file with a timestamp and the specified log level.

    .PARAMETER Message
    The message to be logged. This parameter is mandatory.

    .PARAMETER LogFile
    The path of the log file where the message will be written. This parameter is mandatory.

    .PARAMETER Level
    The level of the log message (e.g., "INFO", "VERBOSE", "ERROR"). This parameter is optional and defaults to "INFO".

    .EXAMPLE
    Write-LogMessage -Message "System prompt:`n$system_message" -LogFile $logfile -Level "VERBOSE"
    #>
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,
            [Parameter(Mandatory = $true)]
            [string]$LogFile,
            [Parameter(Mandatory = $false)]
            [string]$Level = "INFO"
        )
        # Get the current date and time in the format "yyyy-MM-dd HH:mm:ss"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Format the log entry
        $logEntry = "[$timestamp [$Level]] $Message"

        # Write the log entry to the log file
        Add-Content -Path $LogFile -Value $logEntry -Force
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
        $Deployment = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_CC_DEPLOYMENT -PromptMessage "Please enter the Deployment"
    }

    Write-Verbose "APIKEY: $ApiKey"
    while ([string]::IsNullOrEmpty($ApiKey)) {
        if (-not ($ApiKey = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API Key" -Secure)) {
            Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -VariableValue $null
            $ApiKey = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API Key" -Secure
        }
        
    }

    switch ($Mode) {
        "Precise" {
            $Precise = $true
            $Creative = $false
        }
        "Creative" {
            $Creative = $true
            $Precise = $false
        }
        default {
            # Code for default case
            [double]$Temperature = 1
            [double]$TopP = 1
        }
    }

    # Adjust parameters based on switches.
    if ($Creative -or $Precise) {
        $parameters = Set-ParametersForSwitches -Creative:$Creative -Precise:$Precise
        $Temperature = $parameters['Temperature']
        $TopP = $parameters['TopP']
    }
    else {
        $parameters = @{
            'Temperature' = $Temperature
            'TopP'        = $TopP
        }
    }


    if ($OneTimeUserPrompt) {
        [string]$OneTimeUserPrompt = ($usermessage | out-string)
    }

    if ($VerbosePreference -eq "Continue") {
        Write-Host "APIVersion: $APIVersion"
        Write-Host "Endpoint: $Endpoint"
        Write-Host "Deployment: $Deployment"
        Write-Host "Mode: $Mode"
        Write-Host "SystemPromptFileName: $(if($SystemPromptFileName){"exists"}else{"does not exist"})"
        Write-Host "SystemPrompt: $(if($SystemPrompt){"exists"}else{"does not exist"})"
        Write-Host "usermessage: $(if($usermessage){"exists"}else{"does not exist"})"
        Write-Host "OneTimeUserPrompt: $(if($OneTimeUserPrompt){"true"}else{"false"})"
        Write-Host "Temperature: $Temperature"
        Write-Host "TopP: $TopP"
        Write-Host "FrequencyPenalty: $FrequencyPenalty"
        Write-Host "PresencePenalty: $PresencePenalty"
        Write-Host "User: $User"
        Write-Host "N: $N"
        Write-Host "Stop: $(if($stop){"set"}else{"not set"})"
        Write-Host "Stream: $(if($stream){"true"}else{"false"})"
        Write-Host "logfile: $(if($logfile){$logfile}else{"not set"})"
        Write-Host "simpleresponse: $simpleresponse"
        Write-Host "usermessagelogfile: $usermessagelogfile"
    }

    try {
        # Check if usermessage is not set and usermessagelogfile is set
        if (-not $usermessage -and $usermessagelogfile) {
            # If so, read the content of usermessagelogfile and assign it to usermessage
            $usermessage = (get-content $usermessagelogfile | out-string)
        }

        # Check if logfile is not set
        if (-not $logfile) {
            $logfileDirectory = Join-Path -Path ([Environment]::GetFolderPath("MyDocuments")) -ChildPath $script:modulename

            if (!(Test-Path -Path $logfileDirectory)) {
                # Create the directory if it does not exist
                New-Item -ItemType Directory -Path $logfileDirectory -Force | Out-Null
            }
    
            $logfileBaseName = ""
            $logfileExtension = ".txt"
            if ($usermessage) {
                $userMessageHash = Get-Hash -InputString $usermessage -HashType MD5
                $logfileBaseName = "usermessage-$userMessageHash-"
                if ($OneTimeUserPrompt) {
                    $logfileBaseName = "usermessage-OneTimeUserPrompt-$userMessageHash-"
                }
            }
            if ($SystemPrompt) {
                $SystemMessageHash = Get-Hash -InputString $SystemPrompt -HashType MD5
                $logfileBaseName += "SystemPrompt-$SystemMessageHash-"
            }
            elseif ($SystemPromptFileName) {
                $logfileBaseName += "SystemPrompt-" + [System.IO.Path]::GetFileNameWithoutExtension($SystemPromptFileName) + "-"
            }

            # Initialize logfileNumber to 1
            $logfileNumber = 1
            # Increment logfileNumber until a unique logfile name is found
            while (Test-Path -Path (Join-Path $logfileDirectory ($logfileBaseName + $logfileNumber + $logfileExtension))) {
                $logfileNumber++
            }
            # Set logfile to the unique logfile name
            $logfile = Join-Path $logfileDirectory ($logfileBaseName + $logfileNumber + $logfileExtension)
        }

        # Call functions to execute API request and output results
        $headers = Get-Headers -ApiKeyVariable $script:API_AZURE_OPENAI_KEY -Secure

        # system prompt
        if ($SystemPromptFileName) {
            #$system_message = get-content -path (Join-Path $PSScriptRoot "prompts\$SystemPromptFileName") -Encoding UTF8 -Raw 
            $system_message = get-content -path $SystemPromptFileName -Encoding UTF8 -Raw 
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
        
        # Get the messages from the system and user
        $messages = Get-Messages -system_message $system_message -UserMessage $userMessage
        # Write the messages to the verbose output
        Write-Verbose "Messages: $($messages | out-string)"

        # Get the URL for the chat
        $urlChat = Get-PSAOAIUrl -Endpoint $Endpoint -Deployment $Deployment -APIVersion $APIVersion -Mode chat

        # Write the URL to the verbose output
        Write-Verbose "urtChat: $urlChat"

        # Write the system prompt to the log file
        Write-LogMessage -Message "System promp:`n$system_message" -LogFile $logfile
        # Write the user message to the log file
        Write-LogMessage -Message "User message:`n$userMessage" -LogFile $logfile

        do {
            # Get the body of the message
            $body = Get-PSAOAIChatBody -messages $messages -temperature $parameters['Temperature'] -top_p $parameters['TopP'] -frequency_penalty $FrequencyPenalty -presence_penalty $PresencePenalty -user $User -n $N -stop $Stop -stream $Stream

            # Convert the body to JSON
            $bodyJSON = ($body | ConvertTo-Json)
            
            # If not a simple response, display chat completion and other details
            if (-not $simpleresponse) {
                Write-Host "[Chat completion]" -ForegroundColor Green
                if ($logfile) {
                    Write-Host "{Logfile:'${logfile}'} " -ForegroundColor Magenta
                }
                if ($SystemPromptFileName) {
                    Write-Host "{SysPFile:'$(Split-Path -Path $SystemPromptFileName -Leaf)', temp:'$($parameters['Temperature'])', top_p:'$($parameters['TopP'])', fp:'${FrequencyPenalty}', pp:'${PresencePenalty}', user:'${User}', n:'${N}', stop:'${Stop}', stream:'${Stream}'} " -NoNewline -ForegroundColor Magenta
                }
                else {
                    Write-Host "{SysPrompt, temp:'$($parameters['Temperature'])', top_p:'$($parameters['TopP'])', fp:'${FrequencyPenalty}', pp:'${PresencePenalty}', user:'${User}', n:'${N}', stop:'${Stop}', stream:'${Stream}'} " -NoNewline -ForegroundColor Magenta
                }
            }
            
            # Invoke the API request
            $response = Invoke-ApiRequest -url $urlChat -headers $headers -bodyJSON $bodyJSON
            
            # If the response is null, break the loop
            if ($null -eq $response) {
                Write-Verbose "Response is empty"
                break
            }

            # Write the received job to verbose output
            Write-Verbose ("Receive job:`n$($response | ConvertTo-Json)" | Out-String)

            # Get the assistant response
            $assistant_response = $response.choices[0].message.content

            # Add the assistant response to the messages
            $messages += @{"role" = "assistant"; "content" = $assistant_response }

            # If there is a one-time user prompt, process it
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

                # Get the response text
                $responseText = (Show-ResponseMessage -content $assistant_response -stream "assistant" -simpleresponse:$simpleresponse | Out-String)

                # Write the one-time user prompt and response text to the log file
                Write-LogMessage -Message "OneTimeUserPrompt:`n$OneTimeUserPrompt" -LogFile $logfile
                Write-LogMessage -Message "ResponseText:`n$responseText" -LogFile $logfile

                # Return the response text
                return $responseText
            }
            else {
                Write-Verbose "NO OneTimeUserPrompt"

                # Show the response message
                Show-ResponseMessage -content $assistant_response -stream "assistant" -simpleresponse:$simpleresponse
            
                # Write the assistant response to the log file
                Write-LogMessage -Message "Assistant response:`n$assistant_response" -LogFile $logfile

                # Get the user message
                $user_message = Read-Host "Enter chat message (user)" 
                # Add the user message to the messages
                $messages += @{"role" = "user"; "content" = $user_message }

                # Write the user response to the log file
                Write-LogMessage -Message "User response:`n$user_message" -LogFile $logfile
            }
            
        } while ($true)
    }
    catch {
        Format-Error -ErrorVar $_
        Show-Error -ErrorVar $_
    }

}

<#
# Define constants for environment variable names
$API_AZURE_OPENAI_APIVERSION = "API_AZURE_OPENAI_APIVERSION"
$API_AZURE_OPENAI_ENDPOINT = "API_AZURE_OPENAI_ENDPOINT"
$API_AZURE_OPENAI_DEPLOYMENT = "API_AZURE_OPENAI_DEPLOYMENT"
$API_AZURE_OPENAI_KEY = "API_AZURE_OPENAI_KEY"

# Get the API version from the environment variable
$APIVersion = Set-EnvironmentVariable -VariableName $API_AZURE_OPENAI_APIVERSION -PromptMessage "Please enter the API version"
# Get the endpoint from the environment variable
$Endpoint = Set-EnvironmentVariable -VariableName $API_AZURE_OPENAI_ENDPOINT -PromptMessage "Please enter the endpoint"
# Get the deployment from the environment variable
$Deployment = Set-EnvironmentVariable -VariableName $API_AZURE_OPENAI_DEPLOYMENT -PromptMessage "Please enter the deployment"
# Get the API key from the environment variable
$ApiKey = Set-EnvironmentVariable -VariableName $API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API key"
#>