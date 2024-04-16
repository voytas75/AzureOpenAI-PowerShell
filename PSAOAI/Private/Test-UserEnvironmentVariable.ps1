# Function to verify the existence of a user environment variable
function Test-UserEnvironmentVariable {
    <#
    .SYNOPSIS
    Verifies the existence of a user environment variable.
    
    .DESCRIPTION
    This function checks if a specific user environment variable is set in the system. It returns a boolean value indicating the existence of the variable.
    
    .PARAMETER VariableName
    The name of the environment variable to verify. This parameter is mandatory.
    
    .EXAMPLE
    Test-UserEnvironmentVariable -VariableName "API_AZURE_OPENAI"
    
    .OUTPUTS
    Boolean. Returns $true if the environment variable exists, $false otherwise.

    .NOTES
        Author: Wojciech Napierala
        Date: 2024-04

    #> 
    param (
        [Parameter(Mandatory = $true)]
        [string]$VariableName # The name of the environment variable to verify
    )

    # Get the list of environment variables
    $envVariables = Get-ChildItem -Path "Env:$VariableName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    # Get the specific environment variable from the user environment
    $envVariable = [Environment]::GetEnvironmentVariable($VariableName, "User")
    
    # Check if the environment variable exists
    if ($envVariables -contains $VariableName -or $envVariable) {
        Write-Verbose "The user environment variable '$VariableName' is set."
        return $true
    }
    else {
        Write-Verbose "The user environment variable '$VariableName' is not set."
        return $false
    }
}
