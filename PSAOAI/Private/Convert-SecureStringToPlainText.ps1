<#
.SYNOPSIS
    This function converts a SecureString to plain text.

.DESCRIPTION
    The Convert-SecureStringToPlainText function takes a SecureString as input and converts it to plain text. It uses the SecureStringToBSTR and PtrToStringAuto methods from the System.Runtime.InteropServices.Marshal class to perform the conversion. After the conversion, it frees the memory that was allocated for the BSTR to ensure that the data is not left in memory where it could potentially be accessed by malicious code.

.PARAMETER SecureString
    The SecureString to be converted to plain text. This parameter is mandatory.

.EXAMPLE
    $SecurePassword = Read-Host "Enter your password" -AsSecureString
    $PlainTextPassword = Convert-SecureStringToPlainText -SecureString $SecurePassword
    Write-Host $PlainTextPassword

.NOTES
Author: Wojciech Napierala
Date:   2024-04

#>
function Convert-SecureStringToPlainText {
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$SecureString
    )
    write-verbose "Convert-SecureStringToPlainText"

    try {
        # Convert the SecureString to a BSTR
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)

        # Convert the BSTR to a plain text string
        $PlainTextString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        # Free the memory that was allocated for the BSTR
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        # Return the plain text string
        return $PlainTextString
    }
    catch {
        Show-Error -ErrorVar $_
    }
}
