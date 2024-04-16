function Invoke-PSAOAIDalle3 {
    <#
    .SYNOPSIS
    This function interacts with Azure OpenAI Services.

    .DESCRIPTION
    The Invoke-PSAOAIDalle3 function sends a request to the Azure OpenAI Services and retrieves the response. It takes several parameters including the service name, prompt, model, size, response format, quality, style, user, API version, save path, image loops, n, and timeout in seconds.

    .PARAMETER serviceName
    The name of the service to interact with.

    .PARAMETER Prompt
    The prompt to be used.

    .PARAMETER model
    The model to be used. Default is 'dalle3'.

    .PARAMETER size
    The size of the output. Default is '1792x1024'.

    .PARAMETER response_format
    The format of the response. Default is 'url'.

    .PARAMETER quality
    The quality of the output. Default is 'hd'.

    .PARAMETER style
    The style of the output. Default is 'natural'.

    .PARAMETER user
    The user for the request.

    .PARAMETER ApiVersion
    The API version to be used. Default is '2023-12-01-preview'.

    .PARAMETER SavePath
    The path where the output will be saved. Default is the MyPictures folder.

    .PARAMETER ImageLoops
    The number of image loops. Default is 1.

    .PARAMETER n
    The number of outputs. Default is 1.

    .PARAMETER timeoutSec
    The timeout in seconds. Default is 60.

    .EXAMPLE
    Invoke-PSAOAIDalle3 -serviceName "MyService" -Prompt "MyPrompt" -user "MyUser"

    This command sends a request to the "MyService" service with the prompt "MyPrompt" and the user "MyUser", and retrieves the response.

    .NOTES
    Author: Wojciech Napierala
    Date:   2023-06
    #>
    [CmdletBinding()]
    param (
        [string]$serviceName,

        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [string]$Prompt,

        [string]$model = 'dalle3',

        [ValidateSet("1024x1024", "1792x1024", "1024x1792")]
        [string]$size = "1792x1024",

        [ValidateSet("url", "b64_json")]
        [string]$response_format = "url",

        [ValidateSet("standard", "hd")]
        [string]$quality = "hd",

        [ValidateSet("natural", "vivid")]
        [string]$style = "natural",

        [string]$user,

        [string]$ApiVersion = (get-apiversion -preview | select-object -first 1),

        [string]$SavePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyPictures),

        [int]$ImageLoops = 1,

        [int]$n = 1,

        [int]$timeoutSec = 240
    )

    # This function constructs and returns the body for the API request
    function Get-BodyJSON {
        param(
            [Parameter(Mandatory = $true)]
            [string]$prompt,

            [Parameter(Mandatory = $false)]
            [int]$n = 1,

            [Parameter(Mandatory = $false)]
            [string]$user,

            [Parameter(Mandatory = $false)]
            [string]$size,

            [Parameter(Mandatory = $false)]
            [string]$response_format,

            [Parameter(Mandatory = $false)]
            [string]$quality,

            [Parameter(Mandatory = $false)]
            [string]$style

        )
        
        $body = [ordered]@{
            'prompt'          = $prompt
            'n'               = $n
            'user'            = $user
            'size'            = $size
            'response_format' = $response_format
            'quality'         = $quality
            'style'           = $style
        }
        return ($body | ConvertTo-Json)
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
        $Deployment = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_D3_DEPLOYMENT -PromptMessage "Please enter the Deployment"
    }

    while ([string]::IsNullOrEmpty($ApiKey)) {
        if (-not ($ApiKey = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API Key" -Secure)) {
            Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -VariableValue $null
            $ApiKey = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API Key" -Secure
        }
    }

    if ($VerbosePreference -eq 'Continue') {
        Write-Host "Parameters and values:"
        Write-Host "Prompt: $prompt"
        Write-Host "n: $n"
        Write-Host "User: $user"
        Write-Host "Size: $size"
        Write-Host "Response format: $response_format"
        Write-Host "Quality: $quality"
        Write-Host "Style: $style"
    }

    # Create the JSON request body for the API call
    $requestBodyJSON = get-BodyJSON -prompt $prompt -n $n -user $user -size $size -response_format $response_format -quality $quality -style $style

    Write-Verbose $requestBodyJSON

    # Define the headers for the API call
    $headers = Get-Headers -ApiKey $script:API_AZURE_OPENAI_KEY -Secure
    
    # Define the URI for the API call
    $URI = Get-PSAOAIUrl -apiVersion $ApiVersion -Mode Dalle3 -Endpoint $Endpoint -Deployment $Deployment

    Write-Verbose $URI


    # Use a try-catch block to handle potential errors in the API call
    try {
        for ($i = 0; $i -lt $ImageLoops; $i++) {

            # Make the API call and start a job to prevent blocking
            # It uses the URI, body, and headers defined above
            $job = Start-Job -ScriptBlock {
                param($URI, $requestBodyJSON, $headers, $timeoutSec)
                Invoke-RestMethod -Method Post -Uri $URI -Body $requestBodyJSON -Headers $headers -TimeoutSec $timeoutSec
            } -ArgumentList $URI, $requestBodyJSON, $headers, $timeoutSec

            Write-Host "[dalle3]" -ForegroundColor Green
            Write-Host "{n:'${n}', size:'${size}', rf:'${response_format}', quality:'${quality}', user:'${user}', style:'${style}', imageloops:'$($j=$i+1;$j)/${imageloops}'} " -NoNewline -ForegroundColor Magenta

            # If the job is still running, it does progress
            while (($job.JobStateInfo.State -eq 'Running') -or ($job.JobStateInfo.State -eq 'NotStarted')) {
                Write-Host "." -NoNewline -ForegroundColor Blue
                Start-Sleep -Milliseconds 1000
            }
            Write-Host ""

            # Define the filenames for the prompt and image
            $data = (get-date).ToString("yyyyMMddHHmmss")
            $PromptFileName = "$data.png.DATA.txt"
            $ImageFileName = "$data.png"
            
            # Get the full paths for the prompt and image
            $promptFullName = Join-Path $SavePath $PromptFileName
            $ImageFullName = Join-Path $SavePath $ImageFileName
        
            # Check if the job failed and display an error message if it did
            # If it did not fail, it retrieves the response and extracts the image URL and revised prompt
            # It then saves the image and revised prompt to files
            if ($job.JobStateInfo.State -ne 'Failed') {

                # Wait for the job to finish and collect the response
                $response = Receive-Job -Id $job.Id -Wait

                # Get the revised prompt and image URL from the response
                $imageRevisedPrompt = $response.data[0].revised_prompt
                $imageUrl = $response.data[0].url

                # Display the revised prompt
                write-host $imageRevisedPrompt -ForegroundColor Cyan
    
                # Save the revised prompt to a file
                "Prompt: $prompt" | Add-Content -Path $promptFullName -Force
                "Revised prompt: $imageRevisedPrompt" | Add-Content -Path $promptFullName -Force

                # Download the image and save it to a file using .NET WebClient for better performance
                $webClient = New-Object System.Net.WebClient
                $webClient.DownloadFile($imageUrl, $ImageFullName)
        
                # Display the paths of the saved files
                Write-Host $ImageFullName -ForegroundColor Blue
                Write-Host $promptFullName -ForegroundColor Blue
            }
            else {

                Write-Host "Job failed: " -NoNewline -ForegroundColor DarkRed
                [void]($response = Receive-Job -Id $job.Id -Wait -ErrorVariable joberror -ErrorAction SilentlyContinue)
                #$joberror | ConvertTo-Json
                write-host "$($jobError.Exception.ErrorRecord.Exception)" -NoNewline -ForegroundColor DarkYellow
                write-host " $($($($jobError.ErrorDetails.Message) | convertfrom-json).error.message)" -ForegroundColor DarkYellow

                # Save the prompt and joberrormessageto a file
                "[Error] ($($jobError.Exception.ErrorRecord.Exception))" | Add-Content -Path $promptFullName -Force
                "Prompt: $prompt" | Add-Content -Path $promptFullName -Force

                # Display the paths of the saved files
                Write-Host $promptFullName -ForegroundColor Blue
            }
        }
    }
    catch {
        # If any error occurs during the process, the error details (file, line, character, and message) are printed to the console.
        Show-Error $_
    }

}