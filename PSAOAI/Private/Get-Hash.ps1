function Get-Hash {
    <#
    .SYNOPSIS
    This function generates a hash of a given string using the specified hash algorithm.

    .DESCRIPTION
    The Get-Hash function takes an input string and a hash type as parameters. It generates a hash of the input string using the specified hash algorithm. The hash type can be one of the following: HMACMD5, HMACRIPEMD160, HMACSHA1, HMACSHA256, HMACSHA384, HMACSHA512, MACTripleDES, MD5, RIPEMD160, SHA1, SHA256, SHA384, SHA512.

    .PARAMETER InputString
    The string to be hashed.

    .PARAMETER HashType
    The type of hash algorithm to be used. It must be one of the hash types mentioned in the description.

    .EXAMPLE
    Get-Hash -InputString "Hello, World!" -HashType "SHA256"
    This example generates a SHA256 hash of the string "Hello, World!".

    "Hello, world!" | Get-Hash -HashType "HMACMD5"
    This example generates a HMACMD5 hash of the string "Hello, World!".

    .NOTES
    Author: Your Name
    Date:   Current Date
#>
    [CmdletBinding()]
    param(
        # The string to be hashed
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$InputString,

        # The type of hash algorithm to be used
        [Parameter(Mandatory = $true)]
        [ValidateSet("HMACMD5", "HMACRIPEMD160", "HMACSHA1", "HMACSHA256", "HMACSHA384", "HMACSHA512", "MACTripleDES", "MD5", "RIPEMD160", "SHA1", "SHA256", "SHA384", "SHA512")]
        [string]$HashType
    )

    # Create the hash provider based on the specified hash type
    $hashProvider = [System.Security.Cryptography.HashAlgorithm]::Create($HashType)

    # Compute the hash of the input string
    $hash = $hashProvider.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputString))

    # Convert the hash to a string and remove any hyphens
    $hashString = [System.BitConverter]::ToString($hash) -replace "-", ""

    # Return the hash string
    return $hashString
}
