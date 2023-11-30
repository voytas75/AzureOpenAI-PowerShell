function Invoke-APICall {
    <#
    .SYNOPSIS
        Helper function for displaying information about request parameters of AZURE OpenAI API version.
    .NOTES
        Author: Wojciech Napierała
        Date:   2023-07-02
    .LINK
        GitHub repo: https://github.com/voytas75/AzureOpenAI-PowerShell
    .EXAMPLE
        Invoke-APICall -RawAPIUrl 'https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/preview/2023-06-01-preview/inference.json'
    #>
    
    
    param (
        [Parameter(Mandatory = $true)]
        [string]$RawAPIUrl
    )

    $response = Invoke-RestMethod -Uri $RawAPIUrl -TimeoutSec 5

    Write-Output $response.info | fl
    # chat completions
    Write-Output "chat completions, properties:"
    # properties
    $response.paths."/deployments/{deployment-id}/chat/completions".post.requestBody.content."application/json".schema.properties
    Write-Output "chat completions, required:"
    #required
    $response.paths."/deployments/{deployment-id}/chat/completions".post.requestBody.content."application/json".schema.required

    # completions
    Write-Output "completions, properties:"
    $response.paths."/deployments/{deployment-id}/completions".post.requestBody.content."application/json".schema.properties
    #required
    Write-Output "completions, required:"
    $response.paths."/deployments/{deployment-id}/completions".post.requestBody.content."application/json".schema.required

    # embeddings
    Write-Output "embeddings, properties:"
    $response.paths."/deployments/{deployment-id}/embeddings".post.requestBody.content."application/json".schema.properties
    #required
    Write-Output "embeddings, required:"
    $response.paths."/deployments/{deployment-id}/embeddings".post.requestBody.content."application/json".schema.required

}