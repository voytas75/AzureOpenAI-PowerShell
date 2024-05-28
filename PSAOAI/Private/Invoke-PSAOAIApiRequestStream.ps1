# This function makes an API request and stores the response
using namespace System.Net.Http
function Invoke-PSAOAIApiRequestStream {
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
        [string]$bodyJSON, # The body for the API request

        [Parameter(Mandatory = $false)]
        $timeout = 60
    )

    # Try to send the API request and handle any errors
    try {

        # Define the API endpoint and the API key
        $apiEndpoint = $url
        
        #write-host $bodyjson

        $body = $($bodyJSON | convertfrom-json)
        $prompt = $body.prompt
        
        # Create an instance of HttpClient
        $httpClient = [System.Net.Http.HttpClient]::new()

        # Set the required headers
        $httpClient.DefaultRequestHeaders.Add("api-key", $($headers."api-key"))

        # Create the HttpContent object with the request body
        $content = [System.Net.Http.StringContent]::new($body, [System.Text.Encoding]::UTF8, "application/json")

        # Send the HTTP POST request asynchronously
        $response = $httpClient.PostAsync($apiEndpoint, $content).Result

        # Ensure the response is successful
        $response.EnsureSuccessStatusCode()

        # Get the response stream
        $stream = $response.Content.ReadAsStreamAsync().Result

        # Create a StreamReader to read the response stream
        $reader = [System.IO.StreamReader]::new($stream)

        $completeText = $prompt
        write-host $prompt -nonewline
        # Read and output each line from the response stream
        while ($null -ne ($line = $reader.ReadLine())) {
		
            #Write-Output $line
            if ($line.StartsWith("data: ") -and $line -ne "data: [DONE]") {
                # Extract the JSON part from the line
                $jsonPart = $line.Substring(6)
                #$jsonPart
                # Parse the JSON part
                $parsedJson = $jsonPart | ConvertFrom-Json
                #$parsedJson
                # Extract the text and append it to the complete text
                $completeText += $parsedJson.choices[0].text
                write-host $parsedJson.choices[0].text -nonewline
            }
        }

        # Clean up
        $reader.Close()
        $httpClient.Dispose()

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
