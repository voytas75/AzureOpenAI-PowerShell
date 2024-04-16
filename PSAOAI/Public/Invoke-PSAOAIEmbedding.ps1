function Invoke-PSAOAIEmbedding {
    <#
    .SYNOPSIS
    Executes an API request to Azure OpenAI and returns the response message embedding.

    .DESCRIPTION
    This function sends an API request to Azure OpenAI and retrieves the response message embedding. It allows users to input their own messages and returns a vector representation of the input that can be utilized by machine learning models and other algorithms.

    .PARAMETER ApiVersion
    Specifies the version of the Azure OpenAI API to be used.

    .PARAMETER Endpoint
    Defines the endpoint URL for the OpenAI API.

    .PARAMETER Deployment
    Specifies the name of the OpenAI deployment to be used.

    .PARAMETER User
    Identifies the user executing the API request.

    .LINK
    Azure OpenAI Service Documentation: https://learn.microsoft.com/en-us/azure/cognitive-services/openai/
    Azure OpenAI Service REST API reference for embedding: https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference#embeddings

    .EXAMPLE
    PS C:\> Invoke-PSAOAIEmbedding `
    -ApiVersion "2023-06-01-preview" `
    -Endpoint "https://example.openai.azure.com" `
    -Deployment "embedding_model" `
    -User "BobbyK"
    -Message "Hello, World!"
    
    This example demonstrates how to execute an API request to an OpenAI embedding and retrieve the response message.

    .NOTES
    Author: Wojciech Napierała
    Date:   2023-06-27
    Repository: https://github.com/voytas75/AzureOpenAI-PowerShell
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ApiVersion = (get-apiversion -preview | select-object -first 1),
        [Parameter(Mandatory = $false)]
        [string]$Endpoint,
        [Parameter(Mandatory = $false)]
        [string]$Deployment,
        [Parameter(Mandatory = $false)]
        [string]$User,
        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [string]$Message

    )
    function Get-EmbeddingInput {
        <#
        .SYNOPSIS
        Prompts the user to insert a message for embedding.
        
        .DESCRIPTION
        This function prompts the user to insert a message for embedding and returns the input message.
        
        .OUTPUTS
        The user input message.
        #>
        
        $EmbeddingInput = Read-Host "Insert message to embedding"
    
        return $EmbeddingInput
    }
    
    function Invoke-ApiRequest {
        <#
        .SYNOPSIS
        Makes the API request and returns the response.
        
        .DESCRIPTION
        This function makes the API request using the provided URL, headers, and body JSON. It handles exceptions and returns the response.
        
        .PARAMETER Url
        The URL for the API request.
        
        .PARAMETER Headers
        The headers for the API request.
        
        .PARAMETER BodyJson
        The JSON representation of the request body.
        
        .OUTPUTS
        The response object from the API request.
        #>
        
        param(
            [Parameter(Mandatory = $true)]
            [string]$Url,
            [Parameter(Mandatory = $true)]
            [hashtable]$Headers,
            [Parameter(Mandatory = $true)]
            [string]$BodyJson
        )
    
        try {
            $response = Invoke-RestMethod -Uri $Url -Method POST -Headers $Headers -Body $BodyJson -TimeoutSec 30 -ErrorAction Stop
            return $response
        }
        catch {
            Show-Error $_
        }
    }
    
    function Show-ResponseMessage {
        <#
        .SYNOPSIS
        Displays the response message to the console.
        
        .DESCRIPTION
        This function displays the response message from the API request on the console.
        
        .PARAMETER Content
        The content of the response message.
        
        .PARAMETER Stream
        The stream to which the response message belongs.
        #>
        
        param(
            [Parameter(Mandatory = $true)]
            [System.Object]$Content,
            [Parameter(Mandatory = $true)]
            [string]$Stream
        )
    
        Write-Output ""
        Write-Output "Response message embedding ($Stream):"
        return $Content.data.embedding
    }
   
    function Show-Usage {
        <#
        .SYNOPSIS
        Displays the usage information to the console.
        
        .DESCRIPTION
        This function displays the usage information from the API response on the console.
        
        .PARAMETER Usage
        The usage information to be displayed.
        #>
        
        param(
            [Parameter(Mandatory = $true)]
            $Usage
        )
    
        Write-Output ""
        Write-Output "Usage:"
        Write-Output $Usage
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
        $Deployment = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_E_DEPLOYMENT -PromptMessage "Please enter the Deployment"
    }

    while ([string]::IsNullOrEmpty($ApiKey)) {
        if (-not ($ApiKey = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API Key" -Secure)) {
            Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -VariableValue $null
            $ApiKey = Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_KEY -PromptMessage "Please enter the API Key" -Secure
        }
    }

    try {
        $headers = Get-Headers -ApiKeyVariable $script:API_AZURE_OPENAI_KEY -Secure
    
        if (-not $Message) {
            $Message = Get-EmbeddingInput
        }

        $body = Get-PSAOAIEmbededBody -EmbeddingInput $Message -User $User

        $url = Get-PSAOAIUrl -Mode Embedding -Endpoint $Endpoint -Deployment $Deployment -ApiVersion $ApiVersion
        Write-Verbose $url
        $bodyJson = $body | ConvertTo-Json
        Write-Verbose $bodyJson

        $response = Invoke-ApiRequest -Url $url -Headers $headers -BodyJson $bodyJson

        if ($response) {
            Show-ResponseMessage -Content $response -Stream "output"
            Show-Usage -Usage $response.usage
        }
    }
    catch {
        Show-Error $_
    }
}
