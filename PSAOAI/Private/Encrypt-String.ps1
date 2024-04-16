function Encrypt-String {
    <#
    .SYNOPSIS
        This function encrypts a secure string.

    .DESCRIPTION
        The Encrypt-String function takes a secure string as input and converts it to an encrypted standard string.

    .PARAMETER SecureText
        The secure string to be encrypted. This parameter is mandatory.

    .EXAMPLE
        PS C:\> $SecureText = ConvertTo-SecureString -String "Hello, World!" -AsPlainText -Force
        PS C:\> $EncryptedText = Encrypt-String -SecureText $SecureText
        PS C:\> Write-Host $EncryptedText
    
    .NOTES
        Author: Wojciech Napierala
        Date: 2024-04
    #>

    param (
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$SecureText
    )

    write-verbose "Encrypt-String"

    # Convert the secure string to an encrypted standard string
    # The ConvertFrom-SecureString cmdlet is used to convert the secure string into an encrypted standard string
    $encryptedString = $SecureText | ConvertFrom-SecureString

    # Return the encrypted string
    return $encryptedString
}