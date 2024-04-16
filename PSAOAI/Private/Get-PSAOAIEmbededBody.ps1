function Get-PSAOAIEmbededBody {
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
        [Parameter(Mandatory = $false)]
        [string]$User
    )

    $body = [ordered]@{
        'input' = $EmbeddingInput
        'user'  = $User
    }
    return $body
}
