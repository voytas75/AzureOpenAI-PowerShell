function Invoke-LLMChatCompletion {
    param (
        [string]$Provider,
        [string]$SystemPrompt,
        [string]$UserPrompt,
        [double]$Temperature,
        [double]$TopP,
        [int]$MaxTokens,
        [bool]$Stream,
        [string]$LogFolder,
        [string]$DeploymentChat,
        [string]$ollamaModel
    )

    try {
        # Check if verbose prompts are enabled and display them
        if ($GlobalState.VerbosePrompt) {
            Write-Host "System Prompt: $SystemPrompt" -ForegroundColor DarkMagenta
            Write-Host "User Prompt: $UserPrompt" -ForegroundColor DarkMagenta
        }

        # Switch between different LLM providers based on the provider parameter
        switch ($Provider) {
            "ollama" {
                # Verbose message for invoking Ollama model
                Write-Verbose "Invoking Ollama model completion function."
                # Invoke the Ollama model completion function
                $response = Invoke-AIPSTeamOllamaCompletion -SystemPrompt $SystemPrompt -UserPrompt $UserPrompt -Temperature $Temperature -TopP $TopP -ollamaModel $ollamamodel -Stream $Stream
                return $response
            }
            "LMStudio" {
                # Verbose message for invoking LMStudio model
                Write-Verbose "Invoking LMStudio chat completion function."
                # Handle streaming for LMStudio provider
                # Invoke the LMStudio chat completion function
                $response = Invoke-AIPSTeamLMStudioChatCompletion -SystemPrompt $SystemPrompt -UserPrompt $UserPrompt -Temperature $Temperature -TopP $TopP -Stream $Stream -ApiKey $script:lmstudioApiKey -endpoint $script:lmstudioApiBase -Model $script:LMStudioModel
                return $response
            }
            "OpenAI" {
                # Verbose message for unsupported LLM provider
                Write-Verbose "Unsupported LLM provider: $Provider."
                # Throw an exception for unsupported LLM provider
                throw "-- Unsupported LLM provider: $Provider. This provider is not implemented yet."
            }
            "AzureOpenAI" {
                # Verbose message for invoking Azure OpenAI model
                Write-Verbose "Invoking Azure OpenAI chat completion function."
                # Invoke the Azure OpenAI chat completion function
                $response = Invoke-AIPSTeamAzureOpenAIChatCompletion -SystemPrompt $SystemPrompt -UserPrompt $UserPrompt -Temperature $Temperature -TopP $TopP -Stream $Stream -LogFolder $LogFolder -Deployment $DeploymentChat -MaxTokens $MaxTokens
                return $response
            }
            default {
                # Verbose message for unknown LLM provider
                Write-Verbose "Unknown LLM provider: $Provider."
                # Throw an exception for unknown LLM provider
                throw "!! Unknown LLM provider: $Provider"
            }
        }
    }
    catch {
        # Log the error and rethrow it with additional context
        $functionName = $MyInvocation.MyCommand.Name
        $errorMessage = "Error in ${functionName}: $_"
        Write-Error $errorMessage
        Update-ErrorHandling -ErrorRecord $_ -ErrorContext "$functionName function" -LogFilePath (Join-Path $LogFolder "ERROR.txt")
        throw $_
    }
}

function Invoke-AIPSTeamAzureOpenAIChatCompletion {
    param (
        [string]$SystemPrompt,
        [string]$UserPrompt,
        [double]$Temperature,
        [double]$TopP,
        [int]$MaxTokens,
        [bool]$Stream,
        [string]$LogFolder,
        [string]$Deployment
    )

    try {
        # Log the input parameters for debugging purposes
        Write-Verbose "SystemPrompt: $SystemPrompt"
        Write-Verbose "UserPrompt: $UserPrompt"
        Write-Verbose "Temperature: $Temperature"
        Write-Verbose "TopP: $TopP"
        Write-Verbose "MaxTokens: $MaxTokens"
        Write-Verbose "Stream: $Stream"
        Write-Verbose "LogFolder: $LogFolder"
        Write-Verbose "Deployment: $Deployment"

        # Notify the start of the Azure OpenAI process
        Write-Host "++ Initiating Azure OpenAI process for deployment: $Deployment..."
        
        if ($Stream) {
            Write-Host "++ Streaming mode enabled." -ForegroundColor Blue
        }

        # Invoke the Azure OpenAI chat completion function
        $response = PSAOAI\Invoke-PSAOAIChatCompletion -SystemPrompt $SystemPrompt -usermessage $UserPrompt -Temperature $Temperature -TopP $TopP -LogFolder $LogFolder -Deployment $Deployment -User "AIPSTeam" -Stream $Stream -simpleresponse -OneTimeUserPrompt

        if ($Stream) {
            Write-Host "++ Streaming completed." -ForegroundColor Blue
        }
        
        Write-Host "++ Azure OpenAI process initiated successfully for deployment: $Deployment."

        # Check if the response is null or empty
        if ([string]::IsNullOrEmpty($response)) {
            $errorMessage = "The response from Azure OpenAI API is null or empty."
            Write-Error $errorMessage
            throw $errorMessage
        }

        # Log the successful response
        Write-Verbose "Azure OpenAI API response received successfully."

        return $response
    }
    catch {
        # Log the error and rethrow it with additional context
        $functionName = $MyInvocation.MyCommand.Name
        $errorMessage = "Error in ${functionName}: $_"
        Write-Error $errorMessage
        Update-ErrorHandling -ErrorRecord $_ -ErrorContext "$functionName function" -LogFilePath (Join-Path $LogFolder "ERROR.txt")
        throw $_
    }
}

