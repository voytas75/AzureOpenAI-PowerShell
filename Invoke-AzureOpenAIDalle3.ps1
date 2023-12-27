function Invoke-AzureOpenAIDALLE3 {
    [CmdletBinding()]
    param (
        [string]$serviceName,
        [string]$apiKey,
        [string]$prompt,
        [string]$model = 'dalle3',
        [string]$SavePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyPictures)
    )

    # Define the API version and Azure endpoint
    $apiVersion = "2023-12-01-preview"
    $azureEndpoint = "https://${serviceName}.openai.azure.com"
        
    # Create the JSON request body for the API call
    $requestBodyJSON = @{
        prompt = $prompt
        n      = 1
    } | ConvertTo-Json 

    # Define the headers for the API call
    $header = @{
        "Content-Type" = "application/json"
        "api-key"      = $ApiKey
    }

    # Define the URI for the API call
    $URI = "$azureEndpoint/openai/deployments/$model/images/generations?api-version=$apiVersion"
        
    # Use a try-catch block to handle potential errors in the API call
    try {
        # Make the API call and start a job to prevent blocking
        $job = Start-Job -ScriptBlock {
            param($URI, $requestBodyJSON, $header)
            Invoke-RestMethod -Method Post -Uri $URI -Body $requestBodyJSON -Headers $header -TimeoutSec 30 -ErrorAction Stop
        } -ArgumentList $URI, $requestBodyJSON, $header

        # Start a timer to display progress every second while waiting for the response
        while (($job.JobStateInfo.State -eq 'Running') -or ($job.JobStateInfo.State -eq 'NotStarted')) {
            Write-Host "." -NoNewline -ForegroundColor DarkGreen
            Start-Sleep -Milliseconds 500
        }
        Write-Host ""

        # Wait for the job to finish and collect the response
        $response = Receive-Job -Id $job.Id -Wait -ErrorAction Stop
        
        # Get the revised prompt and image URL from the response
        $imageRevisedPrompt = $response.data[0].revised_prompt
        $imageUrl = $response.data[0].url

        # Display the revised prompt
        write-host $imageRevisedPrompt -ForegroundColor Cyan

        # Define the filenames for the prompt and image
        $data = (get-date).ToString("yyyyMMddHHmmss")
        $PromptFileName = "$data.png.PROMPT.txt"
        $ImageFileName = "$data.png"
    
        # Get the full paths for the prompt and image
        $promptFullName = Join-Path $SavePath $PromptFileName
        $ImageFullName = Join-Path $SavePath $ImageFileName
    
        # Save the revised prompt to a file
        $imageRevisedPrompt | Add-Content -Path $promptFullName -Force

        # Download the image and save it to a file
        Invoke-WebRequest -Uri $imageUrl -OutFile $ImageFullName
        
        # Display the paths of the saved files
        Write-Host $ImageFullName -ForegroundColor Blue
        Write-Host $promptFullName -ForegroundColor Blue
    }
    catch {
        # If any error occurs during the process, the error details (file, line, character, and message) are printed to the console.
        Write-Host "[e] Error in file: $($_.InvocationInfo.ScriptName)" -ForegroundColor DarkRed
        Write-Host "[e] Error in line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor DarkRed
        Write-Host "[e] Error at char: $($_.InvocationInfo.OffsetInLine)" -ForegroundColor DarkRed
        Write-Host "[e] An error occurred:" -NoNewline
        Write-Host " $($_.Exception.Message)" -ForegroundColor DarkRed
        Write-Host ""
    }

}

# Define a function to display and log errors
function Show-Error {
    <#
.SYNOPSIS
Displays the error message and performs error logging.

.DESCRIPTION
This function displays the error message on the console and performs any necessary error logging.

.PARAMETER ErrorMessage
The error message to be displayed.
#>

    param(
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage # The error message to be displayed
    )

    # Display the error message
    Write-Error $ErrorMessage
    # Log error to file or other logging mechanism (Not implemented in this function but can be added here)
}
