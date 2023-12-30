function Invoke-AzureOpenAIDALLE3 {
    [CmdletBinding()]
    param (
        [string]$serviceName,
        [Parameter(ValueFromPipeline = $true)]
        [string]$Prompt,
        [string]$model = 'dalle3',
        [string]$user,
        [string]$ApiVersion = "2023-12-01-preview",
        [string]$SavePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyPictures)
    )

    function Get-Headers {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$ApiKeyVariable
        )

        # Construct headers
        $headers = [ordered]@{
            "api-key" = ""
        }

        # Check if API key is valid
        try {
            if (Test-UserEnvironmentVariable -VariableName $ApiKeyVariable) {
                $ApiKey = [System.Environment]::GetEnvironmentVariable($ApiKeyVariable, "user")
                $headers["api-key"] = $ApiKey
            } 
        }
        catch {
            Write-Error "API key '$ApiKeyVariable' not found in environment variables. Please set the environment variable before running this script."
        }

        return $headers
    }

    # This function checks if a user environment variable exists
    # Given a variable name, it checks if it exists in the environment variables
    # If it does, it returns true, otherwise it returns false
    function Test-UserEnvironmentVariable {
        param (
            [Parameter(Mandatory = $true)]
            [string]$VariableName
        )
    
        $envVariable = [Environment]::GetEnvironmentVariable($VariableName, "User")
        if ($envVariable) {
            Write-Verbose "The user environment variable '$VariableName' is set."
            return $true
        }
        else {
            Write-Verbose "The user environment variable '$VariableName' is not set."
            return $false
        }
    }

    # This function displays the error message and performs any necessary error logging.
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

    # This function constructs and returns the URL for the API call
    function Get-Url {
        param (
            [Parameter(Mandatory = $true)]
            [string]$apiVersion
        )

        $urlImages = "$azureEndpoint/openai/deployments/$model/images/generations?api-version=$apiVersion"
        return $urlImages
    }

    # This function constructs and returns the body for the API request
    function Get-BodyJSON {
        param(
            [Parameter(Mandatory = $true)]
            [string]$prompt,

            [Parameter(Mandatory = $false)]
            [int]$n = 1,

            [Parameter(Mandatory = $false)]
            [string]$user
        )
        
        $body = [ordered]@{
            'prompt' = $prompt
            'n'      = $n
            'user'   = $user
        }
        return ($body | ConvertTo-Json)
    }
    

    # Define the API version and Azure endpoint
    $azureEndpoint = "https://${serviceName}.openai.azure.com"
        
    # Create the JSON request body for the API call
    $requestBodyJSON = get-BodyJSON -prompt $prompt -n 1 -user $user

    # Define the headers for the API call
    $headers = Get-Headers -ApiKey "API_AZURE_OPENAI"

    # Define the URI for the API call
    $URI = Get-Url -apiVersion $ApiVersion

    # Use a try-catch block to handle potential errors in the API call
    try {

        # Make the API call and start a job to prevent blocking
        # It uses the URI, body, and headers defined above
        $job = Start-Job -ScriptBlock {
            param($URI, $requestBodyJSON, $headers)
            Invoke-RestMethod -Method Post -Uri $URI -Body $requestBodyJSON -Headers $headers -TimeoutSec 30 
        } -ArgumentList $URI, $requestBodyJSON, $headers

        # Start a timer to display progress every second while waiting for the response
        # If the job is still running, it prints a dot
        while (($job.JobStateInfo.State -eq 'Running') -or ($job.JobStateInfo.State -eq 'NotStarted')) {
            Write-Host "." -NoNewline -ForegroundColor DarkGreen
            Start-Sleep -Milliseconds 500
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
            #$joberror.Exception | ConvertTo-Json
            $jobErrormessage = ($joberror.ErrorDetails.message | Convertfrom-Json).error
            write-host "$($jobErrormessage.code):" -NoNewline -ForegroundColor DarkYellow
            Write-Host " $($jobErrormessage.message)" -ForegroundColor DarkYellow

            # Save the prompt and joberrormessageto a file
            "[Error] ($($jobErrormessage.code)): $($jobErrormessage.message)" | Add-Content -Path $promptFullName -Force
            "Prompt: $prompt" | Add-Content -Path $promptFullName -Force

            # Display the paths of the saved files
            Write-Host $promptFullName -ForegroundColor Blue
        }
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