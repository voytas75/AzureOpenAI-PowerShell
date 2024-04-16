function Get-PSAOAIUrl {
    <#
.SYNOPSIS
This function generates the URL for the Azure OpenAI API request.

.DESCRIPTION
The Get-Url function constructs the URL for the Azure OpenAI API request. It uses the provided endpoint, deployment, and API version to create the URL.

.PARAMETER Endpoint
Specifies the endpoint URL for the Azure OpenAI API. This parameter is mandatory.

.PARAMETER Deployment
Specifies the name of the OpenAI deployment to be used. This parameter is mandatory.

.PARAMETER APIVersion
Specifies the version of the Azure OpenAI API to be used. This parameter is mandatory.

.EXAMPLE
Get-Url -Endpoint "https://api.openai.com" -Deployment "myDeployment" -APIVersion "v1"

.OUTPUTS
Outputs a string representing the URL for the Azure OpenAI API request.

.NOTES
    Author: Wojciech Napierala
    Date: 2024-04

#>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Endpoint, # The endpoint URL for the Azure OpenAI API

        [Parameter(Mandatory = $true)]
        [string]$Deployment, # The name of the OpenAI deployment to be used

        [Parameter(Mandatory = $true)]
        [string]$APIVersion, # The version of the Azure OpenAI API to be used

        [Parameter(Mandatory = $true)]
        [ValidateSet("Chat", "Completion", "Dalle3", "Embedding")]
        [string]$Mode
    )

    switch ($mode) {
        'Chat' { 
            # Construct and return the URL for the API request
            return "${Endpoint}/openai/deployments/${Deployment}/chat/completions?api-version=${APIVersion}"
        }
        'Completion' {  
            # Construct and return the URL for the API request
            return "${Endpoint}/openai/deployments/${Deployment}/completions?api-version=${APIVersion}"
        }
        'Dalle3' { 
            return "${Endpoint}/openai/deployments/${Deployment}/images/generations?api-version=${apiVersion}"
        }
        'Embedding' {
            return "${Endpoint}/openai/deployments/${Deployment}/embeddings?api-version=${ApiVersion}"
        }
        Default {}
    }
}
