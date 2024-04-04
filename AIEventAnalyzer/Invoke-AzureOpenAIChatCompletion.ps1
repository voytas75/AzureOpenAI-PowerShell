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

    <#
    .SYNOPSIS
    This function generates the URL for the Azure OpenAI API request.

    .DESCRIPTION
    The Get-Url function constructs the URL for the Azure OpenAI API request. It uses the provided endpoint, deployment, and API version to create the URL.

    .PARAMETER Endpoint
    Specifies the endpoint URL for the Azure OpenAI API. This parameter is mandatory.

    .PARAMETER Deployment
    Specifies the name of the OpenAI deployment to be used. This parameter is mandatory.

    .PARAMETER APIVersion
    Specifies the version of the Azure OpenAI API to be used. This parameter is mandatory.

    .EXAMPLE
    Get-Url -Endpoint "https://api.openai.com" -Deployment "myDeployment" -APIVersion "v1"

    .OUTPUTS
    Outputs a string representing the URL for the Azure OpenAI API request.
    #>
    function Get-Url {
        # Define parameters for the function
        param (
            [Parameter(Mandatory = $true)]
            [string]$Endpoint, # The endpoint URL for the Azure OpenAI API

            [Parameter(Mandatory = $true)]
            [string]$Deployment, # The name of the OpenAI deployment to be used

            [Parameter(Mandatory = $true)]
            [string]$APIVersion # The version of the Azure OpenAI API to be used
        )

        # Construct and return the URL for the API request
        return "${Endpoint}/openai/deployments/${Deployment}/chat/completions?api-version=${APIVersion}"
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
    
    # Function to display the reason for ending the conversation
    function Show-FinishReason {
        <#
        .SYNOPSIS
        Displays the reason for ending the conversation.
        
        .DESCRIPTION
        The Show-FinishReason function is used to print the reason for ending the conversation to the console. This is typically used in chatbot interactions to indicate why the conversation was terminated.
        
        .PARAMETER finishReason
        The reason for ending the conversation. This parameter is mandatory and should be a string.
        
        .EXAMPLE
        Show-FinishReason -finishReason "End of conversation"
        This example shows how to use the Show-FinishReason function to display "End of conversation" as the reason for ending the conversation.
        
        .OUTPUTS
        None. This function does not return any output. It only prints the finish reason to the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [string]$finishReason # The reason for ending the conversation
        )
    
        # Print an empty line to the console for better readability
        Write-Output ""
        # Print the finish reason to the console
        Write-Output "(Finish reason: $finishReason)"
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

    
    # Function to handle and display errors
    function Show-Error {
        <#
        .SYNOPSIS
        Handles and displays errors.
        
        .DESCRIPTION
        This function handles any errors that occur during the execution of the script. It prints the error details to the console for debugging purposes.
        
        .PARAMETER ErrorVar
        The error variable that contains the error details. This parameter is mandatory.
        
        .EXAMPLE
        Show-Error -ErrorVar $errorVar
        
        .OUTPUTS
        None. This function handles the errors and prints the error details to the console.
        #> 
        param(
            [Parameter(Mandatory = $true)]
            [string]$ErrorVar # The error variable containing the error details
        )
    
        # Print the error details (file, line, character, and message) to the console if any error occurs during the process
        Write-Host "[e] Error in file: $($ErrorVar.InvocationInfo.ScriptName)" -ForegroundColor DarkRed
        Write-Host "[e] Error in line: $($ErrorVar.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkRed
        Write-Host "[e] Error at char: $($ErrorVar.InvocationInfo.OffsetInLine)" -ForegroundColor DarkRed
        Write-Host "[e] An error occurred:" -NoNewline
        Write-Host " $($ErrorVar.Exception.Message)" -ForegroundColor DarkRed
        
        # Handle specific types of exceptions for more detailed error messages
        if ($ErrorVar.Exception -is [System.Net.WebException]) {
            # Handle WebException and print the status code
            Write-Host "[e] WebException: $($ErrorVar.Exception.Response.StatusCode)" -ForegroundColor DarkRed
        }
        elseif ($ErrorVar.Exception -is [System.IO.IOException]) {
            # Handle IOException and print the IO error
            Write-Host "[e] IOException: $($ErrorVar.Exception.IOError)" -ForegroundColor DarkRed
        }
        elseif ($ErrorVar.Exception -is [System.ArgumentException]) {
            # Handle ArgumentException and print the parameter name that caused the exception
            Write-Host "[e] ArgumentException: $($ErrorVar.Exception.ParamName)" -ForegroundColor DarkRed
        }
        else {
            # Handle unknown error types and print the full type name
            Write-Host "[e] Unknown error type: $($ErrorVar.Exception.GetType().FullName)" -ForegroundColor DarkRed
        }
        Write-Host "" # Print an empty line for better readability
    }
        
    # Function to verify the existence of a user environment variable
    function Test-UserEnvironmentVariable {
        <#
        .SYNOPSIS
        Verifies the existence of a user environment variable.
        
        .DESCRIPTION
        This function checks if a specific user environment variable is set in the system. It returns a boolean value indicating the existence of the variable.
        
        .PARAMETER VariableName
        The name of the environment variable to verify. This parameter is mandatory.
        
        .EXAMPLE
        Test-UserEnvironmentVariable -VariableName "API_AZURE_OPENAI"
        
        .OUTPUTS
        Boolean. Returns $true if the environment variable exists, $false otherwise.
        #> 
        param (
            [Parameter(Mandatory = $true)]
            [string]$VariableName # The name of the environment variable to verify
        )
    
        # Get the list of environment variables
        $envVariables = Get-ChildItem -Path "Env:$VariableName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
        # Get the specific environment variable from the user environment
        $envVariable = [Environment]::GetEnvironmentVariable($VariableName, "User")
        
        # Check if the environment variable exists
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
            Outputs the usage statistics of the API call.
            
            .DESCRIPTION
            This function takes in a usage object and prints the usage statistics to the console in a verbose manner. 
            The usage object typically contains information about the total tokens in the API call and the total tokens used.
            
            .PARAMETER usage
            The usage object to be displayed. This parameter is mandatory.
            
            .EXAMPLE
            Show-Usage -usage $response.usage
            
            .OUTPUTS
            String. This function outputs the usage statistics to the console and returns a string representation of the usage.
            #> 
        param(
            [Parameter(Mandatory = $true)]
            [System.Object]$usage # The usage object to display
        )

        # Convert the usage object to a string and write it to the console in a verbose manner
        Write-Verbose ($usage | Out-String)
        Write-Verbose (($usage | gm) | Out-String)

        # Return a string representation of the usage
        $usageData = $usage
        return "Usage:`n$usageData"
    }
    
    <#
    .SYNOPSIS
    This function sets the parameters for the switches.

    .DESCRIPTION
    This function takes in two boolean parameters, Creative and Precise, and sets the Temperature and TopP values accordingly.

    .PARAMETER Creative
    A boolean value that, when true, sets the Temperature to 0.7 and TopP to 0.95.

    .PARAMETER Precise
    A boolean value that, when true, sets the Temperature to 0.3 and TopP to 0.8.

    .EXAMPLE
    Set-ParametersForSwitches3 -Creative $true -Precise $false
    #>
    function Set-ParametersForSwitches3 {
        param(
            [bool]$Creative,
            [bool]$Precise
        )
        # If Creative is true, set Temperature to 0.7 and TopP to 0.95
        if ($Creative) {
            $script:Temperature = 0.7
            $script:TopP = 0.95
        }
        # If Precise is true, set Temperature to 0.3 and TopP to 0.8
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
        This function adjusts the 'Temperature' and 'TopP' parameters based on the provided switches.

        .DESCRIPTION
        This function sets the 'Temperature' and 'TopP' parameters to predefined values based on the state of the 'Creative' or 'Precise' switch. 
        If 'Creative' is enabled, 'Temperature' is set to 0.7 and 'TopP' to 0.95. 
        If 'Precise' is enabled, 'Temperature' is set to 0.3 and 'TopP' to 0.8.

        .PARAMETER Creative
        A switch parameter. When enabled, it sets the parameters for a more creative output.

        .PARAMETER Precise
        A switch parameter. When enabled, it sets the parameters for a more precise output.

        .OUTPUTS
        Outputs a Hashtable of the adjusted parameters.
        #>
        param(
            [switch]$Creative,
            [switch]$Precise
        )
        
        # Initialize parameters with default values
        $parameters = @{
            'Temperature' = 1.0
            'TopP'        = 1.0
        }
    
        # If Creative switch is enabled, adjust parameters for creative output
        if ($Creative) {
            $parameters['Temperature'] = 0.7
            $parameters['TopP'] = 0.95
        }
        # If Precise switch is enabled, adjust parameters for precise output
        elseif ($Precise) {
            $parameters['Temperature'] = 0.3
            $parameters['TopP'] = 0.8
        }
    
        # Return the adjusted parameters
        return $parameters
    }

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
    function Write-LogMessage {
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
   
    <#
    .SYNOPSIS
    This function formats and outputs the provided error record.

    .DESCRIPTION
    The Format-Error function takes in an ErrorRecord object and outputs it. 
    This can be used for better error handling and logging in scripts.

    .PARAMETER ErrorVar
    The ErrorRecord object to be formatted and outputted. This parameter is mandatory.

    .EXAMPLE
    Format-Error -ErrorVar $Error
    #>
    function Format-Error {
        param(
            [Parameter(Mandatory = $true)]
            [System.Management.Automation.ErrorRecord]$ErrorVar
        )

        # Output the ErrorRecord object
        Write-Output $ErrorVar
    }

    <#
    .SYNOPSIS
    This function formats the provided message by removing non-ASCII characters.

    .DESCRIPTION
    The Format-Message function takes in a string message and returns a version of the message with all non-ASCII characters removed. 
    This can be used to ensure that the message can be properly displayed in environments that only support ASCII characters.

    .PARAMETER Message
    The string message to be formatted. This parameter is mandatory.

    .EXAMPLE
    $userMessage = Format-Message -Message $OneTimeUserPrompt
    #>
    function Format-Message {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message
        )

        # Remove non-ASCII characters from the message
        return [System.Text.RegularExpressions.Regex]::Replace($Message, "[^\x00-\x7F]", "")
    }


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
    
    try {
        # Check if usermessage is not set and usermessagelogfile is set
        if (-not $usermessage -and $usermessagelogfile) {
            # If so, read the content of usermessagelogfile and assign it to usermessage
            $usermessage = (get-content $usermessagelogfile | out-string)
        }

        # Check if logfile is not set
        if (-not $logfile) {
            # Check if usermessagelogfile is not set, but usermessage and SystemPromptFileName are set
            if (-not $usermessagelogfile -and $usermessage -and $SystemPromptFileName) {
                $logfileBaseName = "usermessage-" + [System.IO.Path]::GetFileNameWithoutExtension($SystemPromptFileName) + "-"
                $logfileExtension = ".txt"
                $logfileDirectory = [Environment]::GetFolderPath("MyDocuments")
            }
            # Check if OneTimeUserPrompt and SystemPromptFileName are set
            elseif ($OneTimeUserPrompt -and $SystemPromptFileName) {
                $logfileBaseName = "usermessage_OneTimeUserPrompt-" + [System.IO.Path]::GetFileNameWithoutExtension($SystemPromptFileName) + "-"
                $logfileExtension = ".txt"
                $logfileDirectory = [Environment]::GetFolderPath("MyDocuments")
            }
            # Check if SystemPrompt is set
            elseif ($SystemPrompt) {
                $logfileBaseName = "SystemPrompt"
                $logfileExtension = ".txt"
                $logfileDirectory = [Environment]::GetFolderPath("MyDocuments")
                # Action when this condition is true
            }
            # If none of the above conditions are met
            else {
                $logfileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($usermessagelogfile)
                $logfileExtension = [System.IO.Path]::GetExtension($usermessagelogfile)
                $logfileDirectory = [System.IO.Path]::GetDirectoryName($usermessagelogfile)
                $logfileBaseName += "-" + [System.IO.Path]::GetFileNameWithoutExtension($SystemPromptFileName) + "-"
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
        $headers = Get-Headers -ApiKeyVariable "API_AZURE_OPENAI_KEY"

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
        
        # Get the messages from the system and user
        $messages = Get-Messages -system_message $system_message -UserMessage $userMessage
        # Write the messages to the verbose output
        Write-Verbose "Messages: $($messages | out-string)"

        # Get the URL for the chat
        $urlChat = Get-Url -Endpoint $Endpoint -Deployment $Deployment -APIVersion $APIVersion
        # Write the URL to the verbose output
        Write-Verbose "urtChat: $urlChat"

        # Write the system prompt to the log file
        Write-LogMessage -Message "System promp:`n$system_message" -LogFile $logfile
        # Write the user message to the log file
        Write-LogMessage -Message "User message:`n$userMessage" -LogFile $logfile

        do {
            # Get the body of the message
            $body = Get-Body -messages $messages -temperature $parameters['Temperature'] -top_p $parameters['TopP'] -frequency_penalty $FrequencyPenalty -presence_penalty $PresencePenalty -user $User -n $N -stop $Stop -stream $Stream

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
    }

}

<#
    .SYNOPSIS
    This function retrieves the value of a specified environment variable. If the variable does not exist, it prompts the user to provide a value and sets the variable.

    .DESCRIPTION
    The Get-EnvironmentVariable function retrieves the value of the environment variable specified by the VariableName parameter. If the variable does not exist or its value is null or empty, the function prompts the user to provide a value using the message specified by the PromptMessage parameter. The function then attempts to set the environment variable to the provided value.

    .PARAMETER VariableName
    The name of the environment variable to retrieve. This parameter is mandatory.

    .PARAMETER PromptMessage
    The message to display when prompting the user to provide a value for the environment variable. This parameter is mandatory.

    .EXAMPLE
    $APIVersion = Get-EnvironmentVariable -VariableName "API_AZURE_OPENAI_APIVERSION" -PromptMessage "Please enter the API version"
    #>
function Get-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VariableName,
        [Parameter(Mandatory = $true)]
        [string]$PromptMessage
    )

    # Retrieve the value of the environment variable
    $VariableValue = [System.Environment]::GetEnvironmentVariable($VariableName, "User")

    # If the variable does not exist or its value is null or empty, prompt the user to provide a value
    if ([string]::IsNullOrEmpty($VariableValue)) {
        $VariableValue = Read-Host -Prompt $PromptMessage

        # Attempt to set the environment variable to the provided value
        try {
            [System.Environment]::SetEnvironmentVariable($VariableName, $VariableValue, "User")

            # If the variable was set successfully, display a success message
            if ([System.Environment]::GetEnvironmentVariable($VariableName, "User") -eq $VariableValue) {
                Write-Host "Environment variable $VariableName was set successfully."
            }
        }
        # If setting the variable failed, display an error message
        catch {
            Write-Host "Failed to set environment variable $VariableName."
        }
    }

    # Return the value of the environment variable
    return $VariableValue
}
    
<#
    .SYNOPSIS
    This function clears the Azure OpenAI API environment variables.

    .DESCRIPTION
    The Clear-AzureOpenAIAPIEnv function clears the values of the Azure OpenAI API environment variables. If an error occurs during the process, it provides an error message to the user.

    .EXAMPLE
    Clear-AzureOpenAIAPIEnv
    #>
function Clear-AzureOpenAIAPIEnv {
    param()
    try {
        # Clear the environment variables related to Azure OpenAI API
        [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_APIVERSION", "", "User")
        [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_DEPLOYMENT", "", "User")
        [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_KEY", "", "User")
        [System.Environment]::SetEnvironmentVariable("API_AZURE_OPENAI_Endpoint", "", "User")
            
        # Inform the user about the successful deletion of the environment variables
        Write-Host "Environment variables for Azure API have been deleted successfully."
    }
    catch {
        # Inform the user about any errors occurred during the deletion of the environment variables
        Write-Host "An error occurred while trying to delete Azure API environment variables. Please check your permissions and try again."
    }
}

<#
    .SYNOPSIS
    This function generates a hash of a given string using the specified hash algorithm.

    .DESCRIPTION
    The Get-Hash function takes an input string and a hash type as parameters. It generates a hash of the input string using the specified hash algorithm. The hash type can be one of the following: HMACMD5, HMACRIPEMD160, HMACSHA1, HMACSHA256, HMACSHA384, HMACSHA512, MACTripleDES, MD5, RIPEMD160, SHA1, SHA256, SHA384, SHA512.

    .PARAMETER InputString
    The string to be hashed.

    .PARAMETER HashType
    The type of hash algorithm to be used. It must be one of the hash types mentioned in the description.

    .EXAMPLE
    Get-Hash -InputString "Hello, World!" -HashType "SHA256"
    This example generates a SHA256 hash of the string "Hello, World!".

    "Hello, world!" | Get-Hash -HashType "HMACMD5"
    This example generates a HMACMD5 hash of the string "Hello, World!".

    .NOTES
    Author: Your Name
    Date:   Current Date
#>
function Get-Hash {
    [CmdletBinding()]
    param(
        # The string to be hashed
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString,

        # The type of hash algorithm to be used
        [Parameter(Mandatory = $true)]
        [ValidateSet("HMACMD5", "HMACRIPEMD160", "HMACSHA1", "HMACSHA256", "HMACSHA384", "HMACSHA512", "MACTripleDES", "MD5", "RIPEMD160", "SHA1", "SHA256", "SHA384", "SHA512")]
        [string]$HashType
    )

    # Create the hash provider based on the specified hash type
    $hashProvider = [System.Security.Cryptography.HashAlgorithm]::Create($HashType)

    # Compute the hash of the input string
    $hash = $hashProvider.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputString))

    # Convert the hash to a string and remove any hyphens
    $hashString = [System.BitConverter]::ToString($hash) -replace "-", ""

    # Return the hash string
    return $hashString
}



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
