param (
    [Parameter(Mandatory = $true)] 
    [ValidateSet("Mistral", "Phi3")] 
    [string] $model,
    [ValidateSet("Completion", "Chat")] 
    [string] $mode = "chat",
    [string] $SystemMessage,
    [string] $UserMessage,
    [bool] $Stream = $false
    
)

switch ($mode) {
    "Completion" { 
        $UrlPath = "/api/generate"
    }
    "Chat" { 
        $UrlPath = "/api/chat"
        # Create the request body
        $requestBody = [ordered]@{
            model    = $model
            messages = @(
                @{
                    role    = "system"
                    content = $SystemMessage
                }
                @{
                    role    = "user"
                    content = $UserMessage
                }
            )
            stream   = $stream
            options  = @{
                top_p             = 0.85
                temperature       = 0.3
            }
        } | ConvertTo-Json
        $requestBody
    }
    Default {}
}
# Define the API endpoint
$apiEndpoint = "http://localhost:11434" + $UrlPath



# Send the request to the API
$response = Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $requestBody -ContentType "application/json"
$response.message.content
# Output the response
#Write-Host "Response: $($response.response)"

<#


#>