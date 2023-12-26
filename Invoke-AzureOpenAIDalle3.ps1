function Invoke-AzureOpenAIDALLE3 {
    [CmdletBinding()]
    param (
        [string]$serviceName,
        [string]$apiKey,
        [string]$prompt,
        [string]$model = 'dalle3',
        [string]$SavePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::MyPictures)
    )

    $apiVersion = "2023-12-01-preview"
    $azureEndpoint = "https://${serviceName}.openai.azure.com"
    #$apiKey = "$env:AZURE_OPENAI_API_KEY"
    

    # Retrieve the prompt from the user
    #$prompt = Read-Host "Enter your prompt for DALL-E 3 generation"

    $requestBodyJSON = @{
        prompt = $prompt
        n      = 1
    } | ConvertTo-Json 

    #$requestBody

    $header = @{
        "Content-Type" = "application/json"
        "api-key"      = $ApiKey
    }

    #$header

    #endpoint: https://udtazureopenai.openai.azure.com/openai/deployments/Dalle3/images/generations?api-version=2023-12-01-preview
    $URI = "$azureEndpoint/openai/deployments/$model/images/generations?api-version=$apiVersion"
    #$URI = "$azureEndpoint/openai/"
    #$URI
    
    try {
        $response = Invoke-RestMethod -Method Post -Uri $URI -Body $requestBodyJSON -Headers $header -TimeoutSec 30 -ErrorAction Stop

        $response.error.code


        #$imageData = $response.data
        $imageRevisedPrompt = $response.data[0].revised_prompt
        $imageUrl = $response.data[0].url

        write-host $imageRevisedPrompt -ForegroundColor Cyan

        $data = (get-date).ToString("yyyyMMddHHmmss")
        $PromptFileName = "$data.png.PROMPT.txt"
        $ImageFileName = "$data.png"
    
        # FullNames
        $promptFullName = Join-Path $SavePath $PromptFileName
        $ImageFullName = Join-Path $SavePath $ImageFileName
    
        #save prompt
        $imageRevisedPrompt | Add-Content -Path $promptFullName -Force

        Invoke-WebRequest -Uri $imageUrl -OutFile $ImageFullName
        
        #show paths
        Write-Host $ImageFullName -ForegroundColor Blue
        Write-Host $promptFullName -ForegroundColor Blue
    }
    catch {
        #Write-Host "Error getting image: $response.error"
        Show-Error -ErrorMessage "Error getting image file: $($_.Exception.Message)"
    }

}

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
        [string]$ErrorMessage
    )

    Write-Error $ErrorMessage
    # Log error to file or other logging mechanism
}