function Invoke-AIPSTeamOllamaCompletion {
    param (
        [string]$SystemPrompt,
        [string]$UserPrompt,
        [double]$Temperature,
        [double]$TopP,
        [string]$ollamaModel,
        [bool]$Stream
    )

    # Define options for the Ollama API call
    $ollamaOptions = [pscustomobject]@{
        temperature = $Temperature
        top_p       = $TopP
    }

    # Construct the JSON payload for the Ollama API request
    $ollamaJson = [pscustomobject]@{
        model   = $ollamaModel
        prompt  = $SystemPrompt + "`n" + $UserPrompt
        options = $ollamaOptions
        stream  = $Stream
    } | ConvertTo-Json

    # Ensure the Ollama endpoint ends with a '/'
    if (-not $script:ollamaEndpoint.EndsWith('/')) {
        $script:ollamaEndpoint += '/'
    }
    Write-Verbose "Constructed JSON payload for Ollama API: $ollamaJson"

    # Define the URL for the Ollama API endpoint
    $url = "$($script:ollamaEndpoint)api/generate"
    Write-Verbose "Ollama API endpoint URL: $url"

    # Notify the user that the Ollama model is processing
    Write-Host "++ Ollama model ($ollamaModel) is processing your request..."

    # Check if streaming is enabled and handle accordingly
    if ($Stream) {
        # Initialize HttpClientHandler with specific configurations for streaming
        $httpClientHandler = [System.Net.Http.HttpClientHandler]::new()
        $httpClientHandler.AllowAutoRedirect = $false
        $httpClientHandler.UseCookies = $false
        $httpClientHandler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
        
        # Create HttpClient using the handler
        $httpClient = [System.Net.Http.HttpClient]::new($httpClientHandler)
        
        # Prepare the content of the HTTP request
        $content = [System.Net.Http.StringContent]::new($ollamaJson, [System.Text.Encoding]::UTF8, "application/json")
     
        # Create and configure the HTTP request message
        $request = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Post, $url)
        $request.Content = $content
     
        # Send the HTTP request and read the headers of the response
        $response = $httpClient.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
    
        # Stream the response using StreamReader
        $reader = [System.IO.StreamReader]::new($response.Content.ReadAsStreamAsync().Result)
    
        # Initialize variable to accumulate the response text
        $completeText = ""
        Write-Host "++ Streaming" -ForegroundColor Blue

        # Read and process each line of the response stream
        while ($null -ne ($line = $reader.ReadLine()) -or (-not $reader.EndOfStream)) {
            try {
                $line = ($line | ConvertFrom-Json)
            }
            catch {
                Write-Error "Error parsing JSON: $_"
            }            
            if (-not $line.done) {
                $delta = $line.response
                $completeText += $delta
                Write-Host $delta -NoNewline -ForegroundColor White
            }
        }
        Write-Host ""
        $completeText += "`n"
    
        # Output the complete streamed text
        if ($VerbosePreference -eq "Continue") {
            Write-Host "++ Streaming completed. Full text: $completeText" -ForegroundColor DarkBlue
        }
        else {
            Write-Host "++ Streaming completed." -ForegroundColor Blue
        }

        # Clean up resources
        $reader.Close()
        $httpClient.Dispose()

        $response = $completeText
    }
    else {
        # Send a non-streaming HTTP POST request and parse the response
        $response = Invoke-WebRequest -Method POST -Body $ollamaJson -Uri $url -UseBasicParsing
        $response = $response.Content | ConvertFrom-Json | Select-Object -ExpandProperty response
    }

    # Log the interaction details
    $logEntry = @{
        Timestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        SystemPrompt = $SystemPrompt
        UserPrompt   = $UserPrompt
        Response     = $response
    } | ConvertTo-Json

    [void]($this.Log.Add($logEntry))
    $this.AddLogEntry("SystemPrompt:`n$SystemPrompt")
    $this.AddLogEntry("UserPrompt:`n$UserPrompt")
    $this.AddLogEntry("Response:`n$response")
    
    Write-Host "++ Ollama model ($ollamaModel) has successfully processed your request."

    return $response.Trim('"')
}

