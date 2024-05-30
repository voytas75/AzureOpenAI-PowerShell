Add-Type -AssemblyName System.Net.Http

<#
Problem with streaming response, similar: https://github.com/PowerShell/PowerShell/issues/23783
can be connected: https://stackoverflow.com/questions/60707843/806889

solved:
modify the code to use SendAsync with HttpCompletionOption.ResponseHeadersRead. This will return control to your code as soon as the headers are read, allowing you to start processing the response body as a stream immediately.
This modification will send the HTTP POST request with HttpCompletionOption.ResponseHeadersRead, which means that the SendAsync method will complete as soon as it has read the headers from the response. This allows you to start reading the response body as a stream immediately, which can give you a streaming-like behavior.
#>


# This function makes an API request and stores the response
function Invoke-PSAOAIApiRequestStream {
    <#
.SYNOPSIS
    Invokes the Azure OpenAI API using a stream request.

.DESCRIPTION
    This function sends a POST request to the Azure OpenAI API and processes the response as a stream. This is particularly useful for large responses that can be processed incrementally.

.PARAMETER Url
    The URL of the Azure OpenAI API endpoint.

.PARAMETER Headers
    A hashtable containing any custom headers to include in the API request, including the required API key.

.PARAMETER BodyJSON
    The JSON-formatted request body to send to the API.

.PARAMETER Chat
    A switch parameter to indicate if the request is for a chat completion.

.PARAMETER Logfile
    The path to the log file where the function will write log messages.

.PARAMETER Timeout
    The timeout in seconds for the API request. Default is 60 seconds.

.EXAMPLE
    $apiUrl = "https://api.openai.com/v1/endpoint"
    $requestBody = @{
        prompt = "Translate this English text to French."
    } | ConvertTo-Json
    $headers = @{
        "api-key" = "your_api_key_here"
    }
    $response = Invoke-PSAOAIApiRequestStream -Url $apiUrl -Headers $headers -BodyJSON $requestBody
    # Process the response stream (e.g., read and parse the data)

.NOTES
    Author: voytas
    Date: 2024-05-28
#>
    param(
        [Parameter(Mandatory = $true)]
        [string]$url, # The URL for the API request

        [Parameter(Mandatory = $true)]
        [hashtable]$headers, # The headers for the API request

        [Parameter(Mandatory = $true)]
        [string]$bodyJSON, # The body for the API request

        [Parameter(Mandatory = $false)]
        [switch]$Chat, 

        [Parameter(Mandatory = $false)]
        [string]$logfile,

        [Parameter(Mandatory = $false)]
        $timeout = 60 # The timeout for the API request
    )

    # Try to send the API request and handle any errors
    try {
        # Create an instance of HttpClientHandler and disable buffering
        $httpClientHandler = [System.Net.Http.HttpClientHandler]::new()
        $httpClientHandler.AllowAutoRedirect = $false
        $httpClientHandler.UseCookies = $false
        $httpClientHandler.AutomaticDecompression = [System.Net.DecompressionMethods]::GZip -bor [System.Net.DecompressionMethods]::Deflate
        
        # Create an instance of HttpClient
        $httpClient = [System.Net.Http.HttpClient]::new($httpClientHandler)
        #$httpClient = [System.Net.Http.HttpClient]::new()
        Write-LogMessage "HttpClient instance created with custom handler." -LogFile $logfile
            
        # Set the required headers
        $httpClient.DefaultRequestHeaders.Add("api-key", $($headers."api-key"))
        Write-LogMessage "API key header added." -LogFile $logfile
            
        # Set the timeout for the HttpClient
        $httpClient.Timeout = New-TimeSpan -Seconds $timeout
        
        # Create the HttpContent object with the request body
        $content = [System.Net.Http.StringContent]::new($bodyJSON, [System.Text.Encoding]::UTF8, "application/json")
        Write-LogMessage "HttpContent created with request body." -LogFile $logfile
     
        $request = New-Object System.Net.Http.HttpRequestMessage ([System.Net.Http.HttpMethod]::Post, $url)
        $request.Content = $content
     
        # Send the HTTP POST request asynchronously with HttpCompletionOption.ResponseHeadersRead
        $response = $httpClient.SendAsync($request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
     
        Write-LogMessage "HTTP POST request sent to ${url}." -LogFile $logfile
     
        #Write-LogMessage "HTTP POST request sent to ${url}." -LogFile $logfile
    
        # Ensure the request was successful
        if ($response.IsSuccessStatusCode) {
            Write-LogMessage "Received successful response from server." -LogFile $logfile
            # Inspect headers for Transfer-Encoding
            $transferEncoding = $response.Headers.TransferEncoding.ToString()
            #$transferEncoding | ConvertTo-Json | Write-LogMessage -LogFile $logfile
            if ($transferEncoding -contains "chunked") {
                Write-LogMessage "The API endpoint supports streaming (chunked transfer encoding)." -LogFile $logfile
            }
            else {
                Write-LogMessage "The API endpoint does not support streaming (no chunked transfer encoding)." -LogFile $logfile
            }
        }
        else {
            Write-LogMessage "Received error response: $($response.StatusCode) - $($response.ReasonPhrase)" "ERROR" -LogFile $logfile
            throw "Error in HTTP response: $($response.StatusCode) - $($response.ReasonPhrase)"
        }
    
        # Get the response stream
        $stream = $response.Content.ReadAsStreamAsync().Result
        $reader = [System.IO.StreamReader]::new($stream)
        Write-LogMessage "Response stream obtained and StreamReader initialized." -LogFile $logfile
    
        # Initialize the completeText variable
        $completeText = ""
        # Read and output each line from the response stream
        #while (-not $reader.EndOfStream) {
        #    Write-Information ($reader.ReadLine()) -InformationAction Continue
        #}
        while ($null -ne ($line = $reader.ReadLine()) -or (-not $reader.EndOfStream)) {
            # Log each received line
            #Write-LogMessage "Received line: $line" -LogFile $logfile
    
            # Check if the line starts with "data: " and is not "data: [DONE]"
            if ($line.StartsWith("data: ") -and $line -ne "data: [DONE]") {
                # Extract the JSON part from the line
                $jsonPart = $line.Substring(6)
    
                try {
                    # Parse the JSON part
                    $parsedJson = $jsonPart | ConvertFrom-Json
                    #Write-LogMessage "Parsed JSON: $jsonPart" -LogFile $logfile
    
                    if (-not $Chat) {
                        # Extract the text and append it to the complete text - Text Completion
                        $textChunk = $parsedJson.choices[0].text
                        $completeText += $textChunk
                        Write-Host $textChunk -NoNewline
                    }
                    else {
                        # Extract the text and append it to the complete text - Chat Completion
                        $delta = $parsedJson.choices[0].delta.content
                        $completeText += $delta
                        Write-Host $delta -NoNewline
                    }
                    # Update progress indicator
                    #Write-Progress -Activity "Streaming data..."

                }
                catch {
                    Write-LogMessage "Error parsing JSON: $_" "ERROR" -LogFile $logfile
                }
            }
        }
        Write-Host ""
        $completeText += "`n"
    
        if ($VerbosePreference -eq "Continue") {
            Write-Verbose "Streaming completed. Full text: $completeText"
            Write-LogMessage "Streaming completed. Full text: $completeText" "VERBOSE" -LogFile $logfile 
        }
        else {
            Write-LogMessage "Streaming completed." -LogFile $logfile
        }
        # Clean up
        $reader.Close()
        $httpClient.Dispose()
        Write-LogMessage "Resources cleaned up." -LogFile $logfile

        return $completeText
    }
    catch {
        Write-LogMessage "An error occurred: $_" "ERROR" -LogFile $logfile
    }
}

