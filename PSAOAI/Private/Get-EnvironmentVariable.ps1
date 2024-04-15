function Get-EnvironmentVariable {
    <#
    .SYNOPSIS
    This function retrieves the value of a specified environment variable.

    .DESCRIPTION
    The Get-EnvironmentVariable function retrieves the value of the environment variable specified by the VariableName parameter. If the Secure parameter is set to $true, the function will convert the value of the environment variable to plain text using the Convert-SecureStringToPlainText function.

    .PARAMETER VariableName
    The name of the environment variable to retrieve. This parameter is mandatory.

    .PARAMETER Secure
    If set to $true, the function will convert the value of the environment variable to plain text using the Convert-SecureStringToPlainText function. This parameter is optional.

    .EXAMPLE
    $APIVersion = Get-EnvironmentVariable -VariableName "API_AZURE_OPENAI_APIVERSION"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VariableName,
        [Parameter(Mandatory = $false)]
        [switch]$Secure
    )

    write-verbose "Get-EnvironmentVariable"

    # Writing the name of the variable to the verbose output stream for debugging purposes
    Write-Verbose "Variable Name: $VariableName"

    # Retrieve the value of the environment variable
    $VariableValue = [System.Environment]::GetEnvironmentVariable($VariableName, "User")

    Write-Verbose "Variable Value: $VariableValue"


    if ([string]::IsNullOrEmpty($VariableValue)) {
        return $null
    }
    # If Secure is set to $true, convert the value of the environment variable to plain text
    if ($Secure) {
        
        try {
            $VariableValue = Convert-SecureStringToPlainText -SecureString ($VariableValue | ConvertTo-SecureString)
            #$VariableValue = Convert-SecureStringToPlainText -SecureString ($VariableValue | ConvertTo-SecureString -AsPlainText -Force)
            # Writing the value of the variable to the verbose output stream for debugging purposes
            Write-Verbose "Variable Value: *****"
            return $VariableValue
        }
        catch {
            #Write-warning "Failed to convert the environment variable value to plain text. The value may not be a valid SecureString."
            Show-Error -ErrorVar $_
            return $null
        }

    }
    else {
        
        # Writing the value of the variable to the verbose output stream for debugging purposes
        Write-Verbose "Variable Value: $VariableValue"

    }

    # Return the value of the environment variable
    return $VariableValue
}
