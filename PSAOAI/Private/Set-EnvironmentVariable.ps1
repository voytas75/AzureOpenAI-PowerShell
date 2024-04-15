function Set-EnvironmentVariable {
    <#
    .SYNOPSIS
    This function sets the value of a specified environment variable. If the variable does not exist, it prompts the user to provide a value.

    .DESCRIPTION
    The Set-EnvironmentVariable function sets the value of the environment variable specified by the VariableName parameter. If the variable does not exist or its value is null or empty, the function prompts the user to provide a value using the message specified by the PromptMessage parameter.

    .PARAMETER VariableName
    The name of the environment variable to set. This parameter is mandatory.

    .PARAMETER PromptMessage
    The message to display when prompting the user to provide a value for the environment variable. This parameter is mandatory.

    .PARAMETER Secure
    A switch to indicate if the environment variable should be stored securely. This parameter is not mandatory.

    .EXAMPLE
    Set-EnvironmentVariable -VariableName "API_AZURE_OPENAI_APIVERSION" -PromptMessage "Please enter the API version" -Secure
    #>

    param(
        [Parameter(Mandatory = $true)]
        [string]$VariableName,
        [Parameter(Mandatory = $false)]
        [string]$PromptMessage,
        [Parameter(Mandatory = $false)]
        [switch]$Secure,
        [Parameter(Mandatory = $false)]
        [string]$VariableValue
    )

    write-verbose "Set-EnvironmentVariable"

    if (-not ([string]::IsNullOrEmpty($VariableValue))) {
        # Attempt to set the environment variable to the provided value
        try {
            [System.Environment]::SetEnvironmentVariable($VariableName, $VariableValue, "User")
        }
        # If setting the variable failed, display an error message
        catch {
            Write-Warning "Failed to set environment variable $VariableName."
            Show-Error -ErrorVar $_
        }        
    }

    try {
        if ($Secure) {
            # If the variable does not exist or its value is null or empty, prompt the user to provide a value
            $VariableValue = Get-EnvironmentVariable -VariableName $VariableName -Secure
            write-Host "VariableValue: $VariableValue"
        }
        else {
            $VariableValue = Get-EnvironmentVariable -VariableName $VariableName
        }
    }
    catch {
        Write-Warning "Failed to get environment variable $VariableName."
        Show-Error -ErrorVar $_
        return $false
    }
    # Checking if the value of the variable is null or empty
    if ([string]::IsNullOrEmpty($VariableValue)) {
        if ($Secure) {
            $VariableValue = (Read-Host -Prompt $PromptMessage -AsSecureString) | ConvertFrom-SecureString
            #$VariableValue = Encrypt-String -SecureText $VariableValue
            #$VariableValue = $VariableValue | Convertfrom-SecureString
        }
        else {
            $VariableValue = Read-Host -Prompt $PromptMessage
        }

        # Attempt to set the environment variable to the provided value
        try {
            [System.Environment]::SetEnvironmentVariable($VariableName, $VariableValue, "User")

            # If the variable was set successfully, display a success message
            if (Test-UserEnvironmentVariable -VariableName $VariableName) {
                Write-Host "Environment variable $VariableName was set successfully." -ForegroundColor Green
            }

            if ($Secure) {
                $VariableValue = Get-EnvironmentVariable -VariableName $VariableName -Secure

            }
        }
        # If setting the variable failed, display an error message
        catch {
            Write-Warning "Failed to set environment variable $VariableName."
            Show-Error -ErrorVar $_
        }
    }
    return $VariableValue
}
