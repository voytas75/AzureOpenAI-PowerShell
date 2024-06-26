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
    Repository: https://github.com/voytas75/AzureOpenAI-PowerShell/PSAOAI
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [switch]$simpleresponse,
        [Parameter(Mandatory = $false)]
        [string]$Endpoint = (Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_ENDPOINT -PromptMessage "Please enter the endpoint"),
        [Parameter(Mandatory = $false)]
        [string]$Deployment = (Set-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_C_DEPLOYMENT -PromptMessage "Please enter the deployment"),
        [Parameter(Mandatory = $false)]
        [string]$ApiVersion = (Get-EnvironmentVariable -VariableName $script:API_AZURE_OPENAI_APIVERSION),
        [Parameter(Mandatory = $false)]
        [string]$User
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
            [string]$Stream,
            [Parameter(Mandatory = $false)]
            [switch]$simpleresponse
    
        )
        if (-not $simpleresponse) {
            Write-Host ""
            Write-Host "Response message embedding ($Stream):"
        }
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
    
        Write-Host ""
        Write-Host "Usage:"
        return $Usage
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
        # Retrieve the headers using the API key
        $headers = Get-Headers -ApiKeyVariable $script:API_AZURE_OPENAI_KEY -Secure
    
        # If no message is provided, get the embedding input
        if (-not $Message) {
            $Message = Get-EmbeddingInput
        }

        # Get the body of the request using the embedding input and user
        $body = Get-PSAOAIEmbededBody -EmbeddingInput $Message -User $User

        # Construct the URL for the request
        $url = Get-PSAOAIUrl -Mode Embedding -Endpoint $Endpoint -Deployment $Deployment -ApiVersion $ApiVersion
        Write-Verbose $url
        
        # Convert the body to JSON format
        $bodyJson = $body | ConvertTo-Json
        Write-Verbose $bodyJson

        # Invoke the API request with the constructed URL, headers, and body
        $response = Invoke-PSAOAIApiRequest -Url $url -Headers $headers -BodyJson $bodyJson -timeout 240

        # If a response is received, show the usage and return the response message
        if ($response) {
            if (-not $simpleresponse) {
                Show-Usage -Usage $response.usage
            }
            return (Show-ResponseMessage -Content $response -Stream "output" -simpleresponse:$simpleresponse)
            
        }
    }
    catch {
        # If an error occurs, show the error
        Show-Error $_
    }
}
