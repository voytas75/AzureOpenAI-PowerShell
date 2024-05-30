Add-Type -AssemblyName System.Net.Http
#using namespace System.Net.Http


<#
nie moge otrzymac streamingu 
koles pisze, ze tez nie moze: https://github.com/PowerShell/PowerShell/issues/23783

analiza problemu: https://chatgpt.com/share/6e0d8df3-7418-426f-8ed0-5130b7d7e2af

moze byc powiazane: https://stackoverflow.com/questions/60707843/806889
#>




# This function makes an API request and stores the response
function Invoke-PSAOAIApiRequestStream2 {
    <#
.SYNOPSIS
    Invokes the Azure OpenAI API using a stream request.

.DESCRIPTION
    This function allows you to invoke the Azure OpenAI API using a stream request. It accepts various parameters such as `Url`, `Headers`, `BodyJSON`, and an optional `Timeout`.
    The function provides the capability for streaming the API response.

.PARAMETER Url
    The URL of the Azure OpenAI API endpoint.

.PARAMETER Headers
    A hashtable containing any custom headers to include in the API request, including the required API key.

.PARAMETER BodyJSON
    The JSON-formatted request body to send to the API.

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
        $timeout = 60 # The timeout for the API request
    )

    # Try to send the API request and handle any errors
    try {

        # Define the API endpoint
        $apiEndpoint = $url
        
        # Create an instance of HttpClient
        $httpClient = [System.Net.Http.HttpClient]::new()

        # Set the required headers
        $httpClient.DefaultRequestHeaders.Add("api-key", $($headers."api-key"))

        # Set the timeout for the HttpClient
        $httpClient.Timeout = New-TimeSpan -Seconds $timeout

        # Create the HttpContent object with the request body
        $content = [System.Net.Http.StringContent]::new($bodyJSON, [System.Text.Encoding]::UTF8, "application/json")

        # Send the HTTP POST request asynchronously
        $response = $httpClient.PostAsync($apiEndpoint, $content).Result
        #$response = $httpClient.GetAsync($apiEndpoint).Result

        # Get the response stream
        $stream = $response.Content.ReadAsStreamAsync().Result

        # Create a StreamReader to read the response stream
        $reader = [System.IO.StreamReader]::new($stream)

        # Initialize the completeText variable
        $completeText = ""

        # Read and output each line from the response stream

        while ($null -ne ($line = $reader.ReadLine())) {
		
            # Check if the line starts with "data: " and is not "data: [DONE]"
            if ($line.StartsWith("data: ") -and $line -ne "data: [DONE]") {
                # Extract the JSON part from the line
                $jsonPart = $line.Substring(6)

                # Parse the JSON part
                $parsedJson = $jsonPart | ConvertFrom-Json

                if (-not $Chat) {

                    # Extract the text and append it to the complete text - Text Completion
                    $completeText += $parsedJson.choices[0].text
                    write-host $parsedJson.choices[0].text -nonewline
                }
                else {
                    # Extract the text and append it to the complete text - Chat Completion
                    $delta = $parsedJson.choices[0].delta.content
                    $completeText += $delta
                    write-host $delta -nonewline
                }
            }
        }

        Write-Host ""
        $completeText += "`n"

        # Clean up
        $reader.Close()
        $httpClient.Dispose()
				
        # Return the API response object
        return $completeText
    }
    # Catch any errors and write a warning
    catch {
        Write-Error "Error: $($_.Exception.Message)"
        if ($null -ne $_.Exception.Response) {
            Write-Error "HTTP Status Code: $($_.Exception.Response.StatusCode)"
            Write-Error "HTTP Reason Phrase: $($_.Exception.Response.ReasonPhrase)"
        }
    }
}