function Invoke-AIPSTeamLMStudioChatCompletion {
    param (
        [string]$SystemPrompt,
        [string]$UserPrompt,
        [double]$Temperature,
        [double]$TopP,
        [string]$Model,
        [string]$ApiKey,
        [string]$endpoint,
        [int]$timeoutSec = 240,
        [bool]$Stream
    )
    $response = ""

    # Define headers for the HTTP request
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $ApiKey"
    }

    # Construct the JSON body for the request
    $bodyJSON = [ordered]@{
        'model'       = $Model
        'messages'    = @(
            [ordered]@{
                'role'    = 'system'
                'content' = $SystemPrompt
            },
            [ordered]@{
                'role'    = 'user'
                'content' = $UserPrompt
            }
        )
        'temperature' = $Temperature
        'top_p'       = $TopP
        'stream'      = $Stream
        'max_tokens'  = $GlobalState.maxtokens
    } | ConvertTo-Json

    Write-Verbose "Request Body JSON: $bodyJSON"

    # Inform the user that the request is being processed
    $InfoText = "++ LM Studio" + $(if ($Model) { " model ($Model)" } else { "" }) + " is processing your request..."
    Write-Host $InfoText

    $url = "$($endpoint)chat/completions"

    # Check if streaming is enabled and handle accordingly
    if ($Stream) {
        # Create an instance of HttpClientHandler and disable buffering
        $httpClientHandler = [System.Net.Http.HttpClientHandler]::new()
        $httpClientHandler.AllowAutoRedirect = $false
        $httpClientHandler.UseCookies = $false
        $httpClientHandler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
        
        # Create an instance of HttpClient
        $httpClient = [System.Net.Http.HttpClient]::new($httpClientHandler)
            
        # Set the required headers
        $httpClient.DefaultRequestHeaders.Add("api-key", $ApiKey)
            
        # Set the timeout for the HttpClient
        $httpClient.Timeout = New-TimeSpan -Seconds $timeoutSec
        
        # Create the HttpContent object with the request body
        $content = [System.Net.Http.StringContent]::new($bodyJSON, [System.Text.Encoding]::UTF8, "application/json")
     
        $request = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Post, $url)
        $request.Content = $content
     
        # Send the HTTP POST request asynchronously with HttpCompletionOption.ResponseHeadersRead
        $response = $httpClient.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
    
        # Ensure the request was successful
        if (-not $response.IsSuccessStatusCode) {
            Write-Host "-- Response was not successful: $($response.StatusCode) - $($response.ReasonPhrase)"
            return
        }
    
        # Get the response stream
        $stream_ = $response.Content.ReadAsStreamAsync().Result
        $reader = [System.IO.StreamReader]::new($stream_)
    
        Write-Host "++ Streaming." -ForegroundColor Blue

        # Initialize the completeText variable
        $completeText = ""
        while ($null -ne ($line = $reader.ReadLine()) -or (-not $reader.EndOfStream)) {
            # Check if the line starts with "data: " and is not "data: [DONE]"
            if ($line.StartsWith("data: ") -and $line -ne "data: [DONE]") {
                # Extract the JSON part from the line
                $jsonPart = $line.Substring(6)    
                if ($completeText.EndsWith('+')) {
                    $completeText = $completeText.Substring(0, $completeText.Length - 1)
                }
                try {
                    # Parse the JSON part
                    $parsedJson = $jsonPart | ConvertFrom-Json
                    # Extract the text and append it to the complete text - Chat Completion
                    $delta = $parsedJson.choices[0].delta.content
                    $completeText += $delta
                    Write-Host $delta -NoNewline -ForegroundColor White
                }
                catch {
                    Write-Error "Error parsing JSON: $_"
                }
            }
        }
        Write-Host ""
        $completeText += "`n"
    
        if ($VerbosePreference -eq "Continue") {
            Write-Verbose "Streaming completed. Full text: $completeText"
        }
        else {
            Write-Host "++ Streaming completed." -ForegroundColor Blue
        }
        # Clean up
        $reader.Close()
        $httpClient.Dispose()

        $response = $completeText
    }
    else {
        # Send a non-streaming HTTP POST request and parse the response
        $response = Invoke-RestMethod -Uri "$($endpoint)chat/completions" -Headers $headers -Method POST -Body $bodyJSON -TimeoutSec $timeoutSec
        $response = $($response.Choices[0].message.content).trim()
    }

    # Log the prompt and response to the log file
    $logEntry = @{
        Timestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        SystemPrompt = $SystemPrompt
        UserPrompt   = $UserPrompt
        Response     = $response
    } | ConvertTo-Json
    
    [void]($this.Log.Add($logEntry))
    # Log the summary
    [void]($this.AddLogEntry("SystemPrompt:`n$SystemPrompt"))
    [void]($this.AddLogEntry("UserPrompt:`n$UserPrompt"))
    [void]($this.AddLogEntry("Response:`n$Response"))
    
    $InfoText = "++ LM Studio" + $(if ($Model) { " model ($Model)" } else { "" }) + " has successfully processed your request."
    Write-Host $InfoText

    return $response
}

import-module PSAOAI