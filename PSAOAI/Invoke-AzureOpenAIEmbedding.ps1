function Invoke-AzureOpenAIEmbedding {
    <#
    .SYNOPSIS
    This script makes an API request to an AZURE OpenAI and outputs the response message embedding.
    
    .DESCRIPTION
    This script defines functions to make an API request to an AZUER OpenAI and output the response message. The user can input their own messages.
    Get a vector representation of a given input that can be easily consumed by machine learning models and other algorithms.
    
    .PARAMETER ApiVersion
    The version of the AZURE OpenAI API to use.
    
    .PARAMETER Endpoint
    The endpoint URL for the OpenAI API.
    
    .PARAMETER Deployment
    The name of the OpenAI deployment to use.
    
    .PARAMETER User
    The name of the user making the API request.

    .LINK
    Azure OpenAI Service Documentation: https://learn.microsoft.com/en-us/azure/cognitive-services/openai/
    Azure OpenAI Service REST API reference for embedding: https://learn.microsoft.com/en-us/azure/cognitive-services/openai/reference#embeddings

    .EXAMPLE
    PS C:\> Invoke-AzureOpenAIEmbedding `
    -ApiVersion "2023-06-01-preview" `
    -Endpoint "https://example.openai.azure.com" `
    -Deployment "example_model_ada_1" `
    -User "BobbyK"
    
    This example makes an API request to an OpenAI embedding and outputs the response message.
    
    .NOTES
    Author: Wojciech Napierała
    Date:   2023-06-27
    Repo: https://github.com/voytas75/AzureOpenAI-PowerShell
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiVersion,
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [Parameter(Mandatory = $true)]
        [string]$Deployment,
        [Parameter(Mandatory = $true)]
        [string]$User
    )

    # Function to retrieve headers for API request.
    function Get-Headers {
        <#
        .SYNOPSIS
        Retrieves headers for API request.
        
        .DESCRIPTION
        This function retrieves the headers required to make an API request to Azure OpenAI Text Analytics API.
        
        .PARAMETER ApiKeyVariable
        The name of the environment variable that contains the API key.
        
        .OUTPUTS
        Hashtable of headers to use in API request.
        #>
        
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$ApiKeyVariable
        )

        try {
            if (Test-UserEnvironmentVariable -VariableName $ApiKeyVariable) {
                $ApiKey = [System.Environment]::GetEnvironmentVariable($ApiKeyVariable, "user")
            } 
        }
        catch {
            Write-Error "API key '$ApiKeyVariable' not found in environment variables. Please set the environment variable before running this script."
            return $null
        }

        $headers = @{
            "Content-Type" = "application/json"
            "api-key"      = $ApiKey
        }

        return $headers
    }
    
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
    
    function Get-Body {
        <#
        .SYNOPSIS
        Builds the body for the API request.
        
        .DESCRIPTION
        This function builds the body for the API request using the provided input message and user name.
        
        .PARAMETER EmbeddingInput
        The message to be embedded.
        
        .PARAMETER User
        The name of the user making the API request.
        
        .OUTPUTS
        The body object for the API request.
        #>
        
        param(
            [Parameter(Mandatory = $true)]
            [string]$EmbeddingInput,
            [Parameter(Mandatory = $true)]
            [string]$User
        )
    
        $body = @{
            'input' = $EmbeddingInput
            'user'  = $User
        }
        return $body
    }
    
    function Get-Url {
        <#
        .SYNOPSIS
        Builds the URL for the API request.
        
        .DESCRIPTION
        This function builds the URL for the API request using the provided endpoint, deployment, and API version.
        
        .OUTPUTS
		The URL for the API request.
        #>
        
        $urlEmbedding = "${Endpoint}/openai/deployments/${Deployment}/embeddings?api-version=${ApiVersion}"
        return $urlEmbedding
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
            Show-Error -ErrorMessage $_.Exception.Message
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
        Write-Output $Content.data.embedding
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

    function Test-UserEnvironmentVariable {
        <#
        .SYNOPSIS
        Tests if a user environment variable is set.
        
        .DESCRIPTION
        This function tests if a user environment variable with the provided name is set.
        
        .PARAMETER VariableName
        The name of the environment variable to test.
        
        .OUTPUTS
        $true if the variable is set, $false otherwise.
        #>
        
        param (
            [Parameter(Mandatory = $true)]
            [string]$VariableName
        )
    
        $envVariables = Get-ChildItem -Path "Env:" | Select-Object -ExpandProperty Name
        return $envVariables.Contains($VariableName)
    }
    
    $headers = Get-Headers -ApiKeyVariable "API_AZURE_OPENAI"
    if (-not $headers) {
        return
    }
    
    $embeddingInput = Get-EmbeddingInput
    $body = Get-Body -EmbeddingInput $embeddingInput -User $User
    $url = Get-Url
    
    $bodyJson = $body | ConvertTo-Json
    
    $response = Invoke-ApiRequest -Url $url -Headers $headers -BodyJson $bodyJson
    if ($response) {
        Show-ResponseMessage -Content $response -Stream "output"
        Show-Usage -Usage $response.usage
    }
}
