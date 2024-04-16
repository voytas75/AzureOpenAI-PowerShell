function Get-EnvironmentVariable {
    <#
    .SYNOPSIS
    Retrieves the value of a specified environment variable.

    .DESCRIPTION
    The Get-EnvironmentVariable function fetches the value of the environment variable defined by the VariableName parameter. If the Secure parameter is set to $true, the function will transform the value of the environment variable to plain text using the Convert-SecureStringToPlainText function.

    .PARAMETER VariableName
    The name of the environment variable to fetch. This parameter is mandatory.

    .PARAMETER Secure
    If set to $true, the function will transform the value of the environment variable to plain text using the Convert-SecureStringToPlainText function. This parameter is optional.

    .EXAMPLE
    $APIVersion = Get-EnvironmentVariable -VariableName "API_AZURE_OPENAI_APIVERSION"

    .NOTES
        Author: Wojciech Napierala
        Date: 2024-04

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VariableName,
        [Parameter(Mandatory = $false)]
        [switch]$Secure
    )

    write-verbose "Executing Get-EnvironmentVariable"

    # Outputting the name of the variable to the verbose output stream for debugging
    Write-Verbose "Variable Name: $VariableName"

    # Fetch the value of the environment variable
    $VariableValue = [System.Environment]::GetEnvironmentVariable($VariableName, "User")

    if ([string]::IsNullOrEmpty($VariableValue)) {
        return $null
    }
    # If Secure is set to $true, transform the value of the environment variable to plain text
    if ($Secure) {
        
        try {
            $VariableValue = Convert-SecureStringToPlainText -SecureString ($VariableValue | ConvertTo-SecureString)
            # Outputting the value of the variable to the verbose output stream for debugging
            Write-Verbose "Variable Value: *****"
            return $VariableValue
        }
        catch {
            Show-Error -ErrorVar $_
            return $null
        }

    }
    else {
       
        # Outputting the value of the variable to the verbose output stream for debugging
        Write-Verbose "Variable Value: $VariableValue"

    }

    # Return the value of the environment variable
    return $VariableValue
}
