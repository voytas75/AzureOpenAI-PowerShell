    # Function to generate the headers for the API request.
    function Get-Headers {
        <#
        .SYNOPSIS
        Generates the necessary headers for an API request to Azure OpenAI.
        
        .DESCRIPTION
        This function constructs the headers required for an API request to Azure OpenAI. It retrieves the API key from the specified environment variable and uses it for request authentication.
        
        .PARAMETER ApiKeyVariable
        Specifies the name of the environment variable that stores the API key. This parameter is mandatory.
        
        .EXAMPLE
        Get-Headers -ApiKeyVariable "OPENAI_API_KEY"
        
        .OUTPUTS
        Returns a hashtable of headers for the API request. The headers include "Content-Type" set to "application/json" and "api-key" set to the value of the API key retrieved from the environment variable.
        
        .NOTES
        It's crucial to store the API key securely in an environment variable. The function will throw an error if it can't find the API key in the specified environment variable.        
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]$ApiKeyVariable,
            [switch]$Secure
        )

        # Initialize API key variable
        $ApiKey = $null

        try {
            # Check if the API key exists in the user's environment variables
            if (Test-UserEnvironmentVariable -VariableName $ApiKeyVariable) {
                # Retrieve the API key from the environment variable
                if ($secure) {
                    $ApiKey = Get-EnvironmentVariable -VariableName $ApiKeyVariable -Secure
                } else {
                    $ApiKey = Get-EnvironmentVariable -VariableName $ApiKeyVariable
                }
            }
        }
        catch {
            # Throw an error if the API key is not found
            Write-Error "API key '$ApiKeyVariable' not found in environment variables. Please set the environment variable before running this script."
            Show-Error -ErrorVar $Error[0]
            return $null
        }

        # Return the headers for the API request
        return @{
            "Content-Type" = "application/json"
            "api-key"      = $ApiKey
        }
               
    }
